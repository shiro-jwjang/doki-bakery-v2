extends GutTest

## Test Suite for HUD Experience Bar
## Tests that the HUD experience bar updates correctly when XP changes
## SNA-92: HUD 경험치 바 실시간 반영

var hud: Node
var exp_bar: ProgressBar


func before_each() -> void:
	# Reset GameManager state
	GameManager.level = 1
	GameManager.experience = 0

	# Create HUD scene
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)

	# Wait for HUD to be fully ready
	await hud.ready
	await wait_physics_frames(2)

	# Get exp_bar reference
	exp_bar = hud.get_node("Control/ExpBar")
	assert_not_null(exp_bar, "ExpBar node must exist in HUD")


func after_each() -> void:
	if hud != null and is_inside_tree():
		hud.queue_free()
		await wait_physics_frames(1)


## Test HUD scene can be instantiated
func test_hud_scene_instantiation() -> void:
	assert_not_null(hud, "HUD should be instantiated")
	assert_not_null(exp_bar, "ExpBar should exist")


## Test initial state
func test_initial_state() -> void:
	assert_eq(exp_bar.value, 0.0, "Initial XP should be 0")
	assert_eq(exp_bar.max_value, 0.0, "Initial max XP should be 0 (level 1 requirement)")


## Test that XP bar updates when GameManager.add_xp is called
func test_xp_bar_updates_with_game_manager() -> void:
	# Add XP through GameManager
	GameManager.add_xp(30)
	await wait_physics_frames(3)

	assert_eq(exp_bar.value, 30.0, "XP bar should show 30")


## Test level up flow via GameManager
func test_level_up_via_game_manager() -> void:
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
