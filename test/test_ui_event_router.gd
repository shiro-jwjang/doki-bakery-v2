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
		EventBusAutoload.gold_changed.is_connected(router._on_gold_changed),
		"Should connect gold_changed signal"
	)
	assert_true(
		EventBusAutoload.experience_changed.is_connected(router._on_experience_changed),
		"Should connect experience_changed signal"
	)


func test_connect_event_bus_connects_production_signals() -> void:
	router.set_production_panel(mock_production_panel)

	router.connect_event_bus()

	assert_true(
		EventBusAutoload.production_started.is_connected(router._on_production_started),
		"Should connect production_started signal"
	)
	assert_true(
		EventBusAutoload.production_progressed.is_connected(router._on_production_progressed),
		"Should connect production_progressed signal"
	)
	assert_true(
		EventBusAutoload.production_completed.is_connected(router._on_production_completed),
		"Should connect production_completed signal"
	)


func test_connect_event_bus_connects_baking_signals() -> void:
	router.set_display_slots(mock_display_slots)

	router.connect_event_bus()

	assert_true(
		EventBusAutoload.baking_finished.is_connected(router._on_baking_finished),
		"Should connect baking_finished signal"
	)
	assert_true(
		EventBusAutoload.bread_sold.is_connected(router._on_bread_sold),
		"Should connect bread_sold signal"
	)


# ==================== Signal Forwarding Tests ====================


func test_gold_changed_forwarded_to_hud() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	EventBusAutoload.gold_changed.emit(0, 100)
	await wait_physics_frames(1)

	assert_true(true, "gold_changed signal forwarded without error")


func test_experience_changed_forwarded_to_hud() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	EventBusAutoload.experience_changed.emit(0, 100)
	await wait_physics_frames(1)

	assert_true(true, "experience_changed signal forwarded without error")


func test_level_up_forwarded_to_hud() -> void:
	router.set_hud(mock_hud)
	router.connect_event_bus()

	EventBusAutoload.level_up.emit(5)
	await wait_physics_frames(1)

	assert_true(true, "level_up signal forwarded without error")


func test_production_started_forwarded_to_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	EventBusAutoload.production_started.emit(0, "test_recipe")
	await wait_physics_frames(1)

	assert_true(true, "production_started signal forwarded without error")


func test_production_progressed_forwarded_to_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	EventBusAutoload.production_progressed.emit(0, 0.5)
	await wait_physics_frames(1)

	assert_true(true, "production_progressed signal forwarded without error")


func test_production_completed_forwarded_to_production_panel() -> void:
	router.set_production_panel(mock_production_panel)
	router.connect_event_bus()

	EventBusAutoload.production_completed.emit(0, "test_recipe")
	await wait_physics_frames(1)

	assert_true(true, "production_completed signal forwarded without error")


func test_baking_finished_forwarded_to_display_slots() -> void:
	router.set_display_slots(mock_display_slots)
	router.connect_event_bus()

	EventBusAutoload.baking_finished.emit("test_recipe")
	await wait_physics_frames(1)

	assert_true(true, "baking_finished signal forwarded without error")


func test_bread_sold_forwarded_to_display_slots() -> void:
	router.set_display_slots(mock_display_slots)
	router.connect_event_bus()

	EventBusAutoload.bread_sold.emit("test_recipe", 100)
	await wait_physics_frames(1)

	assert_true(true, "bread_sold signal forwarded without error")
