extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for GameManager Level/XP System (SNA-69)
## Tests level and experience management using LevelData

var _level_up_received := false
var _level_up_value := 0
var _experience_changed_received := false
var _experience_changed_old := 0
var _experience_changed_new := 0


func before_each() -> void:
	# Reset GameManager state for each test
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0
	GameManager.set_game_state("menu")

	# Reset signal tracking
	_level_up_received = false
	_level_up_value = 0
	_experience_changed_received = false
	_experience_changed_old = 0
	_experience_changed_new = 0


func after_each() -> void:
	# Disconnect all signals
	if EventBusAutoload.level_up.is_connected(_on_level_up):
		EventBusAutoload.level_up.disconnect(_on_level_up)
	if EventBusAutoload.experience_changed.is_connected(_on_experience_changed):
		EventBusAutoload.experience_changed.disconnect(_on_experience_changed)


## Test add_xp increases experience points
func test_add_xp_increases_experience() -> void:
	GameManager.add_xp(50)

	assert_eq(GameManager.get_xp(), 50, "Experience should be 50")


## Test add_xp accumulates
func test_add_xp_accumulates() -> void:
	GameManager.add_xp(30)
	GameManager.add_xp(20)

	assert_eq(GameManager.get_xp(), 50, "Experience should be 50")


## Test get_xp returns current experience
func test_get_xp() -> void:
	GameManager.add_xp(75)

	assert_eq(GameManager.get_xp(), 75, "get_xp should return 75")


## Test get_level returns current level
func test_get_level() -> void:
	assert_eq(GameManager.get_level(), 1, "Initial level should be 1")


## Test add_xp triggers level up at threshold (Level 1 -> 2)
func test_level_up_threshold() -> void:
	EventBusAutoload.level_up.connect(_on_level_up)

	# Level 2 requires 100 XP (from LevelData)
	GameManager.add_xp(100)

	assert_eq(GameManager.get_level(), 2, "Should level up to 2")
	assert_true(_level_up_received, "level_up signal should be emitted")
	assert_eq(_level_up_value, 2, "Signal should carry correct level")


## Test add_xp with excess XP carries over
func test_level_up_with_excess_xp() -> void:
	# Add 150 XP: should reach level 2 with 50 XP remaining
	# Level 2 requires 100 XP from level 1
	GameManager.add_xp(150)

	assert_eq(GameManager.get_level(), 2, "Should be level 2")
	assert_eq(GameManager.get_xp(), 50, "Should have 50 XP remaining")


## Test multiple level ups with sufficient XP
func test_multiple_level_ups() -> void:
	EventBusAutoload.level_up.connect(_on_level_up)

	# Level 1 -> 2 requires 100 XP
	# Level 2 -> 3 requires 250 XP (total 350 XP from level 1)
	GameManager.add_xp(350)

	assert_eq(GameManager.get_level(), 3, "Should level up to 3")
	assert_eq(GameManager.get_xp(), 0, "Should have 0 XP remaining")


## Test max level cap prevents further leveling
func test_max_level_cap() -> void:
	EventBusAutoload.level_up.connect(_on_level_up)

	# Add massive XP to cap at level 10
	# Total XP needed for level 10: 100 + 250 + 500 + 1000 + 2000 + 4000 + 8000 + 16000 + 32000 = 63850
	GameManager.add_xp(70000)

	assert_eq(GameManager.get_level(), 10, "Should cap at level 10")


## Test cannot level up beyond MAX_LEVEL
func test_cannot_level_up_beyond_max() -> void:
	GameManager.level = 10
	GameManager.experience = 0
	EventBusAutoload.level_up.connect(_on_level_up)

	GameManager.add_xp(1000)

	assert_eq(GameManager.get_level(), 10, "Should remain at level 10")
	assert_false(_level_up_received, "level_up signal should not be emitted")


## Test experience_changed signal is emitted when adding XP
func test_experience_changed_signal() -> void:
	EventBusAutoload.experience_changed.connect(_on_experience_changed)

	GameManager.add_xp(50)

	assert_true(_experience_changed_received, "experience_changed signal should be emitted")
	assert_eq(_experience_changed_old, 0, "Old XP should be 0")
	assert_eq(_experience_changed_new, 50, "New XP should be 50")


## Test level_up signal is emitted for each level gained
func test_level_up_signal_multiple_times() -> void:
	EventBusAutoload.level_up.connect(_on_level_up)

	# Level 1 -> 2 -> 3
	GameManager.add_xp(350)

	assert_eq(_level_up_value, 3, "Final signal should carry level 3")


## Test experience is consumed when leveling up
func test_experience_consumed_on_level_up() -> void:
	# Add exactly enough for level 2 (100 XP)
	GameManager.add_xp(100)

	assert_eq(GameManager.get_level(), 2, "Should be level 2")
	assert_eq(GameManager.get_xp(), 0, "XP should be consumed")


## Test add_xp with zero amount
func test_add_xp_zero() -> void:
	GameManager.add_xp(0)

	assert_eq(GameManager.get_xp(), 0, "XP should remain 0")


## Test add_xp with negative amount (should not add)
func test_add_xp_negative() -> void:
	GameManager.add_xp(50)
	GameManager.add_xp(-10)

	assert_eq(GameManager.get_xp(), 50, "XP should remain 50 (negative ignored)")


## Signal handlers
func _on_level_up(new_level: int) -> void:
	_level_up_received = true
	_level_up_value = new_level


func _on_experience_changed(old: int, new: int) -> void:
	_experience_changed_received = true
	_experience_changed_old = old
	_experience_changed_new = new
