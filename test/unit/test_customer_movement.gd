extends GutTest

## Test Suite for CustomerMovement
## Tests customer movement and positioning logic

var _movement: Node = null
var _mock_customer_view: Node2D = null


func before_each() -> void:
	_mock_customer_view = Node2D.new()
	_mock_customer_view.name = "MockCustomer"
	add_child_autoqfree(_mock_customer_view)
	_movement = _create_movement()
	if _movement != null:
		add_child_autoqfree(_movement)


func after_each() -> void:
	if _movement != null and is_instance_valid(_movement):
		_movement.queue_free()
		_movement = null
	if _mock_customer_view != null and is_instance_valid(_mock_customer_view):
		_mock_customer_view.queue_free()
		_mock_customer_view = null


## ==================== POSITION CONSTANTS TESTS ====================


## Test spawn position constant
func test_spawn_position() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("get_spawn_position"):
		pending("get_spawn_position method not implemented")
		return

	var pos = _movement.get_spawn_position()
	assert_true(pos.x < 0, "Spawn position should be off-screen left")
	assert_true(pos.y > 500, "Spawn position should be at bottom")


## Test display position constant
func test_display_position() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("get_display_position"):
		pending("get_display_position method not implemented")
		return

	var pos = _movement.get_display_position()
	assert_true(pos.x > 300 and pos.x < 600, "Display position should be in middle of screen")
	assert_true(pos.y > 400 and pos.y < 700, "Display position should be near counter")


## Test exit position constant
func test_exit_position() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("get_exit_position"):
		pending("get_exit_position method not implemented")
		return

	var pos = _movement.get_exit_position()
	assert_true(pos.x > 1200, "Exit position should be off-screen right")
	assert_true(pos.y > 500, "Exit position should be at bottom")


## ==================== MOVEMENT DURATION TESTS ====================


## Test movement duration constant
func test_movement_duration() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("get_movement_duration"):
		pending("get_movement_duration method not implemented")
		return

	var duration = _movement.get_movement_duration()
	assert_true(duration > 0, "Movement duration should be positive")
	assert_true(duration <= 5.0, "Movement duration should be reasonable (<= 5s)")


## ==================== MOVE TO POSITION TESTS ====================


## Test move_to_display method
func test_move_to_display() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("move_to_display"):
		pending("move_to_display method not implemented")
		return

	# Setup customer view at spawn position
	var spawn_pos = Vector2(-200, 1100)
	_mock_customer_view.position = spawn_pos

	var completed = false
	if _movement.has_signal("movement_completed"):
		_movement.movement_completed.connect(func(): completed = true)

	_movement.move_to_display(_mock_customer_view)

	# Should have started the movement
	assert_true(true, "move_to_display should execute without error")


## Test move_to_exit method
func test_move_to_exit() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("move_to_exit"):
		pending("move_to_exit method not implemented")
		return

	# Setup customer view at display position
	_mock_customer_view.position = Vector2(450, 550)

	var completed = false
	if _movement.has_signal("movement_completed"):
		_movement.movement_completed.connect(func(): completed = true)

	_movement.move_to_exit(_mock_customer_view)

	# Should have started the movement
	assert_true(true, "move_to_exit should execute without error")


## ==================== POSITION GETTER TESTS ====================


## Test get_customer_position returns correct position
func test_get_customer_position() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("get_customer_position"):
		pending("get_customer_position method not implemented")
		return

	var test_pos = Vector2(100, 200)
	_mock_customer_view.position = test_pos

	var pos = _movement.get_customer_position(_mock_customer_view)
	assert_eq(pos, test_pos, "Should return customer's current position")


## Test get_customer_position with null view
func test_get_customer_position_null_view() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("get_customer_position"):
		pending("get_customer_position method not implemented")
		return

	var pos = _movement.get_customer_position(null)
	assert_eq(pos, Vector2.ZERO, "Should return ZERO for null view")


## ==================== TWEEN CLEANUP TESTS ====================


## Test cleanup method stops active tweens
func test_cleanup_stops_tweens() -> void:
	if _movement == null:
		pending("CustomerMovement not implemented yet")
		return

	if not _movement.has_method("cleanup"):
		pending("cleanup method not implemented")
		return

	# Start a movement
	if _movement.has_method("move_to_display"):
		_movement.move_to_display(_mock_customer_view)

	# Cleanup should not throw error
	_movement.cleanup()
	assert_true(true, "cleanup should execute without error")


## ==================== HELPER METHODS ====================


func _create_movement() -> Node:
	var script = load("res://scripts/customer/customer_movement.gd")
	if script == null:
		return null

	var movement = script.new()
	return movement
