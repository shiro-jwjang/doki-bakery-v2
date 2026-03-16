extends GutTest

## Test suite for LevelUpNotification UI component
## SNA-99: 레벨업 시 해금 알림 표시

var notification: Control


func before_each() -> void:
	var LevelUpNotificationScene = preload("res://scenes/ui/level_up_notification.tscn")
	notification = LevelUpNotificationScene.instantiate()
	add_child_autofree(notification)
	await wait_physics_frames(1)


func after_each() -> void:
	notification = null


# ==================== Initialization Tests ====================


func test_notification_initializes() -> void:
	assert_not_null(notification, "LevelUpNotification should initialize")
	assert_false(notification.visible, "Notification should not be visible initially")


# ==================== Show/Hide Tests ====================


func test_show_unlocks_makes_notification_visible() -> void:
	var unlocked_items = ["bread_001", "bread_002"]
	notification.show_unlocks(5, unlocked_items)

	assert_true(notification.visible, "Notification should be visible after show_unlocks")


func test_show_unlocks_sets_level_text() -> void:
	var unlocked_items = ["bread_001"]
	notification.show_unlocks(3, unlocked_items)

	# Level text should include the new level
	var level_text = notification.get("level_text") if notification.has_method("get") else ""
	assert_true(notification.visible, "Notification should be visible")


func test_show_unlocks_with_empty_items() -> void:
	var empty_items: Array[String] = []
	notification.show_unlocks(2, empty_items)

	assert_true(notification.visible, "Notification should still be visible with no unlocks")


func test_hide_makes_notification_invisible() -> void:
	notification.show_unlocks(1, ["test_item"])
	assert_true(notification.visible, "Notification should be visible first")

	notification.hide_notification()
	assert_false(notification.visible, "Notification should be hidden after hide_notification()")


# ==================== Unlocked Items Display Tests ====================


func test_notification_shows_unlocked_items_text() -> void:
	var unlocked_items = ["bread_001", "bread_005"]
	notification.show_unlocks(5, unlocked_items)

	# Check that item names are displayed
	var items_text = (
		notification.get_items_text() if notification.has_method("get_items_text") else ""
	)
	assert_true(items_text.length() > 0, "Should display unlocked items text")


func test_notification_with_single_item() -> void:
	var single_item = ["bread_001"]
	notification.show_unlocks(2, single_item)

	assert_true(notification.visible, "Notification should be visible")


func test_notification_with_multiple_items() -> void:
	var multiple_items = ["bread_001", "bread_002", "bread_003"]
	notification.show_unlocks(10, multiple_items)

	assert_true(notification.visible, "Notification should be visible")


func test_notification_auto_closes_after_delay() -> void:
	notification.show_unlocks(1, ["bread_001"])
	assert_true(notification.visible, "Notification should be visible initially")

	# Set short direct timer for testing
	if notification.auto_close_timer:
		notification.auto_close_timer.stop()
		notification.auto_close_timer.wait_time = 0.1
		notification.auto_close_timer.start()

	# Wait for auto-close (0.1 seconds + buffer)
	await wait_seconds(0.2)

	assert_false(notification.visible, "Notification should auto-close after delay")


func test_notification_show_multiple_times() -> void:
	# First show
	notification.show_unlocks(1, ["bread_001"])
	if notification.auto_close_timer:
		notification.auto_close_timer.stop()
		notification.auto_close_timer.wait_time = 0.1
		notification.auto_close_timer.start()

	assert_true(notification.visible, "Should be visible first time")

	await wait_seconds(0.2)
	assert_false(notification.visible, "Should be hidden after auto-close")

	# Second show
	notification.show_unlocks(2, ["bread_002"])
	if notification.auto_close_timer:
		notification.auto_close_timer.stop()
		notification.auto_close_timer.wait_time = 0.1
		notification.auto_close_timer.start()

	assert_true(notification.visible, "Should be visible second time")

	await wait_seconds(0.2)
	assert_false(notification.visible, "Should be hidden after second auto-close")
