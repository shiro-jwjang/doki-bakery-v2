extends GutTest

## Test Suite for CustomerView
## Tests that CustomerView provides NPC visualization for customers
## SNA-120: Customer NPC 시각화
## SNA-138: Path2D 경로 이동 + 애니메이션

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


## Test that CustomerView has MovementPath node
func test_customer_view_has_movement_path() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var path = _customer_view.find_child("MovementPath", true, false)
	assert_not_null(path, "CustomerView should have MovementPath node")


## Test that MovementPath has PathFollow2D child
func test_movement_path_has_path_follow() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var path = _customer_view.find_child("MovementPath", true, false)
	if path == null:
		fail_test("MovementPath not found")
		return

	var path_follow = path.find_child("PathFollow2D", true, false)
	assert_not_null(path_follow, "MovementPath should have PathFollow2D child")


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


## ==================== PATH2D MOVEMENT TESTS ====================


## Test that CustomerView has PathFollow2D node
func test_customer_view_has_path_follow() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var path_follow = _customer_view.find_child("PathFollow2D", true, false)
	assert_not_null(path_follow, "CustomerView should have PathFollow2D node")


## Test that CustomerView has movement_speed property
func test_customer_view_has_movement_speed() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		"movement_speed" in _customer_view,
		"CustomerView should have movement_speed property"
	)


## Test that default movement speed is 50
func test_default_movement_speed_is_50() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_eq(_customer_view.movement_speed, 50.0, "Default movement speed should be 50")


## Test that movement speed can be set
func test_movement_speed_can_be_set() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var test_speed := 100.0
	_customer_view.set_movement_speed(test_speed)

	# Check if speed was stored (either as property or via getter)
	var actual_speed := 0.0
	if "movement_speed" in _customer_view:
		actual_speed = _customer_view.movement_speed
	elif _customer_view.has_method("get_movement_speed"):
		actual_speed = _customer_view.get_movement_speed()

	assert_eq(actual_speed, test_speed, "Movement speed should be set to %s" % test_speed)


## Test that CustomerView has start_movement method
func test_customer_view_has_start_movement_method() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		_customer_view.has_method("start_movement"),
		"CustomerView should have start_movement() method"
	)


## Test that CustomerView has set_movement_speed method
func test_customer_view_has_set_movement_speed_method() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		_customer_view.has_method("set_movement_speed"),
		"CustomerView should have set_movement_speed() method"
	)


## Test that start_movement begins path progress
func test_start_movement_begins_progress() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var path_follow: PathFollow2D = _customer_view.find_child("PathFollow2D", true, false)
	if path_follow == null:
		fail_test("PathFollow2D not found")
		return

	# Set up a simple path
	var path2d: Path2D = _customer_view.find_child("MovementPath", true, false)
	if path2d == null:
		fail_test("MovementPath not found")
		return

	# Create a simple 100px horizontal path
	var curve := Curve2D.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(100, 0))
	path2d.curve = curve

	# Start movement
	_customer_view.start_movement()
	assert_true(_customer_view.is_moving(), "CustomerView should be moving after start_movement()")


## Test that stop_movement stops path progress
func test_stop_movement_stops_progress() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	# Set up a simple path
	var path2d: Path2D = _customer_view.find_child("MovementPath", true, false)
	if path2d == null:
		fail_test("MovementPath not found")
		return

	var curve := Curve2D.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(100, 0))
	path2d.curve = curve

	# Start and then stop
	_customer_view.start_movement()
	_customer_view.stop_movement()
	assert_false(_customer_view.is_moving(), "CustomerView should not be moving after stop_movement()")


## ==================== ANIMATION TESTS ====================


## Test that CustomerView has play_animation method
func test_customer_view_has_play_animation_method() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		_customer_view.has_method("play_animation"),
		"CustomerView should have play_animation(name: String) method"
	)


## Test that CustomerView has get_current_animation method
func test_customer_view_has_get_current_animation_method() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	assert_true(
		_customer_view.has_method("get_current_animation") or \
		_customer_view.has_method("get_animation"),
		"CustomerView should have method to get current animation"
	)


## Test that idle animation can be played
func test_play_idle_animation() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	_customer_view.play_animation("idle")
	await wait_physics_frames(1)

	var current_anim := ""
	if _customer_view.has_method("get_current_animation"):
		current_anim = _customer_view.get_current_animation()
	elif _customer_view.has_method("get_animation"):
		current_anim = _customer_view.get_animation()

	assert_eq(current_anim, "idle", "Current animation should be 'idle'")


## Test that walk animation can be played
func test_play_walk_animation() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	_customer_view.play_animation("walk")
	await wait_physics_frames(1)

	var current_anim := ""
	if _customer_view.has_method("get_current_animation"):
		current_anim = _customer_view.get_current_animation()
	elif _customer_view.has_method("get_animation"):
		current_anim = _customer_view.get_animation()

	assert_eq(current_anim, "walk", "Current animation should be 'walk'")


## Test that buy animation can be played
func test_play_buy_animation() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	_customer_view.play_animation("buy")
	await wait_physics_frames(1)

	var current_anim := ""
	if _customer_view.has_method("get_current_animation"):
		current_anim = _customer_view.get_current_animation()
	elif _customer_view.has_method("get_animation"):
		current_anim = _customer_view.get_animation()

	assert_eq(current_anim, "buy", "Current animation should be 'buy'")


## Test that animation transitions from idle to walk
func test_animation_transition_idle_to_walk() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	# Start with idle
	_customer_view.play_animation("idle")
	await wait_physics_frames(1)

	var current_anim := ""
	if _customer_view.has_method("get_current_animation"):
		current_anim = _customer_view.get_current_animation()
	elif _customer_view.has_method("get_animation"):
		current_anim = _customer_view.get_animation()

	assert_eq(current_anim, "idle", "Should start with idle animation")

	# Transition to walk
	_customer_view.play_animation("walk")
	await wait_physics_frames(1)

	if _customer_view.has_method("get_current_animation"):
		current_anim = _customer_view.get_current_animation()
	elif _customer_view.has_method("get_animation"):
		current_anim = _customer_view.get_animation()

	assert_eq(current_anim, "walk", "Should transition to walk animation")


## ==================== SIGNAL TESTS ====================


## Test that CustomerView has path_completed signal
func test_customer_view_has_path_completed_signal() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	# Check for signal existence using signal_list
	var has_signal := false
	for signal_info in _customer_view.get_signal_list():
		if signal_info.name == "path_completed":
			has_signal = true
			break

	assert_true(has_signal, "CustomerView should have path_completed signal")


## Test that CustomerView has arrived_at_target signal
func test_customer_view_has_arrived_at_target_signal() -> void:
	if _customer_view == null:
		fail_test("CustomerView not loaded")
		return

	var has_signal := false
	for signal_info in _customer_view.get_signal_list():
		if signal_info.name == "arrived_at_target":
			has_signal = true
			break

	assert_true(has_signal, "CustomerView should have arrived_at_target signal")
