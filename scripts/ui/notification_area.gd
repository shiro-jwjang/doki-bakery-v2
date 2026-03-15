extends Control
class_name NotificationArea

const MAX_NOTIFICATIONS: int = 3
const NOTIFICATION_DURATION: float = 3.0  # seconds
const NotificationItemScene = preload("res://scenes/ui/notification_item.tscn")

## NotificationArea - HUD 우측 상단 알림 팝업 시스템
## SNA-141: 알림 팝업 (NotificationArea) — TDD
##
## 기능:
## - 우선순위 큐 기반 노티피케이션 표시 (최대 3개)
## - 슬라이드 인/아웃 애니메이션 (3초 지속)
## - EventBus.notification_requested 시그널 연동

@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Track active notifications with their priority
var _active_notifications: Array[Dictionary] = []  # [{item, priority, timer}]
var _pending_notifications: Array[Dictionary] = []  # Priority queue for pending


func _ready() -> void:
	# Connect to EventBus signal
	EventBus.notification_requested.connect(_on_notification_requested)


## Show a notification with the given parameters
func show_notification(title: String, desc: String, icon: Texture2D, priority: int = 0) -> void:
	var notification_data := {
		"title": title, "description": desc, "icon": icon, "priority": priority
	}

	# Check if we should add to pending or active queue
	if _active_notifications.size() < MAX_NOTIFICATIONS:
		_add_notification_to_active(notification_data)
	else:
		_add_to_pending_queue(notification_data)


## Clear all notifications immediately
func clear_all() -> void:
	# Clear active notifications
	for notification in _active_notifications:
		if is_instance_valid(notification.item):
			notification.item.queue_free()

	_active_notifications.clear()

	# Clear pending notifications
	_pending_notifications.clear()


## Handle EventBus notification_requested signal
func _on_notification_requested(
	title: String, description: String, icon: Texture2D, priority: int
) -> void:
	show_notification(title, description, icon, priority)


## Add notification to active display
func _add_notification_to_active(data: Dictionary) -> void:
	var notification_item = _create_notification_item(data)
	vbox_container.add_child(notification_item)

	# Create timer for auto-removal
	var timer := get_tree().create_timer(NOTIFICATION_DURATION)
	timer.timeout.connect(_on_notification_timer.bind(notification_item))

	# Track active notification
	_active_notifications.append(
		{"item": notification_item, "priority": data.priority, "timer": timer}
	)

	# Play slide-in animation
	_play_slide_in_animation(notification_item)


## Add notification to pending priority queue
func _add_to_pending_queue(data: Dictionary) -> void:
	_pending_notifications.append(data)

	# Sort by priority (highest first)
	_pending_notifications.sort_custom(func(a, b): return a.priority > b.priority)

	# Check if we should replace a low-priority active notification
	if _active_notifications.size() >= MAX_NOTIFICATIONS:
		_try_replace_low_priority_notification()


## Try to replace lowest priority active notification
func _try_replace_low_priority_notification() -> void:
	if _pending_notifications.is_empty():
		return

	# Find lowest priority active notification
	var lowest_priority_index := 0
	var lowest_priority: int = _active_notifications[0].priority

	for i in range(1, _active_notifications.size()):
		if _active_notifications[i].priority < lowest_priority:
			lowest_priority = _active_notifications[i].priority
			lowest_priority_index = i

	# Check if pending has higher priority
	var pending_data = _pending_notifications[0]
	if pending_data.priority > lowest_priority:
		# Remove the low priority notification
		var old_notification = _active_notifications[lowest_priority_index]
		if is_instance_valid(old_notification.item):
			old_notification.item.queue_free()

		if is_instance_valid(old_notification.timer):
			old_notification.timer.disconnect("timeout", _on_notification_timer)

		_active_notifications.remove_at(lowest_priority_index)

		# Add the high priority notification
		_pending_notifications.pop_front()
		_add_notification_to_active(pending_data)


## Create a notification item node
func _create_notification_item(data: Dictionary) -> Control:
	var item = NotificationItemScene.instantiate()

	var icon = item.get_node("HBoxContainer/Icon")
	var title = item.get_node("HBoxContainer/VBoxContainer/Title")
	var description = item.get_node("HBoxContainer/VBoxContainer/Description")

	icon.texture = data.icon
	title.text = data.title
	description.text = data.description

	return item


## Handle notification timer expiration
func _on_notification_timer(item: Control) -> void:
	if not is_instance_valid(item):
		return

	# Remove from active notifications
	for i in range(_active_notifications.size() - 1, -1, -1):
		if _active_notifications[i].item == item:
			_active_notifications.remove_at(i)
			break

	# Play slide-out animation before removing
	_play_slide_out_animation(item)

	# Wait for animation then remove
	await get_tree().create_timer(0.3).timeout  # Animation duration

	if is_instance_valid(item):
		item.queue_free()

	# Check if there are pending notifications
	_process_pending_queue()


## Process pending notifications queue
func _process_pending_queue() -> void:
	while (
		not _pending_notifications.is_empty() and _active_notifications.size() < MAX_NOTIFICATIONS
	):
		var data = _pending_notifications.pop_front()
		_add_notification_to_active(data)


## Play slide-in animation for notification
func _play_slide_in_animation(item: Control) -> void:
	# Start from off-screen right
	item.modulate.a = 0.0
	item.position.x += 200

	# Create simple tween animation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "modulate:a", 1.0, 0.3)
	tween.tween_property(item, "position:x", item.position.x - 200, 0.3)


## Play slide-out animation for notification
func _play_slide_out_animation(item: Control) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "modulate:a", 0.0, 0.3)
	tween.tween_property(item, "position:x", item.position.x + 200, 0.3)
