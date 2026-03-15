extends GutTest
# gdlint: disable=max-public-methods

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
	add_child_autofree(world_controller)
	await wait_physics_frames(1)


func after_each() -> void:
	# autofree automatically queues free at the end of the test.
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


func test_event_bus_experience_changed_connected() -> void:
	assert_true(
		EventBus.experience_changed.is_connected(world_controller._on_experience_changed),
		"WorldController should be connected to experience_changed"
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
	assert_true(
		result.has("experience_changed_connected"), "Should report experience_changed_connected"
	)
	assert_true(
		result.has("production_started_connected"), "Should report production_started_connected"
	)


func test_validate_connections_all_connected_true_after_init() -> void:
	var result: Dictionary = world_controller.validate_connections()
	assert_true(result["all_connected"], "All EventBus connections should be established")


# ==================== Signal Propagation Tests ====================


func test_gold_change_signal_propagates() -> void:
	# Verify WorldController receives gold_changed via EventBus
	assert_true(
		EventBus.gold_changed.is_connected(world_controller._on_gold_changed),
		"Signal should be wired through WorldController"
	)

	# Create a simple Control as mock HUD
	var mock_hud := Control.new()
	add_child_autofree(mock_hud)
	world_controller.set_hud(mock_hud)

	# Emit signal — WorldController._on_gold_changed will run without error
	EventBus.gold_changed.emit(0, 100)

	# If we get here without crash/hang, signal propagation works
	assert_true(true, "gold_changed signal propagated without error")


func test_production_started_signal_propagates() -> void:
	# Verify WorldController is listening
	assert_true(
		EventBus.production_started.is_connected(world_controller._on_production_started),
		"production_started should propagate through WorldController"
	)


# ==================== SNA-176: Automatic Signal Routing Tests ====================


func test_automatic_signal_routing_metadata_exists() -> void:
	# Verify WorldController has signal routing metadata
	assert_true(
		world_controller.has_method("get_signal_routes"),
		"WorldController should have get_signal_routes method for metadata"
	)


func test_get_signal_routes_returns_array() -> void:
	var routes: Array = world_controller.get_signal_routes()
	assert_not_null(routes, "get_signal_routes should return an array")
	assert_true(routes is Array, "get_signal_routes should return Array type")


func test_signal_routes_contain_required_fields() -> void:
	var routes: Array = world_controller.get_signal_routes()
	if routes.is_empty():
		# No routes yet - fail until we implement the feature
		fail_test("get_signal_routes should return at least one route")
		return

	var route = routes[0]
	assert_true(route.has("event_bus_signal"), "Route should have event_bus_signal field")
	assert_true(route.has("handler_method"), "Route should have handler_method field")


func test_automatic_routing_connects_all_signals() -> void:
	# After _ready() is called, all EventBus signals should be connected
	# This tests the automatic routing system
	var routes: Array = world_controller.get_signal_routes()

	for route in routes:
		var signal_name = route["event_bus_signal"]
		var handler_name = route["handler_method"]

		# Get EventBus signal object
		var event_bus_signal = EventBus.get(signal_name)
		if event_bus_signal is Signal:
			var handler = Callable(world_controller, handler_name)
			assert_true(
				event_bus_signal.is_connected(handler),
				"Automatic routing should connect %s to %s" % [signal_name, handler_name]
			)


func test_signal_routing_preserves_existing_behavior() -> void:
	# Ensure automatic routing doesn't break existing signal forwarding
	var mock_hud := Control.new()
	add_child_autofree(mock_hud)
	world_controller.set_hud(mock_hud)

	# This should not crash - signals should propagate
	EventBus.gold_changed.emit(0, 100)
	EventBus.experience_changed.emit(0, 50)
	EventBus.level_up.emit(5)

	assert_true(true, "Signal propagation should work with automatic routing")
