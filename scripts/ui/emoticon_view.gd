class_name EmoticonView
extends Node2D

## EmoticonView
##
## Displays emoticons above character heads with fade animations.
## SNA-140: EmoticonView — TDD
##
## Emoticon types:
## - heart: Satisfaction (delicious bread purchased)
## - star: Moved (rare bread purchased)
## - yummy: Tasty (normal purchase)
## - thinking: Thinking (checking display)
## - question: Curious (bread out of stock)

## Emoticon sprite
@onready var sprite: Sprite2D = $Sprite2D

## Animation player for fade effects
@onready var anim_player: AnimationPlayer = $AnimationPlayer

## Emoticon resource paths
const EMOTICON_PATHS := {
	"heart": "res://assets/sprites/ui/emoticons/heart.tres",
	"star": "res://assets/sprites/ui/emoticons/star.tres",
	"yummy": "res://assets/sprites/ui/emoticons/yummy.tres",
	"thinking": "res://assets/sprites/ui/emoticons/thinking.tres",
	"question": "res://assets/sprites/ui/emoticons/question.tres",
}

## Auto-hide timer
var _hide_timer: Timer = null


func _ready() -> void:
	# Start hidden
	if sprite:
		sprite.visible = false
		sprite.modulate.a = 0.0
	
	# Create animation player if it doesn't exist
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		add_child(anim_player)
		_create_fade_animation()
	
	# Create auto-hide timer
	_hide_timer = Timer.new()
	_hide_timer.name = "HideTimer"
	_hide_timer.one_shot = true
	_hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(_hide_timer)
	
	# Connect to EventBus emotion_triggered signal
	# Note: Connect in ready to ensure EventBus is loaded
	if EventBus.has_signal("emotion_triggered"):
		if not EventBus.emotion_triggered.is_connected(_on_emotion_triggered):
			EventBus.emotion_triggered.connect(_on_emotion_triggered)


## Show emoticon with specified type and duration
## type: Emoticon type (heart, star, yummy, thinking, question)
## duration: Display duration in seconds (default 2.0)
func show_emoticon(type: String, duration: float = 2.0) -> void:
	if not sprite:
		return
	
	# Load emoticon texture
	if EMOTICON_PATHS.has(type):
		var texture_path = EMOTICON_PATHS[type]
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
		else:
			# Fallback: create placeholder texture
			sprite.texture = _create_placeholder_texture(type)
	
	# Show sprite
	sprite.visible = true
	sprite.modulate.a = 0.0
	
	# Play fade in animation
	if anim_player and anim_player.has_animation("fade_in"):
		anim_player.play("fade_in")
	
	# Start auto-hide timer
	if _hide_timer:
		_hide_timer.wait_time = duration
		_hide_timer.start()


## Hide emoticon immediately
func hide_emoticon() -> void:
	if not sprite:
		return
	
	# Play fade out animation
	if anim_player and anim_player.has_animation("fade_out"):
		anim_player.play("fade_out")
		await anim_player.animation_finished
	else:
		sprite.visible = false
		sprite.modulate.a = 0.0


## Create fade in/out animations
func _create_fade_animation() -> void:
	if not anim_player:
		return
	
	var fade_in = Animation.new()
	fade_in.resource_name = "fade_in"
	fade_in.length = 0.3
	fade_in.track_set_path(0, "Sprite2D:modulate:a")
	fade_in.track_insert_key(0, 0.0, 0.0)
	fade_in.track_insert_key(0, 0.3, 1.0)
	fade_in.loop_mode = Animation.LOOP_NONE
	anim_player.add_animation("fade_in", fade_in)
	
	var fade_out = Animation.new()
	fade_out.resource_name = "fade_out"
	fade_out.length = 0.3
	fade_out.track_set_path(0, "Sprite2D:modulate:a")
	fade_out.track_insert_key(0, 0.0, 1.0)
	fade_out.track_insert_key(0, 0.3, 0.0)
	fade_out.loop_mode = Animation.LOOP_NONE
	anim_player.add_animation("fade_out", fade_out)


## Create placeholder texture when asset is missing
func _create_placeholder_texture(type: String) -> ImageTexture:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw simple shapes based on type
	var color_map := {
		"heart": Color.RED,
		"star": Color.YELLOW,
		"yummy": Color.ORANGE,
		"thinking": Color.BLUE,
		"question": Color.GREEN,
	}
	
	var color = color_map.get(type, Color.WHITE)
	
	for y in range(16):
		for x in range(16):
			# Simple pixel art pattern
			var dx = abs(x - 8)
			var dy = abs(y - 8)
			if dx + dy < 6:
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture


## Handle EventBus emotion_triggered signal
func _on_emotion_triggered(character_id: String, emotion_type: String) -> void:
	# Only respond if this is the target character
	if get_parent() and get_parent().name == character_id:
		show_emoticon(emotion_type, 2.0)


## Handle auto-hide timer timeout
func _on_hide_timer_timeout() -> void:
	hide_emoticon()


func _exit_tree() -> void:
	# Disconnect EventBus signal
	if EventBus.has_signal("emotion_triggered"):
		if EventBus.emotion_triggered.is_connected(_on_emotion_triggered):
			EventBus.emotion_triggered.disconnect(_on_emotion_triggered)
