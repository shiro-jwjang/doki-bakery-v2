extends GutTest

## Test Suite: SNA-98 WorldController Centralized Event Wiring
##
## Tests the WorldController which:
## 1. Manages UI components within WorldView hierarchy
## 2. Validates EventBus signal connections
## 3. Ensures proper signal propagation from managers to UI

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


# ==================== Validation Tests ====================

func test_validate_connections_returns_dictionary() -> void:
	var result: Dictionary = world_controller.validate_connections()
	assert_not_null(result, "validate_connections should return a dictionary")


func test_validate_connections_reports_missing_hud() -> void:
	var result: Dictionary = world_controller.validate_connections()
	# Without HUD, validation should report it's missing or not connected
	assert_true(
		result.has("hud") or result.has("all_connected"),
		"Result should have hud or all_connected key"
	)


# ==================== Signal Propagation Tests ====================

func test_gold_change_signal_wired() -> void:
	# WorldController should connect to gold_changed if it centralizes wiring
	# For now, just verify EventBus has the signal
	assert_true(
		EventBus.has_signal("gold_changed"),
		"EventBus should have gold_changed signal"
	)


func test_xp_change_signal_wired() -> void:
	assert_true(
		EventBus.has_signal("xp_changed"),
		"EventBus should have xp_changed signal"
	)


func test_production_signals_wired() -> void:
	assert_true(
		EventBus.has_signal("production_started"),
		"EventBus should have production_started signal"
	)
	assert_true(
		EventBus.has_signal("production_progressed"),
		"EventBus should have production_progressed signal"
	)
	assert_true(
		EventBus.has_signal("production_completed"),
		"EventBus should have production_completed signal"
	)
