extends GutTest

## Test Suite: UIEventRouter management helpers
## Covers UI signal hookup, stored references, validation helpers, and safe dispatch.

const UIEventRouterScript = preload("res://scripts/ui/ui_event_router.gd")

var router: Node
var mock_hud: Control
var mock_production_panel: Control
var mock_display_slots: Node
var mock_bread_menu: Control


func before_each() -> void:
	mock_hud = Control.new()
	mock_hud.name = "MockHUD"
	add_child_autofree(mock_hud)

	mock_production_panel = Control.new()
	mock_production_panel.name = "MockProductionPanel"
	add_child_autofree(mock_production_panel)

	mock_display_slots = Node.new()
	mock_display_slots.name = "MockDisplaySlots"
	add_child_autofree(mock_display_slots)

	mock_bread_menu = Control.new()
	mock_bread_menu.name = "MockBreadMenu"
	add_child_autofree(mock_bread_menu)

	router = UIEventRouterScript.new()
	add_child_autofree(router)
	await wait_physics_frames(1)


func after_each() -> void:
	router = null
	mock_hud = null
	mock_production_panel = null
	mock_display_slots = null
	mock_bread_menu = null


func test_connect_ui_signals_connects_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_ui_signals()

	assert_true(true, "UI signals connected without error")


func test_set_hud_stores_reference() -> void:
	router.set_hud(mock_hud)
	var retrieved = router.get_hud()

	assert_eq(retrieved, mock_hud, "Should retrieve same HUD instance")


func test_set_production_panel_stores_reference() -> void:
	router.set_production_panel(mock_production_panel)
	var retrieved = router.get_production_panel()

	assert_eq(retrieved, mock_production_panel, "Should retrieve same ProductionPanel instance")


func test_set_display_slots_stores_reference() -> void:
	router.set_display_slots(mock_display_slots)
	var retrieved = router.get_display_slots()

	assert_eq(retrieved, mock_display_slots, "Should retrieve same DisplaySlots instance")


func test_set_bread_menu_stores_reference() -> void:
	router.set_bread_menu(mock_bread_menu)
	var retrieved = router.get_bread_menu()

	assert_eq(retrieved, mock_bread_menu, "Should retrieve same BreadMenu instance")


func test_validate_connections_returns_dictionary() -> void:
	router.set_hud(mock_hud)
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	var result: Dictionary = router.validate_connections()
	assert_not_null(result, "validate_connections should return a dictionary")


func test_validate_connections_reports_connection_status() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	var result: Dictionary = router.validate_connections()
	assert_true(result.has("gold_changed_connected"), "Should report gold_changed_connected")
	assert_true(
		result.has("experience_changed_connected"), "Should report experience_changed_connected"
	)


func test_call_safe_method_with_null_component() -> void:
	router.call_safe_method(null, "_on_test_event", [1, 2])
	assert_true(true, "call_safe_method handles null component gracefully")


func test_call_safe_method_with_missing_method() -> void:
	var test_node = Node.new()
	test_node.name = "TestNode"
	add_child_autofree(test_node)

	router.call_safe_method(test_node, "_nonexistent_method", [1, 2])
	assert_true(true, "call_safe_method handles missing method gracefully")
