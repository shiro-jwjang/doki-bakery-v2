extends Node

## BakeryManager Autoload
##
## Manages production slots for the bakery. Handles starting production,
## tracking active slots, and enforcing slot limits based on ShopData.
## SNA-74: BakeryManager 슬롯 관리

## Signal emitted when production starts
signal production_started(slot_index: int, recipe_id: String)

## Signal emitted when production completes
signal production_completed(slot_index: int, recipe_id: String)

## Signal emitted when production fails
signal production_failed(slot_index: int, reason: String)

const ProductionSlotClass = preload("res://resources/data/production_slot.gd")

## Maximum number of production slots
var _max_slots: int = 3

## Array of active production slots
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

	# Create new production slot
	var slot = ProductionSlotClass.new()
	slot.slot_index = slot_index
	slot.is_active = true
	# Use mock time if available (for testing), otherwise use real wall clock
	if _mock_time >= 0.0:
		slot.start_time = _mock_time
	else:
		slot.start_time = Time.get_unix_time_from_system()

	# Use mock recipe if available (for testing), otherwise try DataManager
	if _mock_recipe:
		slot.recipe = _mock_recipe
		# Initialize remaining time based on recipe production time
		slot.remaining_time = _mock_recipe.production_time

	_slots.append(slot)
	_active_count += 1

	production_started.emit(slot_index, recipe_id)
	return true


## Check if a slot is currently active
func _is_slot_active(slot_index: int) -> bool:
	for slot in _slots:
		if slot is ProductionSlotClass and slot.slot_index == slot_index and slot.is_active:
			return true
	return false


## Complete production in the specified slot
func complete_production(slot_index: int) -> void:
	for slot in _slots:
		if slot is ProductionSlotClass and slot.slot_index == slot_index:
			slot.is_active = false
			slot.is_completed = true
			slot.progress = 1.0
			_active_count -= 1

			if slot.recipe:
				production_completed.emit(slot_index, slot.recipe.id)
				# Also emit EventBus signal
				EventBus.production_completed.emit(slot_index, slot.recipe.id)
				# Make bread sellable by selling it through EconomyManager
				EconomyManager.sell_bread(slot.recipe)
			break


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
		if slot is ProductionSlotClass and slot.is_active and slot.recipe:
			# Calculate elapsed time using wall clock
			var elapsed_time = current_time - slot.start_time

			# Calculate remaining time based on wall clock
			slot.remaining_time = maxf(0.0, slot.recipe.production_time - elapsed_time)

			# Update progress based on wall clock elapsed time
			if slot.recipe.production_time > 0:
				slot.progress = minf(1.0, elapsed_time / slot.recipe.production_time)

			# Check if production is complete
			if slot.remaining_time <= 0:
				slot.remaining_time = 0
				slot.progress = 1.0
				complete_production(slot.slot_index)


## Get remaining time for a slot
func get_remaining_time(slot_index: int) -> float:
	for slot in _slots:
		if slot is ProductionSlotClass and slot.slot_index == slot_index and slot.is_active:
			return slot.remaining_time
	return 0.0


## Reset mock time to 0.0 (for testing)
## This should be called before starting production in tests
## to ensure consistent timing
func reset_mock_time() -> void:
	_mock_time = 0.0
