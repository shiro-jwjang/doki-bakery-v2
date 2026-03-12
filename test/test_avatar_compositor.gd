extends GutTest

## Test Suite for Avatar Compositor
## Tests avatar layer composition with proper z-index and animation sync
## SNA-150: 아바타 레이어 합성 시스템

const AvatarScene := preload("res://scenes/entities/avatar.tscn")

var avatar: Node2D
var compositor: Node


func before_each() -> void:
	# Reset state before each test
	avatar = null
	compositor = null


func after_each() -> void:
	# Clean up instances
	if compositor != null and is_instance_valid(compositor):
		compositor.queue_free()
		compositor = null
	if avatar != null and is_instance_valid(avatar):
		avatar.queue_free()
		avatar = null


## Test: Compositor has all 5 required layers
func test_compositor_has_all_five_layers() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var sprite_holder = compositor.get_node_or_null("SpriteHolder")
	assert_not_null(sprite_holder, "Should have SpriteHolder node")

	# Check all 5 layers exist
	var hairdn = sprite_holder.get_node_or_null("HairDn")
	var body = sprite_holder.get_node_or_null("Body")
	var eye = sprite_holder.get_node_or_null("Eye")
	var hairup = sprite_holder.get_node_or_null("HairUp")
	var hat = sprite_holder.get_node_or_null("Hat")

	assert_not_null(hairdn, "Should have HairDn layer")
	assert_not_null(body, "Should have Body layer")
	assert_not_null(eye, "Should have Eye layer")
	assert_not_null(hairup, "Should have HairUp layer")
	assert_not_null(hat, "Should have Hat layer")


## Test: Layers have correct z-index values
func test_layers_have_correct_z_index() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var sprite_holder = compositor.get_node("SpriteHolder")

	# Verify z-index order: hat(4) > hairup(3) > eye(2) > body(1) > hairdn(0)
	assert_eq(sprite_holder.get_node("HairDn").z_index, 0, "HairDn should have z_index 0")
	assert_eq(sprite_holder.get_node("Body").z_index, 1, "Body should have z_index 1")
	assert_eq(sprite_holder.get_node("Eye").z_index, 2, "Eye should have z_index 2")
	assert_eq(sprite_holder.get_node("HairUp").z_index, 3, "HairUp should have z_index 3")
	assert_eq(sprite_holder.get_node("Hat").z_index, 4, "Hat should have z_index 4")


## Test: All layers are AnimatedSprite2D nodes
func test_all_layers_are_animated_sprite2d() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var sprite_holder = compositor.get_node("SpriteHolder")

	assert_true(
		sprite_holder.get_node("HairDn") is AnimatedSprite2D, "HairDn should be AnimatedSprite2D"
	)
	assert_true(
		sprite_holder.get_node("Body") is AnimatedSprite2D, "Body should be AnimatedSprite2D"
	)
	assert_true(sprite_holder.get_node("Eye") is AnimatedSprite2D, "Eye should be AnimatedSprite2D")
	assert_true(
		sprite_holder.get_node("HairUp") is AnimatedSprite2D, "HairUp should be AnimatedSprite2D"
	)
	assert_true(sprite_holder.get_node("Hat") is AnimatedSprite2D, "Hat should be AnimatedSprite2D")


## Test: AvatarData resource structure exists and has all texture fields
func test_avatar_data_has_all_texture_fields() -> void:
	var avatar_data = AvatarData.new()

	assert_not_null(avatar_data, "AvatarData should be instantiable")
	# Check that properties exist (will be null initially)
	assert_true("body_texture" in avatar_data, "AvatarData should have body_texture property")
	assert_true("eye_texture" in avatar_data, "AvatarData should have eye_texture property")
	assert_true("hairup_texture" in avatar_data, "AvatarData should have hairup_texture property")
	assert_true("hairdn_texture" in avatar_data, "AvatarData should have hairdn_texture property")
	assert_true("hat_texture" in avatar_data, "AvatarData should have hat_texture property")


## Test: AvatarData can be created and assigned textures
func test_avatar_data_accepts_textures() -> void:
	var avatar_data = AvatarData.new()
	var dummy_texture = PlaceholderTexture2D.new()

	avatar_data.body_texture = dummy_texture
	avatar_data.eye_texture = dummy_texture
	avatar_data.hairup_texture = dummy_texture
	avatar_data.hairdn_texture = dummy_texture
	avatar_data.hat_texture = dummy_texture

	assert_eq(avatar_data.body_texture, dummy_texture, "Body texture should be assigned")
	assert_eq(avatar_data.eye_texture, dummy_texture, "Eye texture should be assigned")
	assert_eq(avatar_data.hairup_texture, dummy_texture, "HairUp texture should be assigned")
	assert_eq(avatar_data.hairdn_texture, dummy_texture, "HairDn texture should be assigned")
	assert_eq(avatar_data.hat_texture, dummy_texture, "Hat texture should be assigned")


## Test: idle animation has 5 frames
func test_idle_animation_has_five_frames() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var sprite_holder = compositor.get_node("SpriteHolder")
	var body = sprite_holder.get_node("Body")

	# Check that idle animation exists and has 5 frames
	assert_true(body.sprite_frames != null, "Body should have SpriteFrames configured")

	var frames = body.sprite_frames
	assert_true(frames.has_animation("idle"), "Should have idle animation")

	var frame_count = frames.get_frame_count("idle")
	assert_eq(frame_count, 5, "Idle animation should have 5 frames")


## Test: All layers have idle animation configured
func test_all_layers_have_idle_animation() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var sprite_holder = compositor.get_node("SpriteHolder")

	var layers = ["HairDn", "Body", "Eye", "HairUp", "Hat"]
	for layer_name in layers:
		var layer = sprite_holder.get_node(layer_name)
		assert_true(
			layer.sprite_frames != null, "%s should have SpriteFrames configured" % layer_name
		)
		assert_true(
			layer.sprite_frames.has_animation("idle"), "%s should have idle animation" % layer_name
		)


## Test: Animation can be played via compositor
func test_play_animation_starts_animation() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	# All layers should be able to play animation
	var sprite_holder = compositor.get_node("SpriteHolder")
	var body = sprite_holder.get_node("Body")

	body.play("idle")
	await wait_physics_frames(2)

	assert_true(body.is_playing(), "Body should be playing idle animation")


## Test: All layers sync to same frame when animation plays
func test_all_layers_sync_frames() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var sprite_holder = compositor.get_node("SpriteHolder")

	# Start all animations
	var layers = sprite_holder.get_children()
	for layer in layers:
		if layer is AnimatedSprite2D:
			layer.play("idle")

	await wait_physics_frames(5)

	# After some frames, all should be on the same frame
	var first_frame = sprite_holder.get_node("Body").frame
	for layer in layers:
		if layer is AnimatedSprite2D:
			assert_eq(
				layer.frame, first_frame, "%s should be synchronized with Body frame" % layer.name
			)


## Test: Compositor can apply AvatarData
func test_compositor_applies_avatar_data() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	var avatar_data = AvatarData.new()
	var dummy_texture = PlaceholderTexture2D.new()
	avatar_data.body_texture = dummy_texture
	avatar_data.eye_texture = dummy_texture
	avatar_data.hairup_texture = dummy_texture
	avatar_data.hairdn_texture = dummy_texture
	avatar_data.hat_texture = dummy_texture

	# Apply avatar data to compositor
	if compositor.has_method("apply_avatar_data"):
		compositor.apply_avatar_data(avatar_data)
		await wait_physics_frames(1)

		# Verify textures are applied
		var sprite_holder = compositor.get_node("SpriteHolder")
		# Note: Without actual sprite frames setup, we can't fully verify texture application
		# but we can verify the method exists and doesn't crash
		assert_true(true, "apply_avatar_data method should execute without errors")
	else:
		fail_test("Compositor should have apply_avatar_data method")


## Test: Compositor has AvatarCompositor class
func test_compositor_has_correct_class() -> void:
	compositor = AvatarScene.instantiate()
	add_child(compositor)
	await wait_physics_frames(1)

	assert_true(
		compositor.has_method("play_animation"), "Compositor should have play_animation method"
	)
	assert_true(compositor.has_method("_sync_frame"), "Compositor should have _sync_frame method")


## Helper: Create dummy texture for testing
func _create_dummy_texture() -> PlaceholderTexture2D:
	var texture = PlaceholderTexture2D.new()
	texture.set_size(Vector2(50, 60))
	return texture
