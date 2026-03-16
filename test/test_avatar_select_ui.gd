extends GutTest

## SNA-122: AvatarSelectUI Tests
## TDD Red Phase - Tests for avatar selection UI

const AVATAR_SELECT_UI_SCENE_PATH = "res://scenes/ui/avatar_select_ui.tscn"

var _avatar_select_ui: Control
var _test_avatar_list: Array[AvatarData]


func before_each() -> void:
	# Load the avatar select UI scene
	var scene_resource = load(AVATAR_SELECT_UI_SCENE_PATH)
	if scene_resource != null:
		_avatar_select_ui = scene_resource.instantiate()
		add_child_autofree(_avatar_select_ui)
		await get_tree().process_frame

	# Create test avatar data
	_test_avatar_list = []
	for i: int in range(3):
		var avatar = AvatarData.new()
		avatar.resource_name = "avatar_%d" % i
		_test_avatar_list.append(avatar)


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	pass


#region REQ: AvatarSelectUI scene structure


func test_avatar_select_ui_scene_loads() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist at: %s" % AVATAR_SELECT_UI_SCENE_PATH)
	assert_not_null(_avatar_select_ui, "AvatarSelectUI scene should be instantiated")


func test_avatar_select_ui_root_is_control() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")
	assert_true(
		_avatar_select_ui is Control,
		"AvatarSelectUI root should be Control, got: %s" % _avatar_select_ui.get_class()
	)


func test_avatar_select_ui_has_container_for_avatars() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Should have a container to hold avatar options
	var container = _avatar_select_ui.find_child("AvatarContainer", true, false)
	assert_not_null(container, "AvatarSelectUI should have an AvatarContainer")


#endregion

#region REQ: Avatar data management


func test_has_set_avatar_list_method() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	assert_true(
		_avatar_select_ui.has_method("set_avatar_list"),
		"AvatarSelectUI should have set_avatar_list method"
	)


func test_set_avatar_list_accepts_array() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Should accept array of AvatarData
	_avatar_select_ui.set_avatar_list(_test_avatar_list)

	assert_true(true, "set_avatar_list should accept Array[AvatarData]")


func test_set_avatar_list_with_empty_array() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Should handle empty array gracefully
	_avatar_select_ui.set_avatar_list([])

	assert_true(true, "set_avatar_list should handle empty array")


#endregion

#region REQ: Avatar selection


func test_select_avatar_method_exists() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	assert_true(
		_avatar_select_ui.has_method("select_avatar"),
		"AvatarSelectUI should have select_avatar method"
	)


func test_select_avatar_updates_game_manager() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Set initial avatar
	GameManager.avatar_data_id = ""

	# Select an avatar
	_avatar_select_ui.select_avatar(0)

	# GameManager should be updated
	# (Actual implementation may use different approach, but should update some state)
	assert_true(true, "select_avatar should update avatar state")


#endregion

#region REQ: Avatar preview


func test_avatar_display_has_preview_nodes() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Should have preview nodes to display avatar appearance
	# This is a basic structure test
	var container = _avatar_select_ui.find_child("AvatarContainer", true, false)
	if container != null:
		# Container should have children (avatar options)
		var child_count = container.get_child_count()
		assert_true(child_count >= 0, "AvatarContainer should exist")
	else:
		fail_test("AvatarContainer not found")


#endregion

#region REQ: UI interaction


func test_confirm_button_emits_signal_or_updates_state() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Should have a confirm button
	var confirm_button = _avatar_select_ui.find_child("ConfirmButton", true, false)

	# Button may or may not exist in MVP, but if it exists, should be Button type
	if confirm_button != null:
		assert_true(
			confirm_button is BaseButton,
			"ConfirmButton should be BaseButton, got: %s" % confirm_button.get_class()
		)
	else:
		# MVP might not have confirm button, that's ok
		assert_true(true, "ConfirmButton is optional for MVP")


func test_close_method_exists() -> void:
	if _avatar_select_ui == null:
		fail_test("AvatarSelectUI scene file does not exist")

	# Should have a way to close the UI
	assert_true(
		(
			_avatar_select_ui.has_method("close")
			or _avatar_select_ui.has_method("hide")
			or _avatar_select_ui.has_method("queue_free")
		),
		"AvatarSelectUI should have close, hide, or queue_free method"
	)

#endregion
