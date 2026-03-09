extends Control

## LevelUpNotification
## SNA-99: 레벨업 시 해금 알림 표시
##
## Displays a popup notification when the player levels up,
## showing unlocked recipes and features.

## Current unlocked items
var _unlocked_items: Array[String] = []

## Auto-close timer (3 seconds)
@onready var auto_close_timer: Timer = $AutoCloseTimer

## Level label
@onready var level_label: Label = $Panel/VBoxContainer/LevelLabel

## Items label
@onready var items_label: Label = $Panel/VBoxContainer/ItemsLabel


func _ready() -> void:
	# Start hidden
	visible = false

	# Connect timer timeout to hide
	if auto_close_timer:
		auto_close_timer.timeout.connect(_on_auto_close_timer_timeout)


## Show notification with level and unlocked items
## items: Array of dictionaries with "id" and "name" keys, or array of strings (ids only)
func show_unlocks(level: int, items: Array) -> void:
	_unlocked_items = items

	# Update level text
	if level_label:
		level_label.text = "Level %d Reached!" % level

	# Update items text
	if items_label:
		if items.is_empty():
			items_label.text = "No new unlocks"
		else:
			var item_names: PackedStringArray = []
			for item in items:
				# Handle both dict format {"id": "...", "name": "..."} and string format
				if typeof(item) == TYPE_DICTIONARY:
					item_names.append(item.get("name", item.get("id", "Unknown")))
				else:
					item_names.append(str(item))

			items_label.text = "Unlocked:\n" + "\n".join(item_names)

	# Show notification
	visible = true

	# Start auto-close timer
	if auto_close_timer:
		auto_close_timer.start()


## Hide notification
func hide_notification() -> void:
	visible = false
	if auto_close_timer:
		auto_close_timer.stop()


## Get current unlocked items text (for testing)
func get_items_text() -> String:
	if items_label:
		return items_label.text
	return ""


func _on_auto_close_timer_timeout() -> void:
	hide_notification()
