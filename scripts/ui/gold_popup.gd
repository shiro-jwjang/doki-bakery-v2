class_name GoldPopup
extends Node2D

## GoldPopup - Floating text showing gold changes
## SNA-94: HUD 골드 변동 팝업 애니메이션
##
## Displays "+30G ↑" (green) for gains, "-10G ↓" (red) for losses
## Floats up and fades out over ~1.5 seconds

## Label node for displaying text
@onready var _label: Label = $Label

## Duration before popup disappears (seconds)
const LIFETIME: float = 1.5

## Animation speed
const FLOAT_SPEED: float = -50.0  # Negative = up


func _ready() -> void:
	# Start floating animation
	_start_animation()


## Setup the popup with a gold amount
## @param amount: Gold change amount (positive or negative)
func setup(amount: int) -> void:
	if _label == null:
		await ready

	var text: String
	var color: Color

	if amount >= 0:
		text = "+%dG ↑" % amount
		color = Color.GREEN
	else:
		text = "%dG ↓" % amount  # amount is already negative
		color = Color.RED

	_label.text = text
	_label.modulate = color

	# Auto-destroy after lifetime
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()


## Start floating and fading animation
func _start_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)

	# Float up
	tween.tween_property(self, "position:y", position.y + FLOAT_SPEED * LIFETIME, LIFETIME)

	# Fade out
	tween.tween_property(_label, "modulate:a", 0.0, LIFETIME)
