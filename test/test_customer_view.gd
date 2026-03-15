extends GutTest

## Test Suite for CustomerView
## Tests that CustomerView provides NPC visualization for customers
## SNA-120: Customer NPC 시각화

const CUSTOMER_VIEW_SCENE := "res://scenes/world/customer_view.tscn"

var _customer_view: Node2D = null


func before_each() -> void:
	var scene = load(CUSTOMER_VIEW_SCENE)
	if scene == null:
		fail_test("CustomerView scene not found at %s" % CUSTOMER_VIEW_SCENE)
		return
	_customer_view = scene.instantiate()
	add_child_autoqfree(_customer_view)
	await wait_physics_frames(2)


## ==================== SCENE LOADING TESTS ====================


## Test that CustomerView scene can be loaded
func test_customer_view_scene_loads() -> void:
	var scene = load(CUSTOMER_VIEW_SCENE)
	assert_not_null(scene, "CustomerView scene should exist at %s" % CUSTOMER_VIEW_SCENE)


## Test that CustomerView scene can be instantiated
func test_customer_view_instantiates() -> void:
	assert_not_null(_customer_view, "CustomerView should instantiate without errors")


## ==================== STRUCTURE TESTS ====================


## Test that CustomerView has Sprite2D node
func test_customer_view_has_sprite() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var sprite = _customer_view.find_child("Sprite2D", true, false)
	assert_not_null(sprite, "CustomerView should have Sprite2D node")


## Test that CustomerView has customer_id property
func test_customer_view_has_customer_id() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		"customer_id" in _customer_view or _customer_view.has_method("get_customer_id"),
		"CustomerView should have customer_id property or getter"
	)


## Test that CustomerView has setup method
func test_customer_view_has_setup_method() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		_customer_view.has_method("setup"),
		"CustomerView should have setup(customer_id: String) method"
	)


## ==================== WORLDVIEW PLACEMENT TESTS ====================


## Test that CustomerView can be placed in YSort
func test_customer_view_in_ysort() -> void:
	# Skip in headless mode where scene instantiation with textures fails
	if DisplayServer.get_name() == "headless":
		return

	var world_view_scene = load("res://scenes/world/world_view.tscn")
	if world_view_scene == null:
		fail_test("WorldView scene not found")
		return

	var world_view = world_view_scene.instantiate()
	add_child_autoqfree(world_view)
	await wait_physics_frames(2)

	# Find YSort node
	var entities = world_view.find_child("Entities", true, false)
	if entities == null:
		fail_test("Entities layer not found")
		return

	var y_sort = entities.find_child("YSort", true, false)
	if y_sort == null:
		fail_test("YSort node not found")
		return

	# Instantiate CustomerView and add to YSort
	var customer = load(CUSTOMER_VIEW_SCENE).instantiate()
	y_sort.add_child(customer)
	await wait_physics_frames(1)

	assert_true(customer.is_inside_tree(), "CustomerView should be added to YSort")
	assert_eq(customer.get_parent(), y_sort, "CustomerView parent should be YSort")


## ==================== FUNCTIONAL TESTS ====================


## Test that setup sets customer_id correctly
func test_setup_sets_customer_id() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var test_id := "customer_test_123"
	_customer_view.setup(test_id)

	var actual_id := ""
	if "customer_id" in _customer_view:
		actual_id = _customer_view.customer_id
	elif _customer_view.has_method("get_customer_id"):
		actual_id = _customer_view.get_customer_id()

	assert_eq(actual_id, test_id, "setup() should set customer_id")
