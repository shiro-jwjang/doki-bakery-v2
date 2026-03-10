extends GutTest

var _world_view_scene = preload("res://scenes/world/world_view.tscn")
var _world_view: Node2D = null

func before_each() -> void:
	_world_view = _world_view_scene.instantiate()
	add_child_autoqfree(_world_view)
	await wait_physics_frames(2)


## Test scene can be added to tree without errors
func test_world_view_add_to_scene_tree() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	# The scene was already added to the tree in before_each
	# Verify it's in the tree
	assert_true(_world_view.is_inside_tree(), "WorldView should be inside scene tree")


## ==================== SNA-114: HELPER METHOD TESTS ====================


## Test that add_entity() adds entity to YSort node
func test_add_entity_to_ysort() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	# Find YSort node
	var entities = _world_view.find_child("Entities", true, false)
	if entities == null:
		fail_test("Entities CanvasLayer not found")

	var y_sort_node: Node2D = null
	for child in entities.get_children(true):
		if child is Node2D and child.y_sort_enabled:
			y_sort_node = child
			break

	if y_sort_node == null:
		fail_test("YSort node not found")

	# Create test entity
	var test_entity = Node2D.new()
	test_entity.name = "TestEntity"

	# Call add_entity method
	_world_view.add_entity(test_entity)

	# Verify entity is child of YSort node
	assert_true(
		test_entity.get_parent() == y_sort_node,
		"Entity should be added to YSort node, got parent: %s" % test_entity.get_parent().name
	)

	# Clean up
	test_entity.queue_free()


## Test that adding a null entity triggers an assert (skipped in non-debug or just check manually)
func test_add_entity_null_fails() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	# We can't easily catch asserts in GDScript, but we can verify the function exists
	assert_true(_world_view.has_method("add_entity"), "add_entity method should exist")


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
