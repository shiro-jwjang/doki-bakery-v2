extends GutTest

## Test Suite for HUD Experience Bar
## Tests that the HUD experience bar updates correctly when XP changes
## SNA-92: HUD 경험치 바 실시간 반영
##
## NOTE: Scene tests require GUI mode. Run with DISPLAY=:99

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

var hud: Node
var exp_bar: ProgressBar


func before_each() -> void:
	# Reset GameManager state
	GameManager.level = 1
	GameManager.experience = 0


func after_each() -> void:
	if hud != null and is_instance_valid(hud):
		hud.queue_free()
		hud = null


## Test HUD scene can be instantiated
func test_hud_scene_instantiation() -> void:
	# Skip in pure headless mode (no display)
	if not _can_load_scenes():
		pending("HUD scene tests require GUI mode (DISPLAY=:99)")
		return

	hud = HUD_SCENE.instantiate()
	assert_not_null(hud, "HUD scene should instantiate")

	add_child(hud)
	await wait_physics_frames(2)  # Wait with timeout

	exp_bar = hud.get_node_or_null("Control/ExpBar")
	assert_not_null(exp_bar, "ExpBar node must exist in HUD")


## Test initial state
func test_initial_state() -> void:
	if not _can_load_scenes():
		pending("HUD scene tests require GUI mode")
		return

	hud = HUD_SCENE.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	exp_bar = hud.get_node_or_null("Control/ExpBar")
	if exp_bar == null:
		pending("ExpBar not found")
		return

	assert_eq(exp_bar.value, 0.0, "Initial XP should be 0")
	var next_level_data = DataManager.get_level(2)
	var expected_max = float(next_level_data.required_xp) if next_level_data else 100.0
	assert_eq(exp_bar.max_value, expected_max, "Initial max XP should match level 2 requirement")


## Test that XP bar updates when GameManager.add_xp is called
func test_xp_bar_updates_with_game_manager() -> void:
	if not _can_load_scenes():
		pending("HUD scene tests require GUI mode")
		return

	hud = HUD_SCENE.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	exp_bar = hud.get_node_or_null("Control/ExpBar")
	if exp_bar == null:
		pending("ExpBar not found")
		return

	# Add XP through GameManager
	GameManager.add_xp(30)
	await wait_physics_frames(3)

	assert_eq(exp_bar.value, 30.0, "XP bar should show 30")


## Test level up flow via GameManager
func test_level_up_via_game_manager() -> void:
	if not _can_load_scenes():
		pending("HUD scene tests require GUI mode")
		return

	hud = HUD_SCENE.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	exp_bar = hud.get_node_or_null("Control/ExpBar")
	if exp_bar == null:
		pending("ExpBar not found")
		return

	# Reset to level 1
	GameManager.level = 1
	GameManager.experience = 0

	# Add enough XP to level up (100 XP)
	GameManager.add_xp(100)
	await wait_physics_frames(3)

	# After level up:
	# - Level should be 2
	# - Experience should be 0 (100 - 100 = 0)
	assert_eq(GameManager.level, 2, "Should level up to level 2")
	assert_eq(exp_bar.value, 0.0, "XP should reset to 0 after level up")


## Helper: Check if scene loading is possible (requires display)
func _can_load_scenes() -> bool:
	# Check if we are not running in headless mode
	return DisplayServer.get_name() != "headless"
