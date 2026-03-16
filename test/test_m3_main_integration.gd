extends GutTest

## Integration Test Suite for Main Scene with M3 Components
## SNA-168: 메인 씬 통합 — CustomerView/EmoticonView/NotificationArea 배치 및 연동
##
## This test verifies that all M3 components are properly integrated in the main scene
## and can interact through the EventBusAutoload.

const MAIN_SCENE := "res://scenes/main.tscn"

var main_scene: Node2D
var event_bus: Node


func before_each() -> void:
	# Load main scene
	var scene = load(MAIN_SCENE)
	if scene == null:
		fail_test("Main scene not found at %s" % MAIN_SCENE)
		return

	main_scene = scene.instantiate()
	add_child_autoqfree(main_scene)
	await wait_physics_frames(2)
	# Additional wait for @onready variables and children to be initialized
	await wait_seconds(0.5)

	# Get EventBus reference
	event_bus = get_node_or_null("/root/EventBus")
	if event_bus == null:
		fail_test("EventBus not found")


## ==================== SCENE STRUCTURE TESTS ====================


## Test that main scene can be loaded
func test_main_scene_loads() -> void:
	var scene = load(MAIN_SCENE)
	assert_not_null(scene, "Main scene should exist at %s" % MAIN_SCENE)


## Test that main scene has a script attached
func test_main_scene_has_script() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	assert_not_null(main_scene.get_script(), "Main scene should have a script")


## ==================== CUSTOMER VIEW INTEGRATION TESTS ====================


## Test that CustomerView exists in the scene
func test_customer_view_exists() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	# CustomerView gets renamed to "Customer_main_customer_001" after setup
	# Find by name pattern instead
	var customer_view = null
	for child in main_scene.get_children():
		if child.name.begins_with("Customer_"):
			customer_view = child
			break

	assert_not_null(customer_view, "CustomerView should exist in main scene")


## Test that CustomerView is properly set up
func test_customer_view_is_setup() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	# Find customer view by name pattern
	var customer_view = null
	for child in main_scene.get_children():
		if child.name.begins_with("Customer_"):
			customer_view = child
			break

	if customer_view == null:
		fail_test("CustomerView not found")
		return

	assert_true(customer_view.has_method("setup"), "CustomerView should have setup method")


## ==================== EMOTICON VIEW INTEGRATION TESTS ====================


## Test that EmoticonView exists in the scene
func test_emoticon_view_exists() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	var emoticon_view = main_scene.find_child("EmoticonView", true, false)
	assert_not_null(emoticon_view, "EmoticonView should exist in main scene")


## Test that EmoticonView has character_id property
func test_emoticon_view_has_character_id() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	var emoticon_view = main_scene.find_child("EmoticonView", true, false)
	if emoticon_view == null:
		fail_test("EmoticonView not found")
		return

	assert_true("character_id" in emoticon_view, "EmoticonView should have character_id property")


## ==================== NOTIFICATION AREA INTEGRATION TESTS ====================


## Test that NotificationArea exists in the scene
func test_notification_area_exists() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	var notification_area = main_scene.find_child("NotificationArea", true, false)
	assert_not_null(notification_area, "NotificationArea should exist in main scene")


## Test that NotificationArea has show_notification method
func test_notification_area_has_show_method() -> void:
	if main_scene == null:
		fail_test("Main scene not loaded")
		return

	var notification_area = main_scene.find_child("NotificationArea", true, false)
	if notification_area == null:
		fail_test("NotificationArea not found")
		return

	assert_true(
		notification_area.has_method("show_notification"),
		"NotificationArea should have show_notification method"
	)


## ==================== EVENT BUS INTEGRATION TESTS ====================


## Test that EventBus has required signals
func test_event_bus_has_emotion_triggered() -> void:
	if event_bus == null:
		fail_test("EventBus not found")
		return

	assert_has_signal(
		event_bus, "emotion_triggered", "EventBus should have emotion_triggered signal"
	)


## Test that EventBus has notification_requested signal
func test_event_bus_has_notification_requested() -> void:
	if event_bus == null:
		fail_test("EventBus not found")
		return

	assert_has_signal(
		event_bus, "notification_requested", "EventBus should have notification_requested signal"
	)


## ==================== INTEGRATION FLOW TESTS ====================


## Test customer arrival → emoticon → notification flow
func test_customer_emoticon_notification_flow() -> void:
	if main_scene == null or event_bus == null:
		fail_test("Main scene or EventBus not loaded")
		return

	# Find customer view by name pattern (CustomerView gets renamed after setup)
	var customer_view = null
	for child in main_scene.get_children():
		if child.name.begins_with("Customer_"):
			customer_view = child
			break

	var emoticon_view = main_scene.find_child("EmoticonView", true, false)
	var notification_area = main_scene.find_child("NotificationArea", true, false)

	if customer_view == null or emoticon_view == null or notification_area == null:
		fail_test("M3 components not found in main scene")
		return

	# Setup customer with ID
	customer_view.setup("test_customer_001")

	# Setup emoticon view character_id to match
	emoticon_view.character_id = "test_customer_001"

	# Trigger emotion (simulating customer interaction)
	event_bus.emotion_triggered.emit("test_customer_001", "heart")

	await wait_physics_frames(1)

	# Verify emoticon view is showing emoticon
	assert_true(
		emoticon_view.is_showing(),
		"EmoticonView should be showing emoticon after emotion_triggered"
	)

	# Verify emoticon view is showing emoticon
	assert_true(
		emoticon_view.is_showing(),
		"EmoticonView should be showing emoticon after emotion_triggered"
	)

	# Trigger notification
	event_bus.notification_requested.emit("Test Title", "Test Description", null, 0)

	await wait_physics_frames(1)

	# Verify notification was shown (we can check if NotificationArea has children)
	assert_true(
		notification_area.get_child_count() > 0,
		"NotificationArea should have at least one notification"
	)


## Test multiple emoticons in sequence
func test_multiple_emoticon_sequence() -> void:
	if main_scene == null or event_bus == null:
		fail_test("Main scene or EventBus not loaded")
		return

	var emoticon_view = main_scene.find_child("EmoticonView", true, false)
	if emoticon_view == null:
		fail_test("EmoticonView not found")
		return

	emoticon_view.character_id = "test_customer_002"

	var emotions := ["heart", "star", "yummy"]

	for emotion in emotions:
		event_bus.emotion_triggered.emit("test_customer_002", emotion)
		await wait_physics_frames(1)

		assert_true(emoticon_view.is_showing(), "EmoticonView should be showing %s" % emotion)

		# Wait for emoticon to hide
		await wait_for_signal(emoticon_view.emoticon_hidden, 3.0)

	# Verify final state
	assert_false(emoticon_view.is_showing(), "EmoticonView should be hidden after all emotions")
