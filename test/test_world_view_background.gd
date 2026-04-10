extends GutTest

var _world_view_scene = preload("res://scenes/world/world_view.tscn")
var _world_view: Node2D = null


func before_each() -> void:
	_world_view = _world_view_scene.instantiate()
	add_child_autoqfree(_world_view)
	await wait_physics_frames(2)


## Test that Background CanvasLayer has layer -1 (behind everything)
func test_background_layer_is_minus_one() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	assert_true(background is CanvasLayer, "Background should be CanvasLayer")
	var canvas_layer := background as CanvasLayer
	assert_eq(canvas_layer.layer, -1, "Background CanvasLayer should have layer -1")


func test_back_floor_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var back_floor = background.find_child("BackFloor", true, false)
	assert_not_null(back_floor, "BackFloor Sprite2D should be child of Background")
	assert_true(back_floor is Sprite2D, "BackFloor should be Sprite2D")


func test_back_wall01_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var back_wall = background.find_child("BackWall01", true, false)
	assert_not_null(back_wall, "BackWall01 Sprite2D should be child of Background")
	assert_true(back_wall is Sprite2D, "BackWall01 should be Sprite2D")


func test_back_wall02_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var back_wall = background.find_child("BackWall02", true, false)
	assert_not_null(back_wall, "BackWall02 Sprite2D should be child of Background")
	assert_true(back_wall is Sprite2D, "BackWall02 should be Sprite2D")


func test_back_floor_has_texture() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var back_floor = background.find_child("BackFloor", true, false)
	if back_floor == null:
		fail_test("BackFloor not found")

	var sprite := back_floor as Sprite2D
	assert_not_null(sprite.texture, "BackFloor should have a texture assigned")


func test_entities_layer_is_above_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var entities = _world_view.find_child("Entities", true, false)
	var background = _world_view.find_child("Background", true, false)

	if entities == null:
		fail_test("Entities node not found")
	if background == null:
		fail_test("Background node not found")

	var entities_layer := (entities as CanvasLayer).layer
	var background_layer := (background as CanvasLayer).layer

	assert_gt(entities_layer, background_layer, "Entities layer should be above Background layer")


func test_oven_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var oven = background.find_child("Oven", true, false)
	assert_not_null(oven, "Oven Sprite2D should be child of Background")
	assert_true(oven is Sprite2D, "Oven should be Sprite2D")


func test_oven_has_texture() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var oven = background.find_child("Oven", true, false)
	if oven == null:
		fail_test("Oven not found")

	var sprite := oven as Sprite2D
	assert_not_null(sprite.texture, "Oven should have a texture assigned")


func test_table_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var table = background.find_child("Table", true, false)
	assert_not_null(table, "Table Sprite2D should be child of Background")
	assert_true(table is Sprite2D, "Table should be Sprite2D")


func test_table_has_texture() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var table = background.find_child("Table", true, false)
	if table == null:
		fail_test("Table not found")

	var sprite := table as Sprite2D
	assert_not_null(sprite.texture, "Table should have a texture assigned")


func test_window_exists_in_background() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var window = background.find_child("Window", true, false)
	assert_not_null(window, "Window Sprite2D should be child of Background")
	assert_true(window is Sprite2D, "Window should be Sprite2D")


func test_window_has_texture() -> void:
	if _world_view == null:
		fail_test("WorldView scene file does not exist")

	var background = _world_view.find_child("Background", true, false)
	if background == null:
		fail_test("Background node not found")

	var window = background.find_child("Window", true, false)
	if window == null:
		fail_test("Window not found")

	var sprite := window as Sprite2D
	assert_not_null(sprite.texture, "Window should have a texture assigned")
