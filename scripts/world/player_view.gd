extends Node2D

## PlayerView Character
## Main player character for the bakery world.
## Contains:
## - AnimatedSprite2D for idle/walk animations
## - Initial position at (0, 0) or in front of stall
## SNA-90: PlayerView — 주인공 배치 + idle 애니메이션

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Start playing idle animation
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
