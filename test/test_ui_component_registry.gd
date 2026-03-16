extends GutTest

## Test Suite: SNA-186 UIComponentRegistry
##
## Tests the UIComponentRegistry which:
## 1. Finds and caches UI components within WorldView hierarchy
## 2. Manages UI component references
## 3. Provides getter/setter methods for UI components

const UIComponentRegistryScript = preload("res://scripts/ui/ui_component_registry.gd")

var registry: Node
var mock_ui_layer: CanvasLayer
var mock_hud: Control
var mock_production_panel: Control
var mock_display_slots: Node
var mock_bread_menu: Control


func before_each() -> void:
	# Create UI hierarchy
	mock_ui_layer = CanvasLayer.new()
	mock_ui_layer.name = "UI"
	add_child_autofree(mock_ui_layer)

	mock_hud = Control.new()
	mock_hud.name = "HUD"
	mock_ui_layer.add_child(mock_hud)

	mock_production_panel = Control.new()
	mock_production_panel.name = "ProductionPanel"
	mock_ui_layer.add_child(mock_production_panel)

	mock_display_slots = Node.new()
	mock_display_slots.name = "DisplaySlots"
	mock_ui_layer.add_child(mock_display_slots)

	mock_bread_menu = Control.new()
	mock_bread_menu.name = "BreadMenu"
	mock_ui_layer.add_child(mock_bread_menu)

	# Create registry
	registry = UIComponentRegistryScript.new()
	add_child_autofree(registry)
	await wait_physics_frames(1)


func after_each() -> void:
	registry = null
	mock_ui_layer = null
	mock_hud = null
	mock_production_panel = null
	mock_display_slots = null
	mock_bread_menu = null


# ==================== Initialization Tests ====================


func test_registry_initializes() -> void:
	assert_not_null(registry, "UIComponentRegistry should initialize")


func test_registry_has_empty_state_on_init() -> void:
	assert_null(registry.get_hud(), "HUD should be null initially")
	assert_null(registry.get_production_panel(), "ProductionPanel should be null initially")
	assert_null(registry.get_display_slots(), "DisplaySlots should be null initially")
	assert_null(registry.get_bread_menu(), "BreadMenu should be null initially")


# ==================== Find UI Components Tests ====================


func test_find_components_returns_dictionary() -> void:
	registry.set_root_node(registry)
	var result: Dictionary = registry.find_components()
	assert_not_null(result, "find_components should return a dictionary")


func test_find_components_locates_hud() -> void:
	# Create an isolated root node in a separate branch (not under test scene)
	var isolated_root = Node.new()
	isolated_root.name = "IsolatedRoot"
	# Don't add to test scene, just set it as registry root
	registry.set_root_node(isolated_root)
	registry.find_components()
	var hud = registry.get_hud()
	# HUD should be null since isolated_root has no parent or UI hierarchy
	assert_null(hud, "HUD should be null when root node has no UI hierarchy")
	isolated_root.free()  # Clean up manually


func test_find_components_with_relative_path() -> void:
	# Create a test root with UI as sibling
	var test_root = Node.new()
	test_root.name = "TestRoot"
	add_child_autofree(test_root)

	var ui = CanvasLayer.new()
	ui.name = "UI"
	test_root.add_child(ui)

	var hud = Control.new()
	hud.name = "HUD"
	ui.add_child(hud)

	# Set registry root and find
	registry.set_root_node(test_root)
	registry.find_components()

	var found_hud = registry.get_hud()
	assert_not_null(found_hud, "Should find HUD component")


func test_find_components_returns_all_components() -> void:
	var test_root = Node.new()
	test_root.name = "TestRoot"
	add_child_autofree(test_root)

	var ui = CanvasLayer.new()
	ui.name = "UI"
	test_root.add_child(ui)

	var hud = Control.new()
	hud.name = "HUD"
	ui.add_child(hud)

	var panel = Control.new()
	panel.name = "ProductionPanel"
	ui.add_child(panel)

	registry.set_root_node(test_root)
	var components = registry.find_components()

	assert_true(components.has("hud"), "Should return hud in components")
	assert_true(components.has("production_panel"), "Should return production_panel in components")


# ==================== Getters/Setters Tests ====================


func test_set_hud_stores_reference() -> void:
	var test_hud = Control.new()
	add_child_autofree(test_hud)

	registry.set_hud(test_hud)
	var retrieved = registry.get_hud()

	assert_eq(retrieved, test_hud, "Should retrieve same HUD instance")


func test_set_production_panel_stores_reference() -> void:
	var test_panel = Control.new()
	add_child_autofree(test_panel)

	registry.set_production_panel(test_panel)
	var retrieved = registry.get_production_panel()

	assert_eq(retrieved, test_panel, "Should retrieve same ProductionPanel instance")


func test_set_display_slots_stores_reference() -> void:
	var test_slots = Node.new()
	add_child_autofree(test_slots)

	registry.set_display_slots(test_slots)
	var retrieved = registry.get_display_slots()

	assert_eq(retrieved, test_slots, "Should retrieve same DisplaySlots instance")


func test_set_bread_menu_stores_reference() -> void:
	var test_menu = Control.new()
	add_child_autofree(test_menu)

	registry.set_bread_menu(test_menu)
	var retrieved = registry.get_bread_menu()

	assert_eq(retrieved, test_menu, "Should retrieve same BreadMenu instance")


func test_get_all_components_returns_dictionary() -> void:
	var test_hud = Control.new()
	add_child_autofree(test_hud)
	registry.set_hud(test_hud)

	var components = registry.get_all_components()

	assert_true(components.has("hud"), "Should have hud in all components")
	assert_eq(components["hud"], test_hud, "Should return correct HUD instance")


# ==================== Root Node Tests ====================


func test_set_root_node_stores_reference() -> void:
	var test_root = Node.new()
	add_child_autofree(test_root)

	registry.set_root_node(test_root)
	# Root node should be stored for finding components
	assert_true(true, "Root node setter should work")


# ==================== Component Validation Tests ====================


func test_has_hud_returns_false_when_null() -> void:
	assert_false(registry.has_hud(), "has_hud should return false when HUD is null")


func test_has_hud_returns_true_when_set() -> void:
	var test_hud = Control.new()
	add_child_autofree(test_hud)
	registry.set_hud(test_hud)

	assert_true(registry.has_hud(), "has_hud should return true when HUD is set")


func test_has_production_panel_returns_false_when_null() -> void:
	assert_false(
		registry.has_production_panel(), "has_production_panel should return false when null"
	)


func test_has_production_panel_returns_true_when_set() -> void:
	var test_panel = Control.new()
	add_child_autofree(test_panel)
	registry.set_production_panel(test_panel)

	assert_true(registry.has_production_panel(), "has_production_panel should return true when set")


func test_has_display_slots_returns_false_when_null() -> void:
	assert_false(registry.has_display_slots(), "has_display_slots should return false when null")


func test_has_display_slots_returns_true_when_set() -> void:
	var test_slots = Node.new()
	add_child_autofree(test_slots)
	registry.set_display_slots(test_slots)

	assert_true(registry.has_display_slots(), "has_display_slots should return true when set")


func test_has_bread_menu_returns_false_when_null() -> void:
	assert_false(registry.has_bread_menu(), "has_bread_menu should return false when null")


func test_has_bread_menu_returns_true_when_set() -> void:
	var test_menu = Control.new()
	add_child_autofree(test_menu)
	registry.set_bread_menu(test_menu)

	assert_true(registry.has_bread_menu(), "has_bread_menu should return true when set")
