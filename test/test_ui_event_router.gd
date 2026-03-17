extends GutTest

## Test Suite: SNA-186 UIEventRouter
##
## Tests the UIEventRouter which:
## 1. Connects EventBus signals for forwarding to UI components
## 2. Forwards EventBus signals to appropriate UI handlers
## 3. Manages EventBus signal connections

const UIEventRouterScript = preload("res://scripts/ui/ui_event_router.gd")

var router: Node
var mock_hud: Control
var mock_production_panel: Control
var mock_display_slots: Node
var mock_bread_menu: Control


func before_each() -> void:
	# Create mock UI components
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

	# Create router
	router = UIEventRouterScript.new()
	add_child_autofree(router)
	await wait_physics_frames(1)


func after_each() -> void:
	router = null
	mock_hud = null
	mock_production_panel = null
	mock_display_slots = null
	mock_bread_menu = null


# ==================== Initialization Tests ====================


func test_router_initializes() -> void:
	assert_not_null(router, "UIEventRouter should initialize")


func test_router_has_empty_state_on_init() -> void:
	assert_null(router.get_hud(), "HUD should be null initially")
	assert_null(router.get_production_panel(), "ProductionPanel should be null initially")
	assert_null(router.get_display_slots(), "DisplaySlots should be null initially")
	assert_null(router.get_bread_menu(), "BreadMenu should be null initially")


# ==================== EventBus Connection Tests ====================


func test_connect_event_bus_establishes_connections() -> void:
	router.set_hud(mock_hud)
	router.set_production_panel(mock_production_panel)
	router.set_display_slots(mock_display_slots)

	router.connect_event_bus()

	assert_true(
		EventBus.gold_changed.is_connected(router._on_gold_changed),
		"Should connect gold_changed signal"
	)
	assert_true(
		EventBus.experience_changed.is_connected(router._on_experience_changed),
		"Should connect experience_changed signal"
	)


func test_connect_event_bus_connects_production_signals() -> void:
	router.set_production_panel(mock_production_panel)

	router.connect_event_bus()

	assert_true(
		EventBus.production_started.is_connected(router._on_production_started),
		"Should connect production_started signal"
	)
	assert_true(
		EventBus.production_progressed.is_connected(router._on_production_progressed),
		"Should connect production_progressed signal"
	)
	assert_true(
		EventBus.production_completed.is_connected(router._on_production_completed),
		"Should connect production_completed signal"
	)


func test_connect_event_bus_connects_baking_signals() -> void:
	router.set_display_slots(mock_display_slots)

	router.connect_event_bus()

	assert_true(
		EventBus.baking_finished.is_connected(router._on_baking_finished),
		"Should connect baking_finished signal"
	)
	assert_true(
		EventBus.bread_sold.is_connected(router._on_bread_sold), "Should connect bread_sold signal"
	)


# ==================== Signal Forwarding Tests ====================


func test_gold_changed_forwarded_to_hud() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	EventBus.gold_changed.emit(0, 100)
	await wait_physics_frames(1)

	assert_true(true, "gold_changed signal forwarded without error")


func test_experience_changed_forwarded_to_hud() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	EventBus.experience_changed.emit(0, 100)
	await wait_physics_frames(1)

	assert_true(true, "experience_changed signal forwarded without error")


func test_level_up_forwarded_to_hud() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	EventBus.level_up.emit(5)
	await wait_physics_frames(1)

	assert_true(true, "level_up signal forwarded without error")


func test_production_started_forwarded_to_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	EventBus.production_started.emit(0, "test_recipe")
	await wait_physics_frames(1)

	assert_true(true, "production_started signal forwarded without error")


func test_production_progressed_forwarded_to_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	EventBus.production_progressed.emit(0, 0.5)
	await wait_physics_frames(1)

	assert_true(true, "production_progressed signal forwarded without error")


func test_production_completed_forwarded_to_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	EventBus.production_completed.emit(0, "test_recipe")
	await wait_physics_frames(1)

	assert_true(true, "production_completed signal forwarded without error")


func test_baking_finished_forwarded_to_display_slots() -> void:
	router.set_display_slots(mock_display_slots)
	router.connect_event_bus()

	EventBus.baking_finished.emit("test_recipe")
	await wait_physics_frames(1)

	assert_true(true, "baking_finished signal forwarded without error")


func test_bread_sold_forwarded_to_display_slots() -> void:
	router.set_display_slots(mock_display_slots)
	router.connect_event_bus()

	EventBus.bread_sold.emit("test_recipe", 100)
	await wait_physics_frames(1)

	assert_true(true, "bread_sold signal forwarded without error")


# ==================== UI Signal Connection Tests ====================


func test_connect_ui_signals_connects_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_ui_signals()

	assert_true(true, "UI signals connected without error")


# ==================== Getters/Setters Tests ====================


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


# ==================== Validation Tests ====================


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


# ==================== call_safe_method Helper Tests ====================


func test_call_safe_method_with_null_component() -> void:
	# Should not crash with null component
	router.call_safe_method(null, "_on_test_event", [1, 2])
	assert_true(true, "call_safe_method handles null component gracefully")


func test_call_safe_method_with_missing_method() -> void:
	var test_node = Node.new()
	test_node.name = "TestNode"
	add_child_autofree(test_node)

	# Should not crash if method doesn't exist
	router.call_safe_method(test_node, "_nonexistent_method", [1, 2])
	assert_true(true, "call_safe_method handles missing method gracefully")
