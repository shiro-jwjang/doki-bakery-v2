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
## - Ensures EventBus signals properly connect to UI handlers
## - Coordinates between GameManager, BakeryManager, SalesManager and UI
##
## Note: Current UI components (HUD, ProductionPanel, DisplaySlot) already
## connect to EventBus in their own _ready() methods. WorldController provides
## centralized management and validation of these connections.

## Reference to HUD component
var _hud: CanvasLayer = null

## Reference to ProductionPanel component
var _production_panel: Control = null

## Reference to DisplaySlots container
var _display_slots: Node = null


func _ready() -> void:
	# Find and cache UI component references
	find_ui_components()

	# Validate signal connections
	validate_connections()


## Find and cache references to UI components in WorldView
func find_ui_components() -> void:
	var world_view := get_parent() as Node2D
	if world_view == null:
		push_error("WorldController: parent must be WorldView")
		return

	# Find HUD in UI CanvasLayer
	var ui_layer = world_view.find_child("UI", true, false)
	if ui_layer != null:
		_hud = ui_layer.find_child("HUD", true, false)
		_production_panel = ui_layer.find_child("ProductionPanel", true, false)
		_display_slots = ui_layer.find_child("DisplaySlots", true, false)

	# Log found components for debugging
	if OS.is_debug_build():
		print(
			(
				"WorldController: Found UI components - HUD: %s, Panel: %s, Slots: %s"
				% [_hud != null, _production_panel != null, _display_slots != null]
			)
		)


## Validate that critical signal connections are established
func validate_connections() -> void:
	# Check GameManager → HUD connection
	if _hud != null:
		_check_signal_connection(EventBus.gold_changed, "HUD", "gold_changed")
		_check_signal_connection(EventBus.xp_changed, "HUD", "xp_changed")
		_check_signal_connection(EventBus.level_up, "HUD", "level_up")

	# Check BakeryManager → ProductionPanel connection
	if _production_panel != null:
		_check_signal_connection(
			EventBus.production_started, "ProductionPanel", "production_started"
		)
		_check_signal_connection(
			EventBus.production_progressed, "ProductionPanel", "production_progressed"
		)
		_check_signal_connection(
			EventBus.production_completed, "ProductionPanel", "production_completed"
		)

	# Check SalesManager → DisplaySlots connection
	if _display_slots != null:
		_check_signal_connection(EventBus.bread_sold, "DisplaySlots", "bread_sold")


## Helper: Check if a signal has any connections and log warning if not
func _check_signal_connection(signal: Signal, component_name: String, signal_name: String) -> void:
	if not signal.is_connected():
		push_warning(
			(
				"WorldController: Signal '%s' has no connections (expected for %s)"
				% [signal_name, component_name]
			)
		)


## Get HUD component reference
func get_hud() -> CanvasLayer:
	return _hud


## Get ProductionPanel component reference
func get_production_panel() -> Control:
	return _production_panel


## Get DisplaySlots component reference
func get_display_slots() -> Node:
	return _display_slots
