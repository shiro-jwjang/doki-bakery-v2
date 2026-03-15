extends Control

## DisplaySlots
##
## Container for display slots that show baked goods for sale.
## Manages slot creation and provides helpers for finding empty slots.
## SNA-117: DisplaySlots 씬 생성 및 WorldView 배치

## Array of DisplaySlot nodes
var _slots: Array[Node] = []

## Slot container
@onready var _slot_container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	# Wait for onready to initialize
	await get_tree().process_frame
	_collect_slots()


## Collect all DisplaySlot children
func _collect_slots() -> void:
	_slots.clear()
	if _slot_container == null:
		return

	for child in _slot_container.get_children():
		if child.has_method("setup") and child.has_method("has_bread"):
			_slots.append(child)


## Get all display slots
## Returns: Array of DisplaySlot nodes
func get_slots() -> Array[Node]:
	# Ensure slots are collected
	if _slots.is_empty() and _slot_container != null:
		_collect_slots()
	return _slots


## Get the first empty slot (without bread)
## Returns: DisplaySlot node or null if all slots are full
func get_empty_slot() -> Node:
	for slot in get_slots():
		if slot.has_method("has_bread") and not slot.has_bread():
			return slot
	return null


## Get the number of empty slots
func get_empty_slot_count() -> int:
	var count := 0
	for slot in get_slots():
		if slot.has_method("has_bread") and not slot.has_bread():
			count += 1
	return count
