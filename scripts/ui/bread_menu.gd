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

## Container for bread buttons
@onready var _button_container: VBoxContainer = $VBoxContainer


func _ready() -> void:
	# Start hidden
	visible = false

	# Connect to EventBus for production requests
	if not EventBus.baking_requested.is_connected(_on_baking_requested):
		EventBus.baking_requested.connect(_on_baking_requested)

	# Load recipes from DataManager
	_load_recipes()

	# Build UI buttons
	_build_buttons()


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


## Handle baking request from EventBus
func _on_baking_requested(slot_index: int, recipe_id: String) -> void:
	show_for_slot(slot_index)
	select_bread(recipe_id)


## Load available recipes from DataManager
func _load_recipes() -> void:
	var all_recipes = DataManager.get_all_recipes()
	if all_recipes != null:
		_recipes = all_recipes
	else:
		_recipes = []
		push_warning("BreadMenu: Failed to load recipes from DataManager")


## Build buttons for each recipe
func _build_buttons() -> void:
	# Create container if not exists
	if _button_container == null:
		_button_container = VBoxContainer.new()
		add_child(_button_container)

	# Clear existing buttons
	for child in _button_container.get_children():
		child.queue_free()

	# Create a button for each recipe
	for recipe in _recipes:
		if recipe == null:
			continue
		var button := Button.new()
		button.name = "Btn_%s" % recipe.id
		button.text = recipe.display_name if recipe.display_name else recipe.id
		button.pressed.connect(_on_bread_button_pressed.bind(recipe.id))
		_button_container.add_child(button)


## Handle bread button press
func _on_bread_button_pressed(recipe_id: String) -> void:
	select_bread(recipe_id)
