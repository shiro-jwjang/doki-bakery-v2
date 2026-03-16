extends GutTest

## Test Suite for NotificationArea
## Tests that notifications appear correctly with animations and queue management
## SNA-141: 알림 팝업 (NotificationArea) — TDD

const NotificationArea = preload("res://scripts/ui/notification_area.gd")

var notification_area: NotificationArea
var test_icon: Texture2D


func before_each() -> void:
	# Load a real texture for testing
	test_icon = preload("res://assets/placeholders/bread_white.png")


func after_each() -> void:
	if notification_area != null and is_instance_valid(notification_area):
		notification_area.queue_free()
		notification_area = null


## Helper: Check if scene loading is possible (requires display)
func _can_load_scenes() -> bool:
	return DisplayServer.get_name() != "headless"


## Helper: Create notification area instance
func _create_notification_area() -> void:
	var NotificationAreaScene = preload("res://scenes/ui/notification_area.tscn")
	notification_area = NotificationAreaScene.instantiate()
	add_child(notification_area)
	await wait_physics_frames(2)


## Test: NotificationArea scene exists and loads correctly
func test_notification_area_scene_exists() -> void:
	var scene_path = "res://scenes/ui/notification_area.tscn"
	assert_file_exists(scene_path)

	var scene = load(scene_path)
	assert_not_null(scene, "NotificationArea scene must be loadable")


## Test: NotificationArea has VBoxContainer for stacking items
func test_notification_area_has_vbox_container() -> void:
	_create_notification_area()

	var vbox = notification_area.get_node_or_null("VBoxContainer")
	assert_not_null(vbox, "NotificationArea must have VBoxContainer")


## Test: NotificationArea positioned at top-right of HUD
func test_notification_area_positioned_at_top_right() -> void:
	_create_notification_area()

	# Check anchors for top-right positioning
	# anchor_left = 1.0, anchor_top = 0.0 means top-right corner
	assert_eq(notification_area.anchor_left, 1.0, "Should anchor to right")
	assert_eq(notification_area.anchor_top, 0.0, "Should anchor to top")
	assert_eq(notification_area.anchor_right, 1.0, "Should anchor to right")
	assert_eq(notification_area.anchor_bottom, 0.0, "Should anchor to top")


## Test: show_notification creates a NotificationItem
func test_show_notification_creates_item() -> void:
	_create_notification_area()

	notification_area.show_notification("Test Title", "Test Description", test_icon, 0)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	assert_eq(vbox.get_child_count(), 1, "Should have one notification item")


## Test: NotificationItem has correct structure (icon, title, description)
func test_notification_item_has_correct_structure() -> void:
	_create_notification_area()

	notification_area.show_notification("Test Title", "Test Description", test_icon, 0)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	var item = vbox.get_child(0)

	var icon = item.get_node_or_null("HBoxContainer/Icon")
	var title = item.get_node_or_null("HBoxContainer/VBoxContainer/Title")
	var description = item.get_node_or_null("HBoxContainer/VBoxContainer/Description")

	assert_not_null(icon, "Item must have Icon node")
	assert_not_null(title, "Item must have Title node")
	assert_not_null(description, "Item must have Description node")


## Test: NotificationItem displays correct text
func test_notification_item_displays_correct_text() -> void:
	_create_notification_area()

	notification_area.show_notification("Test Title", "Test Description", test_icon, 0)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	var item = vbox.get_child(0)
	var title = item.get_node("HBoxContainer/VBoxContainer/Title")
	var description = item.get_node("HBoxContainer/VBoxContainer/Description")

	assert_eq(title.text, "Test Title", "Title should match")
	assert_eq(description.text, "Test Description", "Description should match")


## Test: Multiple notifications stack vertically
func test_multiple_notifications_stack_vertically() -> void:
	_create_notification_area()

	notification_area.show_notification("Title1", "Desc1", test_icon, 0)
	await wait_physics_frames(1)

	notification_area.show_notification("Title2", "Desc2", test_icon, 0)
	await wait_physics_frames(1)

	notification_area.show_notification("Title3", "Desc3", test_icon, 0)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	assert_eq(vbox.get_child_count(), 3, "Should have three notifications")


## Test: Maximum 3 notifications displayed at once
func test_max_three_notifications_displayed() -> void:
	_create_notification_area()

	# Add 5 notifications
	for i in range(5):
		notification_area.show_notification("Title" + str(i), "Desc" + str(i), test_icon, 0)
		await wait_physics_frames(1)

	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	assert_eq(vbox.get_child_count(), 3, "Should have maximum 3 notifications")


## Test: Higher priority notifications replace lower priority ones
func test_priority_queue_replaces_low_priority() -> void:
	_create_notification_area()

	# Add 3 low priority notifications
	for i in range(3):
		notification_area.show_notification("Low" + str(i), "Desc", test_icon, 0)
		await wait_physics_frames(1)

	# Add high priority notification
	notification_area.show_notification("High Priority", "Important", test_icon, 10)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	assert_eq(vbox.get_child_count(), 3, "Should still have 3 notifications")

	# Check if high priority notification is present
	var found_high := false
	for item in vbox.get_children():
		var title = item.get_node("HBoxContainer/VBoxContainer/Title")
		if title.text == "High Priority":
			found_high = true
			break

	assert_true(found_high, "High priority notification should be displayed")


## Test: clear_all removes all notifications
func test_clear_all_removes_notifications() -> void:
	_create_notification_area()

	notification_area.show_notification("Title1", "Desc1", test_icon, 0)
	notification_area.show_notification("Title2", "Desc2", test_icon, 0)
	await wait_physics_frames(2)

	notification_area.clear_all()
	await wait_physics_frames(1)

	var vbox = notification_area.get_node("VBoxContainer")
	assert_eq(vbox.get_child_count(), 0, "Should have no notifications after clear")


## Test: NotificationItem auto-removes after delay (animation duration)
func test_notification_auto_removes_after_delay() -> void:
	_create_notification_area()

	notification_area.show_notification("Title", "Desc", test_icon, 0)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	var initial_count = vbox.get_child_count()
	assert_eq(initial_count, 1, "Should have one notification initially")

	# Wait for animation duration (3 seconds) + buffer
	await wait_seconds(3.5)

	assert_eq(vbox.get_child_count(), 0, "Notification should be removed after animation")


## Test: EventBus notification_requested signal triggers notification
func test_eventbus_signal_triggers_notification() -> void:
	_create_notification_area()

	# Emit EventBus signal
	EventBusAutoload.notification_requested.emit("Event Title", "Event Description", test_icon, 0)
	await wait_physics_frames(2)

	var vbox = notification_area.get_node("VBoxContainer")
	assert_eq(vbox.get_child_count(), 1, "Should have one notification from EventBus")


## Test: NotificationArea has AnimationPlayer
func test_notification_area_has_animation_player() -> void:
	_create_notification_area()

	var anim_player = notification_area.get_node_or_null("AnimationPlayer")
	assert_not_null(anim_player, "NotificationArea must have AnimationPlayer")
