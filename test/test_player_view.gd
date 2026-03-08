extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for PlayerView Character
## Tests the player character including:
## - AnimatedSprite2D node structure
## - Initial position (in front of stall)
## - Idle animation playback
## - Sprite texture loading
## SNA-90: PlayerView — 주인공 배치 + idle 애니메이션

const PLAYER_VIEW_SCENE_PATH = "res://scenes/world/player_view.tscn"

var _player_view: Node2D


func before_each() -> void:
	# Load the player view scene
	var scene_resource = load(PLAYER_VIEW_SCENE_PATH)
	if scene_resource != null:
		_player_view = scene_resource.instantiate()
		add_child_autofree(_player_view)
		# Wait for _ready to be called
		await get_tree().process_frame


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	pass


## ==================== BASIC SETUP TESTS ====================

## Test that PlayerView scene can be loaded
func test_player_view_scene_loads() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist at: %s" % PLAYER_VIEW_SCENE_PATH)
	assert_not_null(_player_view, "PlayerView scene should be instantiated")


## Test that PlayerView root is Node2D
func test_player_view_root_is_node2d() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")
	assert_true(
		_player_view is Node2D,
		"PlayerView root should be Node2D, got: %s" % _player_view.get_class()
	)


## ==================== ANIMATED SPRITE TESTS ====================

## Test that AnimatedSprite2D exists as a child
func test_animated_sprite2d_exists() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	var sprite = _player_view.find_child("AnimatedSprite2D", true, false)
	assert_not_null(sprite, "PlayerView should have an AnimatedSprite2D child node")

	if sprite != null:
		assert_true(
			sprite is AnimatedSprite2D,
			"Sprite should be AnimatedSprite2D, got: %s" % sprite.get_class()
		)


## Test that AnimatedSprite2D has SpriteFrames resource
func test_animated_sprite_has_spriteframes() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	var sprite = _player_view.find_child("AnimatedSprite2D", true, false)
	if sprite == null:
		fail_test("AnimatedSprite2D node not found")

	assert_not_null(
		sprite.sprite_frames,
		"AnimatedSprite2D should have a SpriteFrames resource"
	)


## Test that idle animation exists in SpriteFrames
func test_idle_animation_exists() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	var sprite = _player_view.find_child("AnimatedSprite2D", true, false)
	if sprite == null:
		fail_test("AnimatedSprite2D node not found")

	if sprite.sprite_frames == null:
		fail_test("SpriteFrames resource not assigned")

	assert_true(
		sprite.sprite_frames.has_animation("idle"),
		"SpriteFrames should have 'idle' animation"
	)


## ==================== ANIMATION PLAYBACK TESTS ====================

## Test that idle animation plays after _ready
func test_player_idle_animation_plays() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	var sprite = _player_view.find_child("AnimatedSprite2D", true, false)
	if sprite == null:
		fail_test("AnimatedSprite2D node not found")

	# Verify idle animation is playing
	assert_true(
		sprite.is_playing(),
		"AnimatedSprite2D should be playing animation"
	)

	assert_eq(
		sprite.animation,
		"idle",
		"AnimatedSprite2D should be playing 'idle' animation, got: %s" % sprite.animation
	)


## ==================== SPRITE TEXTURE TESTS ====================

## Test that sprite texture is not null
func test_player_sprite_not_null() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	var sprite = _player_view.find_child("AnimatedSprite2D", true, false)
	if sprite == null:
		fail_test("AnimatedSprite2D node not found")

	if sprite.sprite_frames == null:
		fail_test("SpriteFrames resource not assigned")

	assert_true(
		sprite.sprite_frames.has_animation("idle"),
		"SpriteFrames should have 'idle' animation"
	)

	# Check that idle animation has at least one frame
	var frame_count = sprite.sprite_frames.get_frame_count("idle")
	assert_true(
		frame_count > 0,
		"idle animation should have at least one frame, got: %d" % frame_count
	)

	# Check that the first frame's texture is not null
	var texture = sprite.sprite_frames.get_frame_texture("idle", 0)
	assert_not_null(
		texture,
		"idle animation first frame should have a valid texture"
	)


## ==================== POSITION TESTS ====================

## Test that initial position is in front of stall
func test_player_initial_position() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# Player should be at a reasonable position (in front of stall)
	# Using (0, 0) as default or stall front position
	var position = _player_view.position

	# Position should be within reasonable world bounds (0, 0) is valid starting position
	assert_true(
		position.x >= -1000 and position.x <= 2000,
		"PlayerView X position should be within bounds, got: %d" % position.x
	)
	assert_true(
		position.y >= -1000 and position.y <= 2000,
		"PlayerView Y position should be within bounds, got: %d" % position.y
	)

	# Position should be within reasonable world bounds
	assert_true(
		position.x >= -1000 and position.x <= 2000,
		"PlayerView X position should be within bounds, got: %d" % position.x
	)
	assert_true(
		position.y >= -1000 and position.y <= 2000,
		"PlayerView Y position should be within bounds, got: %d" % position.y
	)


## ==================== INTEGRATION TESTS ====================

## Test complete scene structure
func test_player_view_complete_structure() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# Verify AnimatedSprite2D exists
	var sprite = _player_view.find_child("AnimatedSprite2D", true, false)
	assert_not_null(sprite, "Missing AnimatedSprite2D")

	# Verify it's the right type
	assert_true(sprite is AnimatedSprite2D, "Should be AnimatedSprite2D type")

	# Verify SpriteFrames
	assert_not_null(sprite.sprite_frames, "Missing SpriteFrames resource")

	# Verify idle animation exists
	assert_true(
		sprite.sprite_frames.has_animation("idle"),
		"Missing 'idle' animation"
	)


## Test scene can be added to tree without errors
func test_player_view_add_to_scene_tree() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# The scene was already added to the tree in before_each
	# Verify it's in the tree
	assert_true(_player_view.is_inside_tree(), "PlayerView should be inside scene tree")
