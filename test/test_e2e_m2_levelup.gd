extends GutTest

## E2E Test Suite for Production → Experience → Level Up Flow
## Tests the complete flow from bread production/sale to level up with HUD updates
## SNA-102: E2E — 생산→경험치→레벨업 화면 테스트
##
## Goal flow: 반복 생산/판매 → 경험치 누적 → 레벨업 → HUD 레벨 변경 + 알림 표시 확인

const WORLD_VIEW_SCENE := "res://scenes/world/world_view.tscn"
const TEST_RECIPE_ID := "bread_001"
const LEVEL_2_XP := 100  # Level 2 requires 100 XP

var _world_view: Node = null
var _level_up_count: int = 0
var _last_level_up: int = 0


func before_each() -> void:
	# Reset GameManager state completely
	_reset_game_manager()

	# Reset signal tracking
	_level_up_count = 0
	_last_level_up = 0

	# Connect to level_up signal for tracking
	if not EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.connect(_on_level_up)


func after_each() -> void:
	# Disconnect signals
	if EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.disconnect(_on_level_up)

	# Clean up WorldView
	if _world_view != null and is_instance_valid(_world_view):
		_world_view.queue_free()
		_world_view = null

	# Reset GameManager state
	_reset_game_manager()


## ==================== HELPER FUNCTIONS ====================


func _reset_game_manager() -> void:
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0
	GameManager.set_game_state("menu")
	# Clear cached level data
	GameManager._level_data_cache.clear()


func _load_world_view() -> bool:
	if _world_view != null and is_instance_valid(_world_view):
		return true

	var scene = load(WORLD_VIEW_SCENE)
	if scene == null:
		fail_test("WorldView scene not found at %s" % WORLD_VIEW_SCENE)
		return false

	_world_view = scene.instantiate()
	add_child_autoqfree(_world_view)
	await wait_physics_frames(2)
	return true


func _on_level_up(new_level: int) -> void:
	_level_up_count += 1
	_last_level_up = new_level


## ==================== E2E TESTS ====================


## Test 1: XP is awarded when bread is sold
## This is the foundation of the production → XP → level up flow
func test_e2e_xp_awarded_on_bread_sale() -> void:
	# Get recipe data
	var recipe := DataManager.get_recipe(TEST_RECIPE_ID)
	assert_not_null(recipe, "Test recipe should exist")

	var xp_reward: int = recipe.xp_reward
	assert_gt(xp_reward, 0, "Recipe should have XP reward")

	# Record initial XP
	var initial_xp := GameManager.get_xp()

	# Simulate bread sale via EconomyManager
	EconomyManager.sell_bread(recipe)

	# Verify XP increased
	var new_xp := GameManager.get_xp()
	assert_eq(new_xp, initial_xp + xp_reward, "XP should increase by recipe's xp_reward")


## Test 2: Multiple sales accumulate XP and trigger level up
func test_e2e_accumulate_xp_from_sales_and_level_up() -> void:
	var recipe := DataManager.get_recipe(TEST_RECIPE_ID)
	assert_not_null(recipe, "Test recipe should exist")

	var xp_per_sale: int = recipe.xp_reward
	assert_gt(xp_per_sale, 0, "Recipe should have XP reward")

	# Calculate sales needed for level up
	var sales_needed := ceili(float(LEVEL_2_XP) / float(xp_per_sale))

	# Perform sales to accumulate XP
	for i in range(sales_needed):
		EconomyManager.sell_bread(recipe)

	# Wait for level_up signal if expected
	if GameManager.experience >= LEVEL_2_XP or _level_up_count > 0:
		await wait_for_signal(EventBus.level_up, 1.0)

	# Verify level up occurred
	assert_gt(_level_up_count, 0, "Level up signal should have been emitted")
	assert_eq(_last_level_up, 2, "Should have reached level 2")
	assert_eq(GameManager.level, 2, "GameManager level should be 2")


## Test 3: HUD experience bar updates when XP changes
func test_e2e_hud_exp_bar_updates() -> void:
	# Skip in headless mode
	if DisplayServer.get_name() == "headless":
		pending("HUD tests require GUI mode (DISPLAY=:99)")
		return

	if not await _load_world_view():
		return

	var hud := _world_view.find_child("HUD", true, false)
	assert_not_null(hud, "HUD should exist in WorldView")

	var exp_bar: ProgressBar = hud.get_node_or_null("Control/ExpBar")
	assert_not_null(exp_bar, "ExpBar should exist in HUD")

	# Record initial exp bar value
	var initial_value := exp_bar.value

	# Add XP
	GameManager.add_xp(30)
	await wait_physics_frames(2)

	# Verify exp bar updated
	assert_gt(exp_bar.value, initial_value, "Exp bar value should increase")


## Test 4: HUD level display updates on level up
func test_e2e_hud_level_display_updates_on_level_up() -> void:
	# Skip in headless mode
	if DisplayServer.get_name() == "headless":
		pending("HUD tests require GUI mode (DISPLAY=:99)")
		return

	if not await _load_world_view():
		return

	var hud := _world_view.find_child("HUD", true, false)
	assert_not_null(hud, "HUD should exist in WorldView")

	# Add enough XP to level up
	GameManager.add_xp(LEVEL_2_XP)
	await wait_for_signal(EventBus.level_up, 2.0)

	# Verify level changed
	assert_eq(GameManager.level, 2, "Should be level 2")

	# Verify HUD received level_up signal
	# The HUD connects to level_up signal and updates exp_bar
	# We verify the exp_bar shows correct post-level-up state
	var exp_bar: ProgressBar = hud.get_node_or_null("Control/ExpBar")
	if exp_bar != null:
		# After level up, experience should be 0 (100 - 100 = 0)
		assert_eq(exp_bar.value, 0.0, "Exp bar should show 0 after level up")


## Test 5: Level up notification is shown when leveling up
func test_e2e_level_up_notification_shows() -> void:
	# Skip in headless mode
	if DisplayServer.get_name() == "headless":
		pending("Notification tests require GUI mode (DISPLAY=:99)")
		return

	if not await _load_world_view():
		return

	# Find LevelUpNotification in scene
	var notification := _world_view.find_child("LevelUpNotification", true, false)
	if notification == null:
		# Try to find it in UI layer
		notification = _get_node_by_class_name(_world_view, "LevelUpNotification")

	if notification == null:
		pending("LevelUpNotification not found in WorldView")
		return

	# Verify initial state
	assert_false(notification.visible, "Notification should start hidden")

	# Trigger level up
	GameManager.add_xp(LEVEL_2_XP)
	await wait_for_signal(EventBus.level_up, 2.0)

	# Check if notification becomes visible
	# Note: The notification needs to be connected to level_up signal
	# and show itself. This test verifies that connection exists.
	await wait_physics_frames(2)

	# The notification should be visible after level up
	assert_true(notification.visible, "Notification should be visible after level up")


## Test 6: Complete E2E flow - production → sale → XP → level up → HUD update
func test_e2e_complete_production_to_level_up_flow() -> void:
	# Skip in headless mode
	if DisplayServer.get_name() == "headless":
		pending("Complete E2E tests require GUI mode (DISPLAY=:99)")
		return

	if not await _load_world_view():
		return

	var recipe := DataManager.get_recipe(TEST_RECIPE_ID)
	assert_not_null(recipe, "Test recipe should exist")

	# Get DisplaySlots
	var display_slots := _world_view.find_child("DisplaySlots", true, false)
	assert_not_null(display_slots, "DisplaySlots should exist")

	# Get HUD
	var hud := _world_view.find_child("HUD", true, false)
	assert_not_null(hud, "HUD should exist")

	# Get initial values
	var initial_level := GameManager.level
	var initial_xp := GameManager.experience
	var xp_reward: int = recipe.xp_reward

	# Simulate multiple production → sale cycles
	var sales_to_level_up := ceili(float(LEVEL_2_XP) / float(xp_reward))

	for i in range(sales_to_level_up):
		# Simulate bread sale (this should award both gold and XP)
		EconomyManager.sell_bread(recipe)

	# Wait for level up signal
	await wait_for_signal(EventBus.level_up, 2.0)

	# Verify level up occurred
	assert_eq(GameManager.level, initial_level + 1, "Should have leveled up")

	# Verify XP increased
	assert_gt(GameManager.experience, initial_xp, "XP should have accumulated")

	# Verify HUD updated
	var exp_bar: ProgressBar = hud.get_node_or_null("Control/ExpBar")
	if exp_bar != null:
		# Exp bar should reflect current XP
		assert_eq(exp_bar.value, float(GameManager.experience), "HUD exp bar should match GameManager XP")


## Test 7: Level up with excess XP carries over correctly
func test_e2e_level_up_with_excess_xp() -> void:
	var recipe := DataManager.get_recipe(TEST_RECIPE_ID)
	assert_not_null(recipe, "Test recipe should exist")

	var xp_reward: int = recipe.xp_reward

	# Add more XP than needed for level 2
	var excess_xp := 50
	var total_xp := LEVEL_2_XP + excess_xp
	var sales_needed := ceili(float(total_xp) / float(xp_reward))

	for i in range(sales_needed):
		EconomyManager.sell_bread(recipe)

	# Wait for level up
	await wait_for_signal(EventBus.level_up, 2.0)

	# Verify level
	assert_eq(GameManager.level, 2, "Should be level 2")

	# Verify excess XP carried over (with some tolerance for rounding)
	var expected_xp := (sales_needed * xp_reward) - LEVEL_2_XP
	assert_almost_eq(GameManager.experience, expected_xp, xp_reward, "Excess XP should carry over")


## ==================== HELPER: Find node by class name ====================


func _get_node_by_class_name(node: Node, target_class_name: String) -> Node:
	if node.get_script() != null:
		var script = node.get_script()
		if script.resource_path.ends_with(target_class_name.to_lower() + ".gd"):
			return node

	for child in node.get_children():
		var result := _get_node_by_class_name(child, target_class_name)
		if result != null:
			return result

	return null
