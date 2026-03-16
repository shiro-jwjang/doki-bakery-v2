extends Node

## BakeryManager Autoload
##
## Manages production slots for the bakery. Handles starting production,
## tracking active slots, and enforcing slot limits based on ShopData.
## SNA-74: BakeryManager 슬롯 관리
## SNA-174: Dictionary 기반 슬롯 관리
## SNA-177: DI 패턴 도입 (TimeProvider, RecipeProvider)

## Signal emitted when production starts
signal production_started(slot_index: int, recipe_id: String)

## Signal emitted when production completes
signal production_completed(slot_index: int, recipe_id: String)

## Signal emitted when production fails
signal production_failed(slot_index: int, reason: String)

## Time provider for wall clock abstraction (DI)
var _time_provider: TimeProvider = null

## Recipe provider for recipe lookup (DI)
var _recipe_provider: RecipeProvider = null

## Maximum number of production slots
var _max_slots: int = 3

## Dictionary of all production slots indexed by slot_index (O(1) lookup)
## Each slot: {slot_index, recipe, start_time, progress, is_active, is_completed, remaining_time}
## SNA-187: O(1) lookup optimization
var _slots: Dictionary = {}

## Dictionary of active slots only (O(1) active slot lookup)
## SNA-187: O(1) _is_slot_active optimization
var _active_slots: Dictionary = {}

## Current number of active productions
var _active_count: int = 0


func _ready() -> void:
	# Initialize providers with default implementations only if not already set
	if _time_provider == null:
		_time_provider = SystemTimeProvider.new()
	if _recipe_provider == null:
		_recipe_provider = DataManagerRecipeProvider.new()
	set_process(true)


## Get all production slots as Array ordered by slot_index
func get_slots() -> Array:
	var slots_array: Array = []
	var indices := _slots.keys()
	indices.sort()  # Ensure slots are returned in slot_index order
	for index in indices:
		slots_array.append(_slots[index])
	return slots_array


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

	# Check if slot is already active (O(1) lookup)
	if _is_slot_active(slot_index):
		return false

	# Get recipe
	var recipe: Resource = _recipe_provider.get_recipe(recipe_id)
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

	# Add to both dictionaries (O(1) insertion)
	_slots[slot_index] = slot
	_active_slots[slot_index] = slot
	_active_count += 1

	production_started.emit(slot_index, recipe_id)
	return true


## Get current time from time provider
func _get_current_time() -> float:
	return _time_provider.get_current_time()


## Check if a slot is currently active (O(1) lookup)
## SNA-187: Optimized from O(n) to O(1) using _active_slots dictionary
func _is_slot_active(slot_index: int) -> bool:
	return _active_slots.has(slot_index)


## Complete production in the specified slot (O(1) lookup)
## SNA-187: Optimized from O(n) to O(1) using dictionary
func complete_production(slot_index: int) -> void:
	if not _slots.has(slot_index):
		return

	var slot: Dictionary = _slots[slot_index]
	slot["is_active"] = false
	slot["is_completed"] = true
	slot["progress"] = 1.0
	_active_count -= 1

	# Remove from active slots dictionary (O(1) removal)
	_active_slots.erase(slot_index)

	var recipe: Resource = slot.get("recipe")
	if recipe:
		var recipe_id: String = recipe.id
		production_completed.emit(slot_index, recipe_id)

		# AUTO-COLLECT: Automatically clear the slot when finished
		collect_production(slot_index)


## Collect finished production from a slot, clearing it for reuse (O(1) lookup).
## Returns recipe_id if successful, empty string otherwise.
## SNA-187: Optimized from O(n) to O(1) using dictionary
func collect_production(slot_index: int) -> String:
	if not _slots.has(slot_index):
		return ""

	var slot: Dictionary = _slots[slot_index]
	var recipe: Resource = slot.get("recipe")
	var recipe_id: String = recipe.id if recipe else ""

	# Remove from both dictionaries (O(1) deletion)
	_slots.erase(slot_index)
	_active_slots.erase(slot_index)
	EventBusAutoload.production_cleared.emit(slot_index)
	return recipe_id


## Process function to handle production timers (wall clock based)
func _process(delta: float) -> void:
	# Advance mock time if using MockTimeProvider
	if _time_provider is MockTimeProvider:
		_time_provider.advance_time(delta)

	var current_time: float = _time_provider.get_current_time()

	# Process each active slot (iterate over active_slots dictionary)
	for slot_index in _active_slots.keys():
		var slot: Dictionary = _active_slots[slot_index]
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
				EventBusAutoload.production_progressed.emit(slot_index, slot["progress"])

			# Check if production is complete
			if slot["remaining_time"] <= 0:
				slot["remaining_time"] = 0
				slot["progress"] = 1.0
				complete_production(slot_index)


## Get remaining time for a slot (O(1) lookup)
## SNA-187: Optimized from O(n) to O(1) using dictionary
func get_remaining_time(slot_index: int) -> float:
	if not _active_slots.has(slot_index):
		return 0.0

	var slot: Dictionary = _active_slots[slot_index]
	return slot.get("remaining_time", 0.0)


## Set time provider (for testing)
## This allows tests to inject MockTimeProvider
func set_time_provider(provider: TimeProvider) -> void:
	_time_provider = provider


## Set recipe provider (for testing)
## This allows tests to inject MockRecipeProvider
func set_recipe_provider(provider: RecipeProvider) -> void:
	_recipe_provider = provider


## Helper for testing: Reset to default providers
## Use in tests that need to reset BakeryManager state
func reset_to_default_providers() -> void:
	_time_provider = SystemTimeProvider.new()
	_recipe_provider = DataManagerRecipeProvider.new()


## Restore production slots from save data
## Called by GameManager.load_game() to restore saved production state
func restore_slots(slots_data: Array) -> void:
	# Clear existing slots
	_slots.clear()
	_active_slots.clear()
	_active_count = 0

	# Restore each slot
	for slot_data in slots_data:
		if not slot_data is Dictionary:
			continue

		var recipe_id: String = slot_data.get("recipe_id", "")
		if recipe_id.is_empty():
			continue

		var recipe: Resource = _recipe_provider.get_recipe(recipe_id)
		if not recipe:
			continue

		var slot_index: int = slot_data.get("slot_index", 0)
		var slot: Dictionary = {
			"slot_index": slot_index,
			"recipe": recipe,
			"start_time": slot_data.get("start_time", 0.0),
			"progress": slot_data.get("progress", 0.0),
			"is_active": slot_data.get("is_active", false),
			"is_completed": slot_data.get("is_completed", false),
			"remaining_time": 0.0
		}

		# Recalculate remaining time based on current time
		var current_time: float = _time_provider.get_current_time()
		var elapsed: float = current_time - slot["start_time"]
		slot["remaining_time"] = maxf(0.0, recipe.production_time - elapsed)
		if recipe.production_time > 0:
			slot["progress"] = minf(1.0, elapsed / recipe.production_time)

		# Add to dictionaries (O(1) insertion)
		_slots[slot_index] = slot
		if slot["is_active"]:
			_active_slots[slot_index] = slot
			_active_count += 1
