class_name GoldPopup
extends Node2D

var label: Label

var amount: int = 0
var lifetime: float = 1.5
var speed: float = 50.0
var label_settings: LabelSettings


func _init() -> void:
	name = "GoldPopup"
	label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-120, -30)
	label.size = Vector2(240, 60)
	label.z_index = 1

	label_settings = LabelSettings.new()
	label_settings.font = load("res://assets/fonts/NotoSansKR.tres")
	label_settings.font_size = 28
	label_settings.outline_size = 8
	label.label_settings = label_settings
	add_child(label)


func _ready() -> void:
	if amount >= 0:
		label.text = "+%d G" % amount
		label_settings.font_color = Color(1.0, 0.88, 0.29, 1.0)
		label_settings.outline_color = Color(0.25, 0.16, 0.05, 1.0)
	else:
		label.text = "-%d G" % abs(amount)
		label_settings.font_color = Color(1.0, 0.42, 0.42, 1.0)
		label_settings.outline_color = Color(0.30, 0.05, 0.05, 1.0)

	var tween = create_tween()
	tween.set_parallel(true)
	(
		tween
		. tween_property(self, "position:y", position.y - 50.0, lifetime)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(self, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)

	tween.chain().tween_callback(queue_free)


func setup(change_amount: int, p_lifetime: float = 1.5) -> void:
	amount = change_amount
	lifetime = p_lifetime
