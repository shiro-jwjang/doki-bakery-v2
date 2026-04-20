## EmoticonView - 이모티콘 표시 컴포넌트
## SNA-140: 이모티콘 이벤트 (EmoticonView) — 표시 + 클릭 처리
##
## 손님/요정의 감정 표현을 위한 이모티콘 이벤트 시스템
class_name EmoticonView
extends Node2D

## ==================== SIGNALS ====================

## Emitted when emoticon becomes visible
signal emoticon_shown(emoticon_type: String)

## Emitted when emoticon is hidden
signal emoticon_hidden

## ==================== CONSTANTS ====================

# Emoticon type to texture path mapping
const EMOTICON_PATHS := {
	"heart": "res://assets/sprites/ui/emoticons/하트.png",
	"star": "res://assets/sprites/ui/emoticons/따봉.png",
	"idea": "res://assets/sprites/ui/emoticons/느낌표.png",
	"yummy": "res://assets/sprites/ui/emoticons/yummy.png",
	"thinking": "res://assets/sprites/ui/emoticons/말풍선.png",
	"question": "res://assets/sprites/ui/emoticons/question.png",
}

const BALLOON_TEXTURE_PATH := "res://assets/sprites/ui/emoticons/말풍선.png"
const FALLBACK_EMOTICON_PATH := "res://assets/sprites/ui/emoticons/question.png"
const SPRITE_SCALE := Vector2(2.0, 2.0)
const ICON_OFFSET := Vector2(0, -4)

# Placeholder textures for testing (colored squares)
const PLACEHOLDER_COLORS := {
	"heart": Color.RED,
	"star": Color.YELLOW,
	"yummy": Color.GREEN,
	"thinking": Color.BLUE,
	"question": Color.PURPLE,
}

## ==================== EXPORTS ====================

## Offset from character position (negative Y = above)
@export var position_offset: Vector2 = Vector2(0, -40)

## Default display duration in seconds
@export var default_duration: float = 2.0

## Fade animation duration
@export var fade_duration: float = 0.3

## ==================== EXPORTS ====================

## Character ID this emoticon belongs to
@export var character_id: String = ""

## ==================== PRIVATE VARIABLES ====================

var _balloon_sprite: Sprite2D
var _icon_sprite: Sprite2D
var _area: Area2D
var _tween: Tween
var _is_showing: bool = false
var _current_type: String = ""

## ==================== LIFECYCLE ====================


func _ready() -> void:
	print("[DEBUG-EV] _ready START cid='%s'" % character_id)
	_setup_nodes()
	_connect_event_bus()
	hide_emoticon()
	print("[DEBUG-EV] _ready DONE cid='%s'" % character_id)


func _exit_tree() -> void:
	_disconnect_event_bus()
	_cleanup_tween()


## ==================== PUBLIC API ====================


## Show an emoticon with the specified type and duration
func show_emoticon(emoticon_type: String, duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration

	# Cancel any existing animation
	_cleanup_tween()

	# Set textures
	_balloon_sprite.texture = _get_balloon_texture()
	var icon_texture := _get_emoticon_texture(emoticon_type)
	var has_icon := _has_icon_for_type(emoticon_type)
	if icon_texture and has_icon:
		_icon_sprite.texture = icon_texture
	_current_type = emoticon_type

	# Position sprites
	_balloon_sprite.position = position_offset
	_icon_sprite.position = position_offset + ICON_OFFSET

	# Start visible but transparent for fade in
	_balloon_sprite.modulate.a = 0.0
	_icon_sprite.modulate.a = 0.0
	_balloon_sprite.show()
	if has_icon:
		_icon_sprite.show()
	else:
		_icon_sprite.hide()
	_is_showing = true

	# Fade in animation
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_balloon_sprite, "modulate:a", 1.0, fade_duration)
	_tween.tween_property(_icon_sprite, "modulate:a", 1.0, fade_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(_on_fade_in_complete.bind(duration, emoticon_type))


## Hide the current emoticon
func hide_emoticon() -> void:
	if not _is_showing:
		return

	_cleanup_tween()

	# Fade out animation
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_balloon_sprite, "modulate:a", 0.0, fade_duration)
	_tween.tween_property(_icon_sprite, "modulate:a", 0.0, fade_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(_on_fade_out_complete)


## Check if emoticon is currently showing
func is_showing() -> bool:
	return _is_showing


## Bind this view to a character and ensure it is listening for emotion events.
func bind_character(id: String) -> void:
	print("[DEBUG-EV] bind_character('%s') inside_tree=%s" % [id, is_inside_tree()])
	character_id = id
	if is_inside_tree():
		_connect_event_bus()


## Get texture for emoticon type (used by tests)
func _get_emoticon_texture(emoticon_type: String) -> Texture2D:
	var path: String = EMOTICON_PATHS.get(emoticon_type, "")

	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path)

	if ResourceLoader.exists(FALLBACK_EMOTICON_PATH):
		return load(FALLBACK_EMOTICON_PATH)

	# Create placeholder texture for missing assets
	return _create_placeholder_texture(emoticon_type)


## ==================== PRIVATE METHODS ====================


func _setup_nodes() -> void:
	# Setup background and foreground sprites
	_balloon_sprite = get_node_or_null("BalloonSprite")
	if _balloon_sprite == null:
		_balloon_sprite = get_node_or_null("Sprite2D")
		if _balloon_sprite:
			_balloon_sprite.name = "BalloonSprite"
		else:
			_balloon_sprite = Sprite2D.new()
			_balloon_sprite.name = "BalloonSprite"
			add_child(_balloon_sprite)

	_icon_sprite = get_node_or_null("IconSprite")
	if _icon_sprite == null:
		_icon_sprite = Sprite2D.new()
		_icon_sprite.name = "IconSprite"
		add_child(_icon_sprite)

	_balloon_sprite.centered = true
	_balloon_sprite.scale = SPRITE_SCALE
	_balloon_sprite.texture = _get_balloon_texture()
	_balloon_sprite.hide()

	_icon_sprite.centered = true
	_icon_sprite.scale = SPRITE_SCALE
	_icon_sprite.hide()

	# Setup Area2D
	_area = get_node_or_null("Area2D")
	if _area:
		if not _area.input_event.is_connected(_on_input_event):
			_area.input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _is_showing:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_emoticon_clicked()


func _on_emoticon_clicked() -> void:
	# Send notification via EventBus
	var title := "감정 표현"
	var desc := (
		"캐릭터(%s)가 %s 상태입니다!"
		% [character_id if not character_id.is_empty() else "이름없음", _current_type]
	)

	if EventBusAutoload.has_signal("notification_requested"):
		EventBusAutoload.notification_requested.emit(title, desc, _get_notification_texture(), 0)

	# Optional: Hide after click or show feedback
	hide_emoticon()


func _connect_event_bus() -> void:
	var event_bus := get_node_or_null("/root/EventBusAutoload")
	print("[DEBUG-EV] _connect_event_bus bus=%s cid='%s'" % [str(event_bus), character_id])
	if event_bus and event_bus.has_signal("emotion_triggered"):
		var already := event_bus.emotion_triggered.is_connected(_on_emotion_triggered)
		print("[DEBUG-EV] signal found, already_connected=%s" % already)
		if not already:
			event_bus.emotion_triggered.connect(_on_emotion_triggered)
			print("[DEBUG-EV] CONNECTED to emotion_triggered")
		else:
			print("[DEBUG-EV] was already connected, skip")
	else:
		print("[DEBUG-EV] FAIL: event_bus=%s has_signal=%s" % [str(event_bus), event_bus.has_signal("emotion_triggered") if event_bus else "N/A"])


func _disconnect_event_bus() -> void:
	var event_bus := get_node_or_null("/root/EventBusAutoload")
	if event_bus and event_bus.has_signal("emotion_triggered"):
		if event_bus.emotion_triggered.is_connected(_on_emotion_triggered):
			event_bus.emotion_triggered.disconnect(_on_emotion_triggered)


func _cleanup_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _create_placeholder_texture(emoticon_type: String) -> ImageTexture:
	var color: Color = PLACEHOLDER_COLORS.get(emoticon_type, Color.WHITE)
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)

	var texture := ImageTexture.create_from_image(image)
	return texture


func _get_balloon_texture() -> Texture2D:
	if ResourceLoader.exists(BALLOON_TEXTURE_PATH):
		return load(BALLOON_TEXTURE_PATH)

	return _create_placeholder_texture("thinking")


func _has_icon_for_type(emoticon_type: String) -> bool:
	return EMOTICON_PATHS.get(emoticon_type, FALLBACK_EMOTICON_PATH) != BALLOON_TEXTURE_PATH


func _get_notification_texture() -> Texture2D:
	if _icon_sprite.visible and _icon_sprite.texture:
		return _icon_sprite.texture

	return _balloon_sprite.texture


## ==================== CALLBACKS ====================


func _on_fade_in_complete(duration: float, emoticon_type: String) -> void:
	# Emit shown signal after fade-in completes
	emoticon_shown.emit(emoticon_type)

	# Wait for duration, then fade out
	_tween = create_tween()
	_tween.tween_interval(maxf(duration - fade_duration, 0.0))  # Subtract fade time from total
	_tween.tween_callback(hide_emoticon)


func _on_fade_out_complete() -> void:
	_balloon_sprite.hide()
	_icon_sprite.hide()
	_is_showing = false
	emoticon_hidden.emit()


func _on_emotion_triggered(triggered_character_id: String, emotion_type: String) -> void:
	print("[DEBUG-EV] TRIGGERED trig_id='%s' my_id='%s' match=%s" % [triggered_character_id, character_id, triggered_character_id == character_id])
	# Only show if this emoticon belongs to the triggered character
	if not character_id.is_empty() and character_id == triggered_character_id:
		print("[DEBUG-EV] SHOWING '%s'" % emotion_type)
		show_emoticon(emotion_type)
