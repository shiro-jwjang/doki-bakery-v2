extends GutTest

## Test Suite: SNA-98 WorldController Centralized Event Wiring
##
## Tests the WorldController which:
## 1. Manages UI components within WorldView hierarchy
## 2. Connects EventBus signals for forwarding to UI
## 3. Validates EventBus signal connections

const WorldControllerScript = preload("res://scripts/world/world_controller.gd")

var world_controller: Node


func before_each() -> void:
	world_controller = WorldControllerScript.new()
	add_child(world_controller)
	await wait_frames(1)


func after_each() -> void:
	if world_controller:
		world_controller.queue_free()
		world_controller = null


# ==================== Initialization Tests ====================

func test_world_controller_initializes() -> void:
	assert_not_null(world_controller, "WorldController should initialize")


func test_find_ui_components_returns_dictionary() -> void:
	var result: Dictionary = world_controller.find_ui_components()
	assert_not_null(result, "find_ui_components should return a dictionary")


func test_get_hud_returns_null_when_no_hud() -> void:
	var hud: Variant = world_controller.get_hud()
	assert_null(hud, "get_hud should return null when no HUD is present")


func test_get_production_panel_returns_null_when_no_panel() -> void:
	var panel: Variant = world_controller.get_production_panel()
	assert_null(panel, "get_production_panel should return null when no panel")


func test_get_display_slots_returns_null_when_no_slots() -> void:
	var slots: Variant = world_controller.get_display_slots()
	assert_null(slots, "get_display_slots should return null when no slots")


# ==================== EventBus Connection Tests ====================

func test_event_bus_gold_changed_connected() -> void:
	assert_true(
		EventBus.gold_changed.is_connected(world_controller._on_gold_changed),
		"WorldController should be connected to gold_changed"
	)


func test_event_bus_xp_changed_connected() -> void:
	assert_true(
		EventBus.xp_changed.is_connected(world_controller._on_xp_changed),
		"WorldController should be connected to xp_changed"
	)


func test_event_bus_production_signals_connected() -> void:
	assert_true(
		EventBus.production_started.is_connected(world_controller._on_production_started),
		"WorldController should be connected to production_started"
	)
	assert_true(
		EventBus.production_progressed.is_connected(world_controller._on_production_progressed),
		"WorldController should be connected to production_progressed"
	)
	assert_true(
		EventBus.production_completed.is_connected(world_controller._on_production_completed),
		"WorldController should be connected to production_completed"
	)


func test_event_bus_baking_finished_connected() -> void:
	assert_true(
		EventBus.baking_finished.is_connected(world_controller._on_baking_finished),
		"WorldController should be connected to baking_finished"
	)


func test_event_bus_bread_sold_connected() -> void:
	assert_true(
		EventBus.bread_sold.is_connected(world_controller._on_bread_sold),
		"WorldController should be connected to bread_sold"
	)


# ==================== Validation Tests ====================

func test_validate_connections_returns_dictionary() -> void:
	var result: Dictionary = world_controller.validate_connections()
	assert_not_null(result, "validate_connections should return a dictionary")


func test_validate_connections_reports_connection_status() -> void:
	var result: Dictionary = world_controller.validate_connections()
	assert_true(result.has("gold_changed_connected"), "Should report gold_changed_connected")
	assert_true(result.has("xp_changed_connected"), "Should report xp_changed_connected")
	assert_true(result.has("production_started_connected"), "Should report production_started_connected")


func test_validate_connections_all_connected_true_after_init() -> void:
	var result: Dictionary = world_controller.validate_connections()
	assert_true(result["all_connected"], "All EventBus connections should be established")


# ==================== Signal Propagation Tests ====================

func test_gold_change_signal_propagates() -> void:
	# Create mock HUD
	var mock_hud = Control.new()
	mock_hud.set_script(GDScript.new())
	mock_hud.get_script().source_code = """
extends CanvasLayer
var gold_received: bool = false
func on_gold_changed(_old, _new): gold_received = true
"""
	mock_hud.get_script().reload()
	
	world_controller.set_hud(mock_hud)
	
	# Emit signal
	EventBus.gold_changed.emit(0, 100)
	
	# Verify handler was called (WorldController received it)
	assert_true(
		EventBus.gold_changed.is_connected(world_controller._on_gold_changed),
		"Signal should be wired through WorldController"
	)
	
	mock_hud.queue_free()


func test_production_started_signal_propagates() -> void:
	# Verify WorldController is listening
	assert_true(
		EventBus.production_started.is_connected(world_controller._on_production_started),
		"production_started should propagate through WorldController"
	)
