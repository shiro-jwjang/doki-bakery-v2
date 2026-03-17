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
	"heart": "res://assets/placeholders/emoticon_heart.png",
	"star": "res://assets/placeholders/emoticon_star.png",
	"idea": "res://assets/placeholders/emoticon_idea.png",
	"yummy": "res://assets/sprites/ui/emoticons/yummy.png",
	"thinking": "res://assets/sprites/ui/emoticons/thinking.png",
	"question": "res://assets/sprites/ui/emoticons/question.png",
}

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

## ==================== PUBLIC VARIABLES ====================

## Character ID this emoticon belongs to
var character_id: String = ""

## ==================== PRIVATE VARIABLES ====================

var _sprite: Sprite2D
var _area: Area2D
var _tween: Tween
var _is_showing: bool = false
var _current_type: String = ""

## ==================== LIFECYCLE ====================


func _ready() -> void:
	_setup_nodes()
	_connect_event_bus()
	hide_emoticon()


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

	# Set texture
	var texture := _get_emoticon_texture(emoticon_type)
	if texture:
		_sprite.texture = texture
	_current_type = emoticon_type

	# Position sprite
	_sprite.position = position_offset

	# Start visible but transparent for fade in
	_sprite.modulate.a = 0.0
	_sprite.show()
	_is_showing = true

	# Fade in animation
	_tween = create_tween()
	_tween.tween_property(_sprite, "modulate:a", 1.0, fade_duration)
	_tween.tween_callback(_on_fade_in_complete.bind(duration, emoticon_type))


## Hide the current emoticon
func hide_emoticon() -> void:
	if not _is_showing:
		return

	_cleanup_tween()

	# Fade out animation
	_tween = create_tween()
	_tween.tween_property(_sprite, "modulate:a", 0.0, fade_duration)
	_tween.tween_callback(_on_fade_out_complete)


## Check if emoticon is currently showing
func is_showing() -> bool:
	return _is_showing


## Get texture for emoticon type (used by tests)
func _get_emoticon_texture(emoticon_type: String) -> Texture2D:
	var path: String = EMOTICON_PATHS.get(emoticon_type, "")

	if path.is_empty():
		return null

	if ResourceLoader.exists(path):
		return load(path)

	# Create placeholder texture for missing assets
	return _create_placeholder_texture(emoticon_type)


## ==================== PRIVATE METHODS ====================


func _setup_nodes() -> void:
	# Setup Sprite2D
	_sprite = get_node_or_null("Sprite2D")
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)

	_sprite.centered = true
	_sprite.scale = Vector2(3.0, 3.0)  # 16x16 -> 48x48
	_sprite.hide()

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
		EventBusAutoload.notification_requested.emit(title, desc, _sprite.texture, 0)

	# Optional: Hide after click or show feedback
	hide_emoticon()


func _connect_event_bus() -> void:
	var event_bus := get_node_or_null("/root/EventBusAutoload")
	if event_bus and event_bus.has_signal("emotion_triggered"):
		if not event_bus.emotion_triggered.is_connected(_on_emotion_triggered):
			event_bus.emotion_triggered.connect(_on_emotion_triggered)


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


## ==================== CALLBACKS ====================


func _on_fade_in_complete(duration: float, emoticon_type: String) -> void:
	# Emit shown signal after fade-in completes
	emoticon_shown.emit(emoticon_type)

	# Wait for duration, then fade out
	_tween = create_tween()
	_tween.tween_interval(duration - fade_duration)  # Subtract fade time from total
	_tween.tween_callback(hide_emoticon)


func _on_fade_out_complete() -> void:
	_sprite.hide()
	_is_showing = false
	emoticon_hidden.emit()


func _on_emotion_triggered(triggered_character_id: String, emotion_type: String) -> void:
	# Only show if this emoticon belongs to the triggered character
	if character_id.is_empty() or character_id == triggered_character_id:
		show_emoticon(emotion_type)
