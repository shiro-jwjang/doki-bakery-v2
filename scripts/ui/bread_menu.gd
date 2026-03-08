extends Control

## BreadMenu UI
##
## Popup menu for selecting bread to produce.
## Shown when player clicks an empty production slot.
## SNA-96: 슬롯 클릭 → BreadMenu → 생산 시작

## Emitted when a bread is selected for production
signal bread_selected(recipe_id: String)

## The slot index this menu is targeting
var _target_slot: int = -1

## Available recipes (populated from DataManager)
var _recipes: Array = []


func _ready() -> void:
	# Start hidden
	visible = false

	# Connect to EventBus for production requests
	if not EventBus.request_produce.is_connected(_on_request_produce):
		EventBus.request_produce.connect(_on_request_produce)

	# Load recipes from DataManager
	_load_recipes()


## Get the target slot index
func get_target_slot() -> int:
	return _target_slot


## Show the menu for a specific slot
## Does nothing if the slot is already busy
func show_for_slot(slot_index: int) -> void:
	# Check if slot is already busy
	var slots = BakeryManager.get_slots()
	for slot in slots:
		if slot.slot_index == slot_index and slot.is_active:
			# Slot is busy, don't show menu
			return

	_target_slot = slot_index
	visible = true


## Hide the menu
func hide_menu() -> void:
	visible = false
	_target_slot = -1


## Select a bread and emit signal
func select_bread(recipe_id: String) -> void:
	if _target_slot < 0:
		return

	# Start production via BakeryManager
	var success = BakeryManager.start_production(_target_slot, recipe_id)

	if success:
		# Emit signal for other listeners
		bread_selected.emit(recipe_id)

	# Close menu regardless of success
	hide_menu()


## Handle production request from EventBus
func _on_request_produce(slot_index: int, recipe_id: String) -> void:
	show_for_slot(slot_index)
	select_bread(recipe_id)


## Load available recipes from DataManager
func _load_recipes() -> void:
	_recipes = DataManager.get_all_recipes()
