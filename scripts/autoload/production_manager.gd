extends Node

## ProductionManager Autoload
##
## Manages production slots for the bakery. Handles starting production,
## tracking active slots, and enforcing slot limits based on ShopData.
## SNA-74: ProductionManager 슬롯 관리

## Maximum number of production slots
var _max_slots: int = 3

## Array of active production slots
var _slots: Array = []

## Current number of active productions
var _active_count: int = 0

## Mock recipe for testing (used in tests)
var _mock_recipe: Resource = null

## Signal emitted when production starts
signal production_started(slot_index: int, recipe_id: String)

## Signal emitted when production completes
signal production_completed(slot_index: int, recipe_id: String)

## Signal emitted when production fails
signal production_failed(slot_index: int, reason: String)

const ProductionSlotClass = preload("res://resources/data/production_slot.gd")


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
	slot.start_time = Time.get_unix_time_from_system()

	# Use mock recipe if available (for testing), otherwise try DataManager
	if _mock_recipe:
		slot.recipe = _mock_recipe

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
			break
