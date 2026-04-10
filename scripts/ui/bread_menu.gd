class_name BreadMenu
extends BaseUIComponent

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
var _button_container: VBoxContainer = null

@export var recipe_item_scene: PackedScene = preload("res://scenes/ui/recipe_item.tscn")


func _ready() -> void:
	# Safely find VBoxContainer (may not exist when instantiated without scene)
	_button_container = get_node_or_null("ScrollContainer/MarginContainer/VBoxContainer")

	# Start hidden
	visible = false

	# Connect to EventBus for production requests (SNA-160: unified pattern)
	_connect_signal(EventBusAutoload.baking_requested, _on_baking_requested)

	# Load recipes from DataManager
	_load_recipes()

	# Build UI buttons
	_build_buttons()


## Get the target slot index
func get_target_slot() -> int:
	return _target_slot


## Show the menu for a specific slot
## If force is false, does nothing if the slot is already busy
func show_for_slot(slot_index: int, force: bool = false) -> void:
	if not force and _is_slot_busy(slot_index):
		return

	_load_recipes()
	_build_buttons()
	_target_slot = slot_index
	visible = true


## Check if a slot is currently busy
func _is_slot_busy(slot_index: int) -> bool:
	var slots = BakeryManager.get_slots()
	for slot in slots:
		if slot.slot_index == slot_index and slot.is_active:
			return true
	return false


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
		_recipes = all_recipes.filter(
			func(recipe: Resource) -> bool:
				return recipe != null and int(recipe.get("unlock_level")) <= GameManager.level
		)
		_recipes.sort_custom(
			func(a: Resource, b: Resource) -> bool:
				var a_level := int(a.get("unlock_level"))
				var b_level := int(b.get("unlock_level"))
				if a_level == b_level:
					return str(a.get("id")) < str(b.get("id"))
				return a_level < b_level
		)
	else:
		_recipes = []
		push_warning("BreadMenu: Failed to load recipes from DataManager")


## Build buttons for each recipe
func _build_buttons() -> void:
	# Create container if not exists
	if _button_container == null:
		var scroll := ScrollContainer.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(scroll)

		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		scroll.add_child(margin)

		_button_container = VBoxContainer.new()
		_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(_button_container)

	# Clear existing buttons
	for child in _button_container.get_children():
		child.queue_free()

	# Create a RecipeItem for each recipe
	for recipe in _recipes:
		if recipe == null:
			continue

		var item = recipe_item_scene.instantiate()
		_button_container.add_child(item)
		item.setup(recipe)
		item.pressed.connect(_on_recipe_selected.bind(recipe.id))


## Handle recipe selection
func _on_recipe_selected(recipe_id: String) -> void:
	select_bread(recipe_id)
