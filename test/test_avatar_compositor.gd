extends GutTest

## SNA-150: AvatarCompositor 테스트
## TDD Red 단계 - 요구사항 검증

var avatar: Node2D
var compositor: AvatarCompositor


func before_each() -> void:
	# 스크립트 직접 인스턴스화
	var script: GDScript = load("res://scripts/components/avatar_compositor.gd")
	compositor = script.new()
	compositor.name = "AvatarCompositor"
	
	# Layers 노드 생성
	var layers_node := Node2D.new()
	layers_node.name = "Layers"
	compositor.add_child(layers_node)
	
	# 5개 레이어 생성
	var layer_names: Array[String] = ["HairDn", "Body", "Eye", "HairUp", "Hat"]
	var z_indices: Array[int] = [0, 1, 2, 3, 4]
	
	for i: int in range(5):
		var sprite := AnimatedSprite2D.new()
		sprite.name = layer_names[i]
		sprite.z_index = z_indices[i]
		
		# SpriteFrames 생성
		var frames := SpriteFrames.new()
		frames.add_animation("idle")
		for frame_idx: int in range(5):
			frames.add_frame("idle", null)
		sprite.sprite_frames = frames
		sprite.animation = "idle"
		
		layers_node.add_child(sprite)
	
	avatar = Node2D.new()
	avatar.name = "Avatar"
	avatar.add_child(compositor)
	add_child(avatar)
	
	# _ready 대기
	await wait_for_signal(compositor.ready, 1.0)


func after_each() -> void:
	if avatar:
		avatar.queue_free()
		avatar = null
		compositor = null


#region REQ: 레이어 존재 및 Z-index 검증


func test_has_five_layers() -> void:
	# REQ: 5개 레이어 (hat, hairup, eye, body, hairdn) 존재
	assert_not_null(compositor, "AvatarCompositor should exist")
	
	var layers: Node = compositor.get_node_or_null("Layers")
	assert_not_null(layers, "Layers holder should exist")
	
	var hairdn: Node = layers.get_node_or_null("HairDn")
	var body: Node = layers.get_node_or_null("Body")
	var eye: Node = layers.get_node_or_null("Eye")
	var hairup: Node = layers.get_node_or_null("HairUp")
	var hat: Node = layers.get_node_or_null("Hat")
	
	assert_not_null(hairdn, "HairDn layer should exist")
	assert_not_null(body, "Body layer should exist")
	assert_not_null(eye, "Eye layer should exist")
	assert_not_null(hairup, "HairUp layer should exist")
	assert_not_null(hat, "Hat layer should exist")


func test_layer_z_index_order() -> void:
	# REQ: Z-index 순서: hat(4) > hairup(3) > eye(2) > body(1) > hairdn(0)
	var layers: Node = compositor.get_node_or_null("Layers")
	
	var hairdn: CanvasItem = layers.get_node_or_null("HairDn")
	var body: CanvasItem = layers.get_node_or_null("Body")
	var eye: CanvasItem = layers.get_node_or_null("Eye")
	var hairup: CanvasItem = layers.get_node_or_null("HairUp")
	var hat: CanvasItem = layers.get_node_or_null("Hat")
	
	assert_eq(hairdn.z_index, 0, "HairDn z_index should be 0")
	assert_eq(body.z_index, 1, "Body z_index should be 1")
	assert_eq(eye.z_index, 2, "Eye z_index should be 2")
	assert_eq(hairup.z_index, 3, "HairUp z_index should be 3")
	assert_eq(hat.z_index, 4, "Hat z_index should be 4")


#endregion


#region REQ: 애니메이션 동기화 검증


func test_play_animation_syncs_all_layers() -> void:
	# REQ: 애니메이션 재생 시 모든 레이어 동기화
	assert_not_null(compositor, "AvatarCompositor should exist")
	
	# play_animation 메서드 존재 확인
	assert_true(compositor.has_method("play_animation"), "Should have play_animation method")
	
	# idle 애니메이션 재생
	compositor.play_animation("idle")
	
	# 모든 레이어가 같은 애니메이션 재생 중인지 확인
	var layers: Node = compositor.get_node_or_null("Layers")
	for child: Node in layers.get_children():
		if child is AnimatedSprite2D:
			var sprite: AnimatedSprite2D = child as AnimatedSprite2D
			assert_eq(sprite.animation, "idle", "%s should play idle animation" % child.name)
			assert_true(sprite.is_playing(), "%s should be playing" % child.name)


func test_all_layers_have_same_frame_count() -> void:
	# REQ: 모든 레이어가 같은 프레임 수를 가져야 함
	var layers: Node = compositor.get_node_or_null("Layers")
	var frame_counts: Array[int] = []
	
	for child: Node in layers.get_children():
		if child is AnimatedSprite2D:
			var sprite: AnimatedSprite2D = child as AnimatedSprite2D
			var frames: SpriteFrames = sprite.sprite_frames
			if frames:
				var frame_count: int = frames.get_frame_count("idle")
				frame_counts.append(frame_count)
	
	# 모든 프레임 수가 같은지 확인
	if frame_counts.size() > 0:
		var first_count: int = frame_counts[0]
		for count: int in frame_counts:
			assert_eq(count, first_count, "All layers should have same frame count")


#endregion


#region REQ: AvatarData 리소스 확장성 검증


func test_avatar_data_resource_exists() -> void:
	# REQ: AvatarData 리소스로 확장성 확보
	var avatar_data_script: GDScript = load("res://resources/avatar_data.gd")
	assert_not_null(avatar_data_script, "AvatarData script should exist")
	
	# AvatarData 인스턴스 생성 테스트
	var data: Resource = avatar_data_script.new()
	assert_not_null(data, "AvatarData instance should be creatable")


func test_avatar_data_has_five_texture_exports() -> void:
	# REQ: AvatarData에 5개 텍스처 export 변수 존재
	var avatar_data_script: GDScript = load("res://resources/avatar_data.gd")
	var data: Resource = avatar_data_script.new()
	
	# 프로퍼티 존재 확인
	var props: Array[Dictionary] = data.get_property_list()
	var prop_names: Array[String] = []
	for prop: Dictionary in props:
		prop_names.append(prop["name"])
	
	assert_true("body_texture" in prop_names, "Should have body_texture property")
	assert_true("eye_texture" in prop_names, "Should have eye_texture property")
	assert_true("hairup_texture" in prop_names, "Should have hairup_texture property")
	assert_true("hairdn_texture" in prop_names, "Should have hairdn_texture property")
	assert_true("hat_texture" in prop_names, "Should have hat_texture property")


#endregion


#region REQ: 프레임 전환 검증


func test_sync_frame_method_exists() -> void:
	# REQ: _sync_frame 메서드 존재
	assert_not_null(compositor, "AvatarCompositor should exist")
	assert_true(compositor.has_method("_sync_frame"), "Should have _sync_frame method")


func test_sync_frame_updates_all_layers() -> void:
	# REQ: 프레임 전환 시 모든 레이어 동기화
	compositor.play_animation("idle")
	await wait_seconds(0.1)
	
	# 프레임 동기화 호출
	compositor._sync_frame(2)
	
	var layers: Node = compositor.get_node_or_null("Layers")
	for child: Node in layers.get_children():
		if child is AnimatedSprite2D:
			var sprite: AnimatedSprite2D = child as AnimatedSprite2D
			assert_eq(sprite.frame, 2, "%s frame should be 2" % child.name)


#endregion
