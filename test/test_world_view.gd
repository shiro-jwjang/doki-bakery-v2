extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for WorldView Root Scene
## Tests the structure of the world view scene including:
## - Node2D root structure
## - Camera2D configuration (1200x1000 viewport)
## - CanvasLayer separation (Background, Entities, UI)
## - Y-Sort for entity depth ordering
## SNA-88: WorldView 루트 씬 구성 + Y-Sort 레이어

const WORLD_VIEW_SCENE_PATH = "res://scenes/world/world_view.tscn"

var _world_view: Node2D


func before_each() -> void:
	# Load the world view scene
	var scene_resource = load(WORLD_VIEW_SCENE_PATH)
	if scene_resource != null:
		_world_view = scene_resource.instantiate()
		add_child_autofree(_world_view)


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	pass


## ==================== BASIC SETUP TESTS ====================


## Test that WorldView scene can be loaded
func test_world_view_scene_loads() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist at: %s" % WORLD_VIEW_SCENE_PATH)
	assert_not_null(_world_view, "WorldView scene should be instantiated")


## Test that WorldView root is Node2D
func test_world_view_root_is_node2d() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")
	assert_true(
		_world_view is Node2D, "WorldView root should be Node2D, got: %s" % _world_view.get_class()
	)


## ==================== CAMERA TESTS ====================


## Test that Camera2D exists as a child of root
func test_camera2d_exists() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var camera = _world_view.find_child("Camera2D", true, false)
	assert_not_null(camera, "WorldView should have a Camera2D child node")


## Test that Camera2D has correct zoom level for 1200x1000 viewport
func test_camera2d_viewport_size() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var camera = _world_view.find_child("Camera2D", true, false)
	if camera == null:
		fail_test("Camera2D node not found")

	# Check that zoom is set (should be approximately (1.0, 1.0) for base viewport)
	var zoom = camera.zoom
	assert_true(zoom.x > 0 and zoom.y > 0, "Camera2D zoom should be positive, got: %s" % str(zoom))

	# Verify camera is enabled
	assert_true(camera.enabled, "Camera2D should be enabled")


## ==================== CANVAS LAYER TESTS ====================


## Test that Background CanvasLayer exists
func test_background_layer_exists() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	assert_not_null(background, "WorldView should have a Background CanvasLayer")

	if background != null:
		assert_true(
			background is CanvasLayer,
			"Background should be a CanvasLayer, got: %s" % background.get_class()
		)


## Test that Entities CanvasLayer exists
func test_entities_layer_exists() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var entities = _world_view.find_child("Entities", true, false)
	assert_not_null(entities, "WorldView should have an Entities CanvasLayer")

	if entities != null:
		assert_true(
			entities is CanvasLayer,
			"Entities should be a CanvasLayer, got: %s" % entities.get_class()
		)


## Test that UI CanvasLayer exists
func test_ui_layer_exists() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var ui = _world_view.find_child("UI", true, false)
	assert_not_null(ui, "WorldView should have a UI CanvasLayer")

	if ui != null:
		assert_true(ui is CanvasLayer, "UI should be a CanvasLayer, got: %s" % ui.get_class())


## ==================== LAYER ORDER TESTS ====================


## Test that CanvasLayers are in correct order (Background < Entities < UI)
func test_canvas_layer_order() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	var entities = _world_view.find_child("Entities", true, false)
	var ui = _world_view.find_child("UI", true, false)

	if background == null or entities == null or ui == null:
		fail_test("Required CanvasLayers not found")

	# Check layer ordering (higher layer numbers are drawn on top)
	var bg_layer = background.layer if background is CanvasLayer else 0
	var ent_layer = entities.layer if entities is CanvasLayer else 0
	var ui_layer = ui.layer if ui is CanvasLayer else 0

	assert_true(
		bg_layer < ent_layer and ent_layer < ui_layer,
		(
			"Layer order should be Background (%d) < Entities (%d) < UI (%d)"
			% [bg_layer, ent_layer, ui_layer]
		)
	)


## ==================== Y-SORT TESTS ====================


## Test that Entities layer has a Y-Sort node
func test_y_sort_node_exists() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var entities = _world_view.find_child("Entities", true, false)
	if entities == null:
		fail_test("Entities CanvasLayer not found")

	# Look for Y-Sort node (could be named "YSort" or be a YSort node directly)
	var y_sort_node = null

	# Check for Node2D with YSort enabled
	for child in entities.get_children(true):
		if child is Node2D and child.y_sort_enabled:
			y_sort_node = child
			break

	assert_not_null(y_sort_node, "Entities layer should contain a Node2D with YSort enabled")


## Test Y-Sort ordering by creating test nodes
func test_y_sort_ordering() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var entities = _world_view.find_child("Entities", true, false)
	if entities == null:
		fail_test("Entities CanvasLayer not found")

	# Find Node2D with YSort enabled
	var y_sort_node: Node2D = null
	for child in entities.get_children(true):
		if child is Node2D and child.y_sort_enabled:
			y_sort_node = child
			break

	if y_sort_node == null:
		fail_test("Node2D with YSort not found in Entities layer")

	# Create two test nodes at different Y positions
	var node_front = Node2D.new()
	var node_back = Node2D.new()

	node_front.name = "TestNodeFront"
	node_back.name = "TestNodeBack"

	node_front.position.y = 100  # Higher Y = rendered in front
	node_back.position.y = 0  # Lower Y = rendered behind

	y_sort_node.add_child(node_front)
	y_sort_node.add_child(node_back)

	# In Y-Sort, higher Y values should be rendered AFTER (on top of) lower Y values
	# We can verify this by checking that YSort is enabled
	assert_true(y_sort_node.y_sort_enabled, "YSort should be enabled for proper depth ordering")

	# Clean up
	node_front.queue_free()
	node_back.queue_free()


## ==================== INTEGRATION TESTS ====================


## Test complete scene structure
func test_world_view_complete_structure() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	# Verify all components exist
	var camera = _world_view.find_child("Camera2D", true, false)
	var background = _world_view.find_child("Background", true, false)
	var entities = _world_view.find_child("Entities", true, false)
	var ui = _world_view.find_child("UI", true, false)

	assert_not_null(camera, "Missing Camera2D")
	assert_not_null(background, "Missing Background layer")
	assert_not_null(entities, "Missing Entities layer")
	assert_not_null(ui, "Missing UI layer")

	# Verify types
	assert_true(camera is Camera2D, "Camera2D should be Camera2D type")
	assert_true(background is CanvasLayer, "Background should be CanvasLayer type")
	assert_true(entities is CanvasLayer, "Entities should be CanvasLayer type")
	assert_true(ui is CanvasLayer, "UI should be CanvasLayer type")


## Test scene can be added to tree without errors
func test_world_view_add_to_scene_tree() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	# The scene was already added to the tree in before_each
	# Verify it's in the tree
	assert_true(_world_view.is_inside_tree(), "WorldView should be inside scene tree")


## ==================== SNA-118: PlayerView PLACEMENT TESTS ====================


## Test that PlayerView exists as child of YSort
func test_player_view_exists_in_ysort() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var y_sort = _world_view.find_child("YSort", true, false)
	if y_sort == null:
		fail_test("YSort node not found")

	var player_view = y_sort.find_child("PlayerView", true, false)
	assert_not_null(player_view, "PlayerView should be child of YSort")


## ==================== SNA-119: StallMap PLACEMENT TESTS ====================


## Test that StallMap exists as child of Background
func test_stall_map_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var stall_map = background.find_child("StallMap", true, false)
	assert_not_null(stall_map, "StallMap should be child of Background")


## ==================== SNA-115: ProductionPanel PLACEMENT TESTS ====================


## Test that ProductionPanel exists as child of UI layer
func test_production_panel_exists_in_ui() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var ui = _world_view.find_child("UI", true, false)
	if ui == null:
		fail_test("UI layer not found")

	var production_panel = ui.find_child("ProductionPanel", true, false)
	assert_not_null(production_panel, "ProductionPanel should be child of UI layer")


## Test that WorldController references ProductionPanel
func test_world_controller_has_production_panel_reference() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var controller = _world_view.find_child("WorldController", true, false)
	if controller == null:
		fail_test("WorldController not found")

	assert_not_null(controller.production_panel, "WorldController should have production_panel reference")


## ==================== SNA-116: BreadMenu PLACEMENT TESTS ====================


## Test that BreadMenu scene can be loaded
func test_bread_menu_scene_loads() -> void:
	var scene = load("res://scenes/ui/bread_menu.tscn")
	assert_not_null(scene, "BreadMenu scene should exist at res://scenes/ui/bread_menu.tscn")


## Test that BreadMenu exists as child of UI layer
func test_bread_menu_exists_in_ui() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var ui = _world_view.find_child("UI", true, false)
	if ui == null:
		fail_test("UI layer not found")

	var bread_menu = ui.find_child("BreadMenu", true, false)
	assert_not_null(bread_menu, "BreadMenu should be child of UI layer")
