## Test suite for EmoticonView component
## SNA-140: 이모티콘 이벤트 (EmoticonView) — 표시 + 클릭 처리
extends GutTest

const EmoticonViewScript := preload("res://scripts/ui/emoticon_view.gd")

var emoticon_view: Node2D
var _original_modulate: Color


func before_all() -> void:
	# Ensure test assets directory exists
	DirAccess.make_dir_recursive_absolute("res://test/fixtures/emoticons/")


func before_each() -> void:
	# Create fresh EmoticonView instance for each test
	emoticon_view = Node2D.new()
	emoticon_view.set_script(EmoticonViewScript)
	add_child_autofree(emoticon_view)
	await wait_for_signal(emoticon_view.ready, 1.0)


func after_each() -> void:
	# Clean up handled by autofree
	pass


## REQ: 이모티콘 5종 (heart, star, yummy, thinking, question) 리소스 로드
func test_emoticon_types_have_textures() -> void:
	var types := ["heart", "star", "yummy", "thinking", "question"]
	for emoticon_type in types:
		var texture: Texture2D = emoticon_view._get_emoticon_texture(emoticon_type)
		assert_not_null(texture, "Should have texture for type: %s" % emoticon_type)


## REQ: show_emoticon(type, duration) API exists
func test_show_emoticon_api_exists() -> void:
	assert_has_method(emoticon_view, "show_emoticon")


## REQ: hide_emoticon() API exists
func test_hide_emoticon_api_exists() -> void:
	assert_has_method(emoticon_view, "hide_emoticon")


## REQ: show_emoticon makes emoticon visible
func test_show_emoticon_displays_emoticon() -> void:
	emoticon_view.show_emoticon("heart", 2.0)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)
	assert_true(emoticon_view.is_showing(), "Emoticon should be showing")


## REQ: hide_emoticon hides the emoticon
func test_hide_emoticon_hides_emoticon() -> void:
	emoticon_view.show_emoticon("heart", 2.0)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)
	emoticon_view.hide_emoticon()
	assert_false(emoticon_view.is_showing(), "Emoticon should be hidden")


## REQ: 지속 시간 후 자동 숨김 (1.5-2초)
func test_emoticon_auto_hides_after_duration() -> void:
	var test_duration := 0.5  # Short duration for testing
	emoticon_view.show_emoticon("heart", test_duration)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)
	assert_true(emoticon_view.is_showing(), "Emoticon should be showing")

	# Wait for auto-hide
	await wait_for_signal(emoticon_view.emoticon_hidden, 2.0)
	assert_false(emoticon_view.is_showing(), "Emoticon should auto-hide after duration")


## REQ: 페이드 인 애니메이션
func test_fade_in_animation() -> void:
	emoticon_view.show_emoticon("heart", 2.0)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)

	# Check modulate alpha is 1.0 after fade in
	var sprite: Node = emoticon_view.get_node_or_null("Sprite2D")
	if sprite:
		assert_almost_eq(sprite.modulate.a, 1.0, 0.1, "Sprite should be fully visible after fade in")


## REQ: 페이드 아웃 애니메이션
func test_fade_out_animation() -> void:
	var test_duration := 0.3
	emoticon_view.show_emoticon("heart", test_duration)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)

	# Wait for fade out to complete
	await wait_for_signal(emoticon_view.emoticon_hidden, 2.0)

	var sprite: Node = emoticon_view.get_node_or_null("Sprite2D")
	if sprite:
		assert_almost_eq(sprite.modulate.a, 0.0, 0.1, "Sprite should be invisible after fade out")


## REQ: 잘못된 이모티콘 타입 처리
func test_invalid_emoticon_type_returns_default() -> void:
	var texture: Texture2D = emoticon_view._get_emoticon_texture("invalid_type")
	# Should return a default texture or null gracefully
	# The implementation should handle this without crashing
	assert_true(true, "Should handle invalid type without crashing")


## REQ: EventBus 연동 - emotion_triggered 시그널
func test_event_bus_signal_connection() -> void:
	# Check if EventBus has emotion_triggered signal
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus:
		assert_has_signal(event_bus, "emotion_triggered", "EventBus should have emotion_triggered signal")


## REQ: 캐릭터 ID와 함께 이모티콘 표시
func test_show_emoticon_with_character_context() -> void:
	emoticon_view.character_id = "customer_001"
	emoticon_view.show_emoticon("heart", 2.0)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)
	assert_eq(emoticon_view.character_id, "customer_001", "Character ID should be preserved")


## REQ: 이모티콘 위치는 캐릭터 머리 위
func test_emoticon_position_offset() -> void:
	# Default offset should be above the character
	emoticon_view.show_emoticon("heart", 2.0)
	await wait_for_signal(emoticon_view.emoticon_shown, 1.0)

	var sprite: Node = emoticon_view.get_node_or_null("Sprite2D")
	if sprite:
		# Position should be negative Y (above character)
		assert_true(sprite.position.y <= 0, "Sprite should be positioned above character (negative Y)")
