class_name AvatarCompositor
extends Node2D

## Avatar layer compositor for character rendering
## Manages 5 layers with proper z-index and animation synchronization
## SNA-150: 아바타 레이어 합성 시스템

## Node references
@onready var _sprite_holder: Node2D = $SpriteHolder
@onready var _hairdn: AnimatedSprite2D = $SpriteHolder/HairDn
@onready var _body: AnimatedSprite2D = $SpriteHolder/Body
@onready var _eye: AnimatedSprite2D = $SpriteHolder/Eye
@onready var _hairup: AnimatedSprite2D = $SpriteHolder/HairUp
@onready var _hat: AnimatedSprite2D = $SpriteHolder/Hat


func _ready() -> void:
	# Initialize SpriteFrames with idle animation for all layers
	_setup_idle_animation()

	# Connect frame changed signal to sync all layers
	if _body:
		_body.frame_changed.connect(_on_frame_changed)


## Setup idle animation with 5 frames for all layers
func _setup_idle_animation() -> void:
	var dummy_texture = PlaceholderTexture2D.new()
	dummy_texture.set_size(Vector2(50, 60))

	var layers = [_hairdn, _body, _eye, _hairup, _hat]
	for layer in layers:
		if layer:
			var sprite_frames = SpriteFrames.new()
			sprite_frames.add_animation("idle")
			for i in range(5):
				sprite_frames.add_frame("idle", dummy_texture)
			layer.sprite_frames = sprite_frames
			layer.animation = "idle"


## Play animation on all layers
func play_animation(anim_name: String) -> void:
	if _hairdn and _hairdn.sprite_frames and _hairdn.sprite_frames.has_animation(anim_name):
		_hairdn.play(anim_name)
	if _body and _body.sprite_frames and _body.sprite_frames.has_animation(anim_name):
		_body.play(anim_name)
	if _eye and _eye.sprite_frames and _eye.sprite_frames.has_animation(anim_name):
		_eye.play(anim_name)
	if _hairup and _hairup.sprite_frames and _hairup.sprite_frames.has_animation(anim_name):
		_hairup.play(anim_name)
	if _hat and _hat.sprite_frames and _hat.sprite_frames.has_animation(anim_name):
		_hat.play(anim_name)


## Synchronize all layers to the same frame
func _sync_frame(frame: int) -> void:
	if _hairdn:
		_hairdn.frame = frame
	if _body:
		_body.frame = frame
	if _eye:
		_eye.frame = frame
	if _hairup:
		_hairup.frame = frame
	if _hat:
		_hat.frame = frame


## Apply avatar data to set textures
func apply_avatar_data(data: AvatarData) -> void:
	if data == null:
		return

	# Note: Texture application requires proper SpriteFrames setup
	# This is a placeholder for the actual implementation
	# Real implementation would update SpriteFrames with new textures


## Callback when body frame changes - sync all other layers
func _on_frame_changed() -> void:
	if _body:
		_sync_frame(_body.frame)
