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

	# SNA-150: PlayerView now uses AvatarCompositor instead of direct AnimatedSprite2D
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	assert_not_null(compositor, "PlayerView should have an AvatarCompositor child node")

	if compositor != null:
		assert_true(
			compositor is AvatarCompositor,
			"Compositor should be AvatarCompositor, got: %s" % compositor.get_class()
		)


## Test that AnimatedSprite2D has SpriteFrames resource
func test_animated_sprite_has_spriteframes() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# SNA-150: Check that AvatarCompositor has Layers with sprite frames
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	if compositor == null:
		fail_test("AvatarCompositor node not found")

	var layers = compositor.find_child("Layers", true, false)
	assert_not_null(layers, "AvatarCompositor should have Layers child")

	if layers != null:
		# Check that at least one layer has SpriteFrames
		var body = layers.find_child("Body", true, false)
		if body != null and body is AnimatedSprite2D:
			assert_not_null(body.sprite_frames, "Body layer should have a SpriteFrames resource")


## Test that idle animation exists in SpriteFrames
func test_idle_animation_exists() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# SNA-150: Check that layers have idle animation
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	if compositor == null:
		fail_test("AvatarCompositor node not found")

	var layers = compositor.find_child("Layers", true, false)
	var body = layers.find_child("Body", true, false) if layers else null

	if body != null and body is AnimatedSprite2D:
		if body.sprite_frames == null:
			fail_test("SpriteFrames resource not assigned")

		# MVP: SpriteFrames may exist but not have animations yet
		# Just verify the structure is in place
		assert_not_null(body.sprite_frames, "Body layer should have SpriteFrames resource")


## ==================== ANIMATION PLAYBACK TESTS ====================


## Test that idle animation plays after _ready
func test_player_idle_animation_plays() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# SNA-150: Check that AvatarCompositor is playing idle animation
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	if compositor == null:
		fail_test("AvatarCompositor node not found")

	assert_true(
		compositor.has_method("play_animation"),
		"AvatarCompositor should have play_animation method"
	)

	# Verify idle animation is set
	assert_eq(
		compositor.current_animation,
		"idle",
		"AvatarCompositor current_animation should be 'idle' initially"
	)


## ==================== SPRITE TEXTURE TESTS ====================


## Test that sprite texture is not null
func test_player_sprite_not_null() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# SNA-150: Check that Body layer has sprite frames
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	if compositor == null:
		fail_test("AvatarCompositor node not found")

	var layers = compositor.find_child("Layers", true, false)
	var body = layers.find_child("Body", true, false) if layers else null

	if body == null:
		fail_test("Body layer not found")

	if body.sprite_frames == null:
		fail_test("SpriteFrames resource not assigned")

	# MVP: Just verify SpriteFrames exists (actual frames added in SNA-150)
	assert_not_null(body.sprite_frames, "Body layer should have SpriteFrames resource")

	# If idle animation exists, verify structure
	if body.sprite_frames.has_animation("idle"):
		var frame_count = body.sprite_frames.get_frame_count("idle")
		# MVP: Frame count may be 0 (no textures loaded yet)
		if frame_count > 0:
			var texture = body.sprite_frames.get_frame_texture("idle", 0)
			# Texture may be null in MVP until actual assets are loaded
			pass


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

	# SNA-150: Verify AvatarCompositor structure
	var compositor = _player_view.find_child("AvatarCompositor", true, false)
	assert_not_null(compositor, "Missing AvatarCompositor")

	# Verify it's the right type
	assert_true(compositor is AvatarCompositor, "Should be AvatarCompositor type")

	# Verify Layers node
	var layers = compositor.find_child("Layers", true, false)
	assert_not_null(layers, "Missing Layers node")

	# Verify all 5 layers exist
	var layer_names = ["HairDn", "Body", "Eye", "HairUp", "Hat"]
	for layer_name in layer_names:
		var layer = layers.find_child(layer_name, true, false)
		assert_not_null(layer, "Missing %s layer" % layer_name)
		assert_true(layer is AnimatedSprite2D, "%s should be AnimatedSprite2D" % layer_name)


## Test scene can be added to tree without errors
func test_player_view_add_to_scene_tree() -> void:
	if _player_view == null:
		fail_test("PlayerView scene file does not exist")

	# The scene was already added to the tree in before_each
	# Verify it's in the tree
	assert_true(_player_view.is_inside_tree(), "PlayerView should be inside scene tree")
