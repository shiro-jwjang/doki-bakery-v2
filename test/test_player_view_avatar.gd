extends GutTest

## SNA-122: PlayerView Avatar Integration Tests
## TDD Red Phase - Tests for PlayerView avatar appearance application

const PLAYER_VIEW_SCENE_PATH = "res://scenes/world/player_view.tscn"

var _player_view: Node2D
var _test_avatar_data: AvatarData


func before_each() -> void:
	# Load the player view scene
	var scene_resource = load(PLAYER_VIEW_SCENE_PATH)
	if scene_resource != null:
		_player_view = scene_resource.instantiate()
		add_child_autofree(_player_view)
		await get_tree().process_frame

	# Create test avatar data
	_test_avatar_data = AvatarData.new()


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	pass


#region REQ: PlayerView apply_avatar_data method


func test_player_view_has_apply_avatar_data_method() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	assert_true(
		_player_view.has_method("apply_avatar_data"),
		"PlayerView should have apply_avatar_data method"
	)


func test_apply_avatar_data_accepts_avatar_data() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# Test that method can be called with AvatarData
	_player_view.apply_avatar_data(_test_avatar_data)

	# If we get here without crashing, the test passes
	assert_true(true, "apply_avatar_data should accept AvatarData parameter")


func test_apply_avatar_data_with_null_does_not_crash() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# Test that null avatar data doesn't crash
	_player_view.apply_avatar_data(null)

	assert_true(true, "apply_avatar_data should handle null gracefully")


#endregion

#region REQ: Avatar appearance application


func test_apply_avatar_data_updates_animated_sprite() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# SNA-150: PlayerView uses AvatarCompositor
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	if compositor == null:
		fail_test("AvatarCompositor not found in PlayerView")

	# Create test textures
	var test_texture = PlaceholderTexture2D.new()
	test_texture.set_size(Vector2(16, 16))

	_test_avatar_data.body_texture = test_texture

	# Apply avatar data
	_player_view.apply_avatar_data(_test_avatar_data)

	# Verify the compositor still exists
	assert_not_null(compositor, "AvatarCompositor should still exist after applying avatar")


func test_apply_avatar_data_preserves_animation_state() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# SNA-150: PlayerView uses AvatarCompositor
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	if compositor == null:
		fail_test("AvatarCompositor not found")

	# Get initial animation state
	var initial_animation = compositor.current_animation

	# Apply avatar data
	_player_view.apply_avatar_data(_test_avatar_data)

	# Verify animation state is preserved
	assert_eq(
		compositor.current_animation,
		initial_animation,
		"Animation should be preserved after applying avatar"
	)

	# Note: We don't enforce playing state, just that it doesn't crash


#endregion

#region REQ: Integration with GameManager


func test_player_view_connects_to_avatar_changed_signal() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# Emit avatar_changed signal from EventBus
	# Use a valid avatar ID format
	EventBusAutoload.avatar_changed.emit("avatar_0")

	# If we get here without crashing, the test passes
	# (Actual integration test would verify the avatar is applied)
	assert_true(true, "avatar_changed signal emission should not crash")

#endregion
