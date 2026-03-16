extends Node

## WorldController
##
## Central controller for WorldView that coordinates UI components and
## EventBus signal wiring through specialized helper classes.
##
## SNA-98: EventBus 중앙 배선 스크립트
## SNA-186: UIComponentRegistry + UIEventRouter 조합으로 책임 분리
##
## Responsibilities:
## - Coordinate between UIComponentRegistry and UIEventRouter
## - Manage UI component lifecycle
## - Handle UI-specific initialization (level up notification)

const LEVEL_UP_NOTIFICATION_SCENE = preload("res://scenes/ui/level_up_notification.tscn")
const UIComponentRegistryScript = preload("res://scripts/ui/ui_component_registry.gd")
const UIEventRouterScript = preload("res://scripts/ui/ui_event_router.gd")

## Reference to UI container (CanvasLayer)
@onready var ui_layer: CanvasLayer = get_node_or_null("../UI")

## Reference to HUD component (kept for backward compatibility)
@export var hud: Control = null

## Reference to ProductionPanel component (kept for backward compatibility)
@export var production_panel: Control = null

## Reference to DisplaySlots container (kept for backward compatibility)
@export var display_slots: Node = null

## Reference to BreadMenu component (kept for backward compatibility)
@export var bread_menu: Control = null

## Reference to LevelUpNotification component
var level_up_notification: Control = null

## UI Component Registry - manages UI component references
var _component_registry: Node = null

## UI Event Router - manages EventBus signal connections
var _event_router: Node = null


func _ready() -> void:
	# Initialize component registry
	_init_component_registry()

	# Initialize event router
	_init_event_router()

	# Find and cache UI components
	_find_ui_components()

	# Create level up notification
	_create_level_up_notification()

	# Connect EventBus signals through router
	_connect_event_bus_signals()

	# Initialize UI state
	_init_ui_state()


## Initialize UI Component Registry
func _init_component_registry() -> void:
	_component_registry = UIComponentRegistryScript.new()
	_component_registry.set_root_node(self)
	add_child(_component_registry)


## Initialize UI Event Router
func _init_event_router() -> void:
	_event_router = UIEventRouterScript.new()
	_event_router.set_component_registry(_component_registry)
	add_child(_event_router)


## Find and cache UI components using registry.
func _find_ui_components() -> void:
	_component_registry.find_components()

	# Sync exports with registry for backward compatibility
	hud = _component_registry.get_hud()
	production_panel = _component_registry.get_production_panel()
	display_slots = _component_registry.get_display_slots()
	bread_menu = _component_registry.get_bread_menu()


## Connect EventBus signals through router.
func _connect_event_bus_signals() -> void:
	_event_router.connect_event_bus_signals()

	# Initialize UI components with current state
	if hud and hud.has_method("_on_premium_changed"):
		hud._on_premium_changed(0, GameManager.legendary_bread)

	# SNA-193: Initialize display slots from SalesManager inventory
	if display_slots and SalesManager.has_method("initialize_display_slots"):
		SalesManager.initialize_display_slots(display_slots)

	# Connect local UI signals
	_connect_ui_signals()


## Initialize UI state
func _init_ui_state() -> void:
	# Explicitly ensure UI visibility
	if ui_layer:
		ui_layer.visible = true

	# Ensure BreadMenu is hidden initially
	if bread_menu:
		bread_menu.visible = false


## Connect local UI signals (coordination between components)
func _connect_ui_signals() -> void:
	if (
		production_panel
		and not production_panel.slot_clicked.is_connected(_on_production_slot_clicked)
	):
		production_panel.slot_clicked.connect(_on_production_slot_clicked)


## Handle production slot click -> Show BreadMenu
func _on_production_slot_clicked(slot_index: int) -> void:
	# Show bread menu to start baking (auto-collection is handled via signals)
	if bread_menu and bread_menu.has_method("show_for_slot"):
		bread_menu.show_for_slot(slot_index)


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


# ==================== Getters/Setters (Backward Compatibility) ====================


## Find and cache UI components within WorldView hierarchy.
## Returns a dictionary with found components.
func find_ui_components() -> Dictionary:
	return _component_registry.find_components()


## Validate that all required EventBus connections are established.
## Returns a dictionary with validation results.
func validate_connections() -> Dictionary:
	return _event_router.validate_connections()


## Get the HUD component reference.
func get_hud() -> Variant:
	return _component_registry.get_hud()


## Get the ProductionPanel component reference.
func get_production_panel() -> Variant:
	return _component_registry.get_production_panel()


## Get the DisplaySlots container reference.
func get_display_slots() -> Variant:
	return _component_registry.get_display_slots()


## Manually set HUD reference (useful for testing).
func set_hud(p_hud: Control) -> void:
	hud = p_hud
	if _component_registry:
		_component_registry.set_hud(p_hud)


## Manually set ProductionPanel reference (useful for testing).
func set_production_panel(p_panel: Control) -> void:
	production_panel = p_panel
	if _component_registry:
		_component_registry.set_production_panel(p_panel)


## Manually set DisplaySlots reference (useful for testing).
func set_display_slots(p_slots: Node) -> void:
	display_slots = p_slots
	if _component_registry:
		_component_registry.set_display_slots(p_slots)


## Get component registry (for testing/external access)
func get_component_registry() -> Node:
	return _component_registry


## Get event router (for testing/external access)
func get_event_router() -> Node:
	return _event_router
