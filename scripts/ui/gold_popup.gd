class_name GoldPopup
extends Node2D

var label: Label

var amount: int = 0
var lifetime: float = 1.5
var speed: float = 50.0


func _init() -> void:
	name = "GoldPopup"
	label = Label.new()
	label.name = "Label"
	add_child(label)


func _ready() -> void:
	if amount >= 0:
		label.text = "+%dG ↑" % amount
		label.modulate = Color.GREEN
	else:
		label.text = "%dG ↓" % amount
		label.modulate = Color.RED

	var tween = create_tween()
	tween.set_parallel(true)
	(
		tween
		. tween_property(self, "position:y", position.y - 50.0, lifetime)
		. set_trans(Tween.TRANS_OUT)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(self, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_IN).set_ease(
		Tween.EASE_IN
	)

	tween.chain().tween_callback(queue_free)


func setup(change_amount: int) -> void:
	amount = change_amount
