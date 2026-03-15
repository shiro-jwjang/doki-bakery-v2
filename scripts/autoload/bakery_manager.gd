extends Node

## BakeryManager Autoload
##
## Manages production slots for the bakery. Handles starting production,
## tracking active slots, and enforcing slot limits based on ShopData.
## SNA-74: BakeryManager 슬롯 관리
## SNA-174: Dictionary 기반 슬롯 관리

## Signal emitted when production starts
signal production_started(slot_index: int, recipe_id: String)

## Signal emitted when production completes
signal production_completed(slot_index: int, recipe_id: String)

## Signal emitted when production fails
signal production_failed(slot_index: int, reason: String)

## Maximum number of production slots
var _max_slots: int = 3

## Array of active production slots (Dictionary-based)
## Each slot: {slot_index, recipe, start_time, progress, is_active, is_completed, remaining_time}
var _slots: Array = []

## Current number of active productions
var _active_count: int = 0

## Mock recipe for testing (used in tests)
var _mock_recipe: Resource = null

## Mock time for testing (null = use real wall clock time)
var _mock_time: float = -1.0


func _ready() -> void:
	set_process(true)


## Get all production slots
func get_slots() -> Array:
	return _slots


## Get the maximum number of production slots
func get_max_slots() -> int:
	return _max_slots


## Get the number of active productions
func get_active_count() -> int:
	return _active_count


## Start production in the specified slot
## Returns true if successful, false otherwise
func start_production(slot_index: int, recipe_id: String) -> bool:
	# Validate slot index
	if slot_index < 0 or slot_index >= _max_slots:
		return false

	# Validate recipe ID
	if recipe_id.is_empty():
		return false

	# Check if slot is already active
	if _is_slot_active(slot_index):
		return false

	# Get recipe
	var recipe: Resource
	if _mock_recipe:
		recipe = _mock_recipe
	else:
		recipe = DataManager.get_recipe(recipe_id)
		if not recipe:
			push_error("BakeryManager: Recipe not found - %s" % recipe_id)
			return false

	# Create new production slot as Dictionary
	var slot: Dictionary = {
		"slot_index": slot_index,
		"recipe": recipe,
		"start_time": _get_current_time(),
		"progress": 0.0,
		"is_active": true,
		"is_completed": false,
		"remaining_time": recipe.production_time
	}

	_slots.append(slot)
	_active_count += 1

	production_started.emit(slot_index, recipe_id)
	return true


## Get current time (mock or real wall clock)
func _get_current_time() -> float:
	if _mock_time >= 0.0:
		return _mock_time
	return Time.get_unix_time_from_system()


## Check if a slot is currently active
func _is_slot_active(slot_index: int) -> bool:
	for slot in _slots:
		if (
			slot is Dictionary
			and slot.get("slot_index") == slot_index
			and slot.get("is_active", false)
		):
			return true
	return false


## Complete production in the specified slot
func complete_production(slot_index: int) -> void:
	for slot in _slots:
		if slot.get("slot_index") == slot_index:
			slot["is_active"] = false
			slot["is_completed"] = true
			slot["progress"] = 1.0
			_active_count -= 1

			var recipe: Resource = slot.get("recipe")
			if recipe:
				var recipe_id: String = recipe.id
				production_completed.emit(slot_index, recipe_id)
			break


## Collect finished production from a slot, clearing it for reuse.
## Returns recipe_id if successful, empty string otherwise.
func collect_production(slot_index: int) -> String:
	for i in range(_slots.size()):
		var slot: Dictionary = _slots[i]
		if slot.get("slot_index") == slot_index:
			var recipe: Resource = slot.get("recipe")
			var recipe_id: String = recipe.id if recipe else ""
			_slots.remove_at(i)
			EventBus.production_cleared.emit(slot_index)
			return recipe_id
	return ""


## Process function to handle production timers (wall clock based)
func _process(delta: float) -> void:
	# Use mock time if available (for testing), otherwise use real wall clock
	var current_time: float
	if _mock_time >= 0.0:
		_mock_time += delta  # Advance mock time by delta FIRST
		current_time = _mock_time  # Then use updated mock time
	else:
		current_time = Time.get_unix_time_from_system()

	# Process each active slot
	for slot in _slots:
		if slot is Dictionary and slot.get("is_active", false) and slot.get("recipe"):
			# Calculate elapsed time using wall clock
			var start_time: float = slot.get("start_time", 0.0)
			var elapsed_time: float = current_time - start_time

			# Calculate remaining time based on wall clock
			var recipe: Resource = slot.get("recipe")
			var p_time: float = recipe.production_time
			slot["remaining_time"] = maxf(0.0, p_time - elapsed_time)

			# Update progress based on wall clock elapsed time
			if p_time > 0:
				slot["progress"] = minf(1.0, elapsed_time / p_time)
				# Emit progress signal for UI updates
				var slot_index: int = slot.get("slot_index", 0)
				EventBus.production_progressed.emit(slot_index, slot["progress"])

			# Check if production is complete
			if slot["remaining_time"] <= 0:
				slot["remaining_time"] = 0
				slot["progress"] = 1.0
				complete_production(slot.get("slot_index", 0))


## Get remaining time for a slot
func get_remaining_time(slot_index: int) -> float:
	for slot in _slots:
		if (
			slot is Dictionary
			and slot.get("slot_index") == slot_index
			and slot.get("is_active", false)
		):
			return slot.get("remaining_time", 0.0)
	return 0.0


## Reset mock time to 0.0 (for testing)
## This should be called before starting production in tests
## to ensure consistent timing
func reset_mock_time() -> void:
	_mock_time = 0.0


## Set mock recipe for testing
## This allows tests to use a consistent recipe without DataManager
func set_mock_recipe(recipe: Resource) -> void:
	_mock_recipe = recipe


## Clear mock recipe (for testing)
func clear_mock_recipe() -> void:
	_mock_recipe = null


## Restore production slots from save data
## Called by GameManager.load_game() to restore saved production state
func restore_slots(slots_data: Array) -> void:
	# Clear existing slots
	_slots.clear()
	_active_count = 0

	# Restore each slot
	for slot_data in slots_data:
		if not slot_data is Dictionary:
			continue

		var recipe_id: String = slot_data.get("recipe_id", "")
		if recipe_id.is_empty():
			continue

		var recipe: Resource = DataManager.get_recipe(recipe_id)
		if not recipe:
			continue

		var slot: Dictionary = {
			"slot_index": slot_data.get("slot_index", 0),
			"recipe": recipe,
			"start_time": slot_data.get("start_time", 0.0),
			"progress": slot_data.get("progress", 0.0),
			"is_active": slot_data.get("is_active", false),
			"is_completed": slot_data.get("is_completed", false),
			"remaining_time": 0.0
		}

		# Recalculate remaining time based on current time
		var current_time: float = Time.get_unix_time_from_system()
		var elapsed: float = current_time - slot["start_time"]
		slot["remaining_time"] = maxf(0.0, recipe.production_time - elapsed)
		if recipe.production_time > 0:
			slot["progress"] = minf(1.0, elapsed / recipe.production_time)

		_slots.append(slot)
		if slot["is_active"]:
			_active_count += 1
