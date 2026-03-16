extends Node

## WorldController
##
## Central controller for WorldView that manages UI components and
## ensures proper EventBus signal wiring between Autoload managers
## and WorldView child nodes.
##
## SNA-98: EventBus 중앙 배선 스크립트
##
## Responsibilities:
## - Manages UI components within WorldView hierarchy
## - Connects EventBus signals to UI component methods
## - Coordinates between GameManager, BakeryManager, SalesManager and UI

const LEVEL_UP_NOTIFICATION_SCENE = preload("res://scenes/ui/level_up_notification.tscn")

## Reference to UI container (CanvasLayer)
@onready var ui_layer: CanvasLayer = get_node_or_null("../UI")

## Reference to HUD component
@export var hud: Control = null

## Reference to ProductionPanel component
@export var production_panel: Control = null

## Reference to DisplaySlots container
@export var display_slots: Node = null

## Reference to BreadMenu component
@export var bread_menu: Control = null

## Reference to LevelUpNotification component
var level_up_notification: Control = null

## Flag indicating if EventBus connections have been established
var _connections_established: bool = false


func _ready() -> void:
	# Find and cache UI components FIRST
	find_ui_components()
	# Create level up notification after finding UI
	_create_level_up_notification()
	# Connect EventBus signals to UI handlers
	_connect_event_bus_signals()

	# Explicitly ensure UI visibility
	if ui_layer:
		ui_layer.visible = true


## Connect EventBus signals to this controller for forwarding to UI.
func _connect_event_bus_signals() -> void:
	# Gold/XP changes → HUD
	if not EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.connect(_on_gold_changed)

	if not EventBus.experience_changed.is_connected(_on_experience_changed):
		EventBus.experience_changed.connect(_on_experience_changed)

	if not EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.connect(_on_level_up)

	# Premium currency changes → HUD
	if not EventBus.premium_changed.is_connected(_on_premium_changed):
		EventBus.premium_changed.connect(_on_premium_changed)

	# Production events → ProductionPanel
	if not EventBus.production_started.is_connected(_on_production_started):
		EventBus.production_started.connect(_on_production_started)

	if not EventBus.production_progressed.is_connected(_on_production_progressed):
		EventBus.production_progressed.connect(_on_production_progressed)

	if not EventBus.production_completed.is_connected(_on_production_completed):
		EventBus.production_completed.connect(_on_production_completed)

	# Baking finished → DisplaySlots
	if not EventBus.baking_finished.is_connected(_on_baking_finished):
		EventBus.baking_finished.connect(_on_baking_finished)

	if not EventBus.production_cleared.is_connected(_on_production_cleared):
		EventBus.production_cleared.connect(_on_production_cleared)

	if not EventBus.bread_sold.is_connected(_on_bread_sold):
		EventBus.bread_sold.connect(_on_bread_sold)

	# Initialize UI components with current state
	if hud and hud.has_method("_on_premium_changed"):
		hud._on_premium_changed(0, GameManager.legendary_bread)

	# SNA-193: Initialize display slots from SalesManager inventory
	# This ensures that when loading a saved game, display slots show
	# items that were in inventory at the time of save
	if display_slots and SalesManager.has_method("initialize_display_slots"):
		SalesManager.initialize_display_slots(display_slots)

	# Connect local UI signals
	_connect_ui_signals()

	# Ensure BreadMenu is hidden initially
	if bread_menu:
		bread_menu.visible = false

	_connections_established = true


## Find and cache UI components within WorldView hierarchy.
## Returns a dictionary with found components.
func find_ui_components() -> Dictionary:
	var components: Dictionary = {}

	# If variables are already assigned via Inspector, use them
	if not hud:
		hud = get_node_or_null("../UI/HUD")
	if not production_panel:
		production_panel = get_node_or_null("../UI/ProductionPanel")
	if not display_slots:
		display_slots = get_node_or_null("../UI/DisplaySlots")
	if not bread_menu:
		bread_menu = get_node_or_null("../UI/BreadMenu")

	if hud:
		components["hud"] = hud
	if production_panel:
		components["production_panel"] = production_panel
	if display_slots:
		components["display_slots"] = display_slots
	if bread_menu:
		components["bread_menu"] = bread_menu

	return components


## Validate that all required EventBus connections are established.
## Returns a dictionary with validation results.
func validate_connections() -> Dictionary:
	var results: Dictionary = {}

	# Check EventBus signal connections
	results["gold_changed_connected"] = EventBus.gold_changed.is_connected(_on_gold_changed)
	results["premium_changed_connected"] = EventBus.premium_changed.is_connected(
		_on_premium_changed
	)
	results["experience_changed_connected"] = EventBus.experience_changed.is_connected(
		_on_experience_changed
	)
	results["production_started_connected"] = EventBus.production_started.is_connected(
		_on_production_started
	)
	results["production_completed_connected"] = EventBus.production_completed.is_connected(
		_on_production_completed
	)

	# Check UI component presence
	results["hud"] = hud != null
	results["production_panel"] = production_panel != null
	results["display_slots"] = display_slots != null

	# Overall status
	results["all_connected"] = _connections_established

	return results


## Connect local UI signals (coordination between components)
func _connect_ui_signals() -> void:
	if (
		production_panel
		and not production_panel.slot_clicked.is_connected(_on_production_slot_clicked)
	):
		production_panel.slot_clicked.connect(_on_production_slot_clicked)


# ==================== EventBus Signal Handlers ====================


## Forward gold changes to HUD
func _on_gold_changed(old: int, new: int) -> void:
	if hud and hud.has_method("_on_gold_changed"):
		hud._on_gold_changed(old, new)


## Forward premium changes to HUD
func _on_premium_changed(_old: int, new: int) -> void:
	if hud and hud.has_method("_on_premium_changed"):
		hud._on_premium_changed(_old, new)


## Forward XP changes to HUD
func _on_experience_changed(old: int, new: int) -> void:
	if hud and hud.has_method("_on_experience_changed"):
		hud._on_experience_changed(old, new)


## Forward level up to HUD
func _on_level_up(new_level: int) -> void:
	if hud and hud.has_method("_on_level_up"):
		hud._on_level_up(new_level)

	# Show level up notification
	_show_level_up_notification(new_level)


## Forward production started to ProductionPanel
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	if production_panel and production_panel.has_method("on_production_started"):
		production_panel.on_production_started(slot_index, recipe_id)


## Forward production progress to ProductionPanel
func _on_production_progressed(slot_index: int, progress: float) -> void:
	if production_panel and production_panel.has_method("on_production_progressed"):
		production_panel.on_production_progressed(slot_index, progress)


## Forward production completed to ProductionPanel
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	if production_panel and production_panel.has_method("on_production_completed"):
		production_panel.on_production_completed(slot_index, recipe_id)


## Forward baking finished to DisplaySlots (find empty slot and fill)
func _on_baking_finished(recipe_id: String) -> void:
	if display_slots and display_slots.has_method("get_empty_slot"):
		var empty_slot = display_slots.get_empty_slot()
		if empty_slot and empty_slot.has_method("setup"):
			var recipe = DataManager.get_recipe(recipe_id)
			if recipe:
				empty_slot.setup(recipe_id, recipe.base_price)


## Forward bread sold to DisplaySlots
func _on_bread_sold(recipe_id: String, price: int) -> void:
	if display_slots and display_slots.has_method("on_bread_sold"):
		display_slots.on_bread_sold(recipe_id, price)


## Handle production cleared signal -> Reset Slot UI to Empty
func _on_production_cleared(slot_index: int) -> void:
	if production_panel:
		var slot_ui = production_panel.get_slot_ui(slot_index)
		if slot_ui and slot_ui.has_method("setup"):
			slot_ui.setup(slot_index)


## Handle production slot click -> Show BreadMenu
func _on_production_slot_clicked(slot_index: int) -> void:
	# Show bread menu to start baking (auto-collection is handled via signals)
	if bread_menu and bread_menu.has_method("show_for_slot"):
		bread_menu.show_for_slot(slot_index)


# ==================== Getters/Setters ====================


## Get the HUD component reference.
func get_hud() -> Variant:
	return hud


## Get the ProductionPanel component reference.
func get_production_panel() -> Variant:
	return production_panel


## Get the DisplaySlots container reference.
func get_display_slots() -> Variant:
	return display_slots


## Manually set HUD reference (useful for testing).
func set_hud(p_hud: Control) -> void:
	hud = p_hud


## Manually set ProductionPanel reference (useful for testing).
func set_production_panel(p_panel: Control) -> void:
	production_panel = p_panel


## Manually set DisplaySlots reference (useful for testing).
func set_display_slots(p_slots: Node) -> void:
	display_slots = p_slots


# ==================== Level Up Notification ====================


## Create and setup level up notification
func _create_level_up_notification() -> void:
	if LEVEL_UP_NOTIFICATION_SCENE:
		level_up_notification = LEVEL_UP_NOTIFICATION_SCENE.instantiate()
		# Add to UI layer if possible, otherwise to ourself
		if ui_layer:
			ui_layer.add_child(level_up_notification)
		else:
			add_child(level_up_notification)

		if level_up_notification:
			level_up_notification.visible = false


## Show level up notification with unlocked items
func _show_level_up_notification(level: int) -> void:
	if level_up_notification and level_up_notification.has_method("show_unlocks"):
		var unlocked_items = DataManager.get_unlocks_for_level(level)

		# Convert recipe IDs to display names
		var item_data: Array[Dictionary] = []
		for item_id in unlocked_items:
			var recipe = DataManager.get_recipe(item_id)
			var item_dict = {"id": item_id}
			if recipe:
				item_dict["name"] = recipe.display_name
			else:
				item_dict["name"] = item_id
			item_data.append(item_dict)

		level_up_notification.show_unlocks(level, item_data)
