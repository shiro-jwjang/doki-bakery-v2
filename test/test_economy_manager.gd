extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for EconomyManager
## Tests gold earning from bread sales and XP calculation

var _experience_changed_received := false
var _experience_changed_old := 0
var _experience_changed_new := 0
var _level_up_received := false
var _level_up_value := 0
var _gold_changed_received := false
var _gold_changed_old := 0
var _gold_changed_new := 0


func before_each() -> void:
	# Reset GameManager state for each test
	GameManager.gold = 0
	GameManager.level = 1
	GameManager.experience = 0

	# Reset signal tracking
	_experience_changed_received = false
	_experience_changed_old = 0
	_experience_changed_new = 0
	_level_up_received = false
	_level_up_value = 0
	_gold_changed_received = false
	_gold_changed_old = 0
	_gold_changed_new = 0


func after_each() -> void:
	# Disconnect all signals
	if EventBus.experience_changed.is_connected(_on_experience_changed):
		EventBus.experience_changed.disconnect(_on_experience_changed)
	if EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.disconnect(_on_level_up)
	if EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.disconnect(_on_gold_changed)


## Test that EconomyManager singleton exists
func test_economy_engine_singleton_exists() -> void:
	assert_not_null(EconomyManager, "EconomyManager singleton should exist")


## Test sell_bread grants correct XP from recipe xp_reward
func test_sell_bread_grants_xp() -> void:
	EventBus.experience_changed.connect(_on_experience_changed)

	var recipe := RecipeData.new()
	recipe.id = "test_bread"
	recipe.display_name = "Test Bread"
	recipe.base_price = 50
	recipe.xp_reward = 25

	EconomyManager.sell_bread(recipe)

	assert_eq(GameManager.experience, 25, "Experience should be 25")
	assert_true(_experience_changed_received, "experience_changed signal should be emitted")
	assert_eq(_experience_changed_new, 25, "Signal should carry correct XP amount")


## Test sell_bread adds gold from recipe base_price
func test_sell_bread_adds_gold() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)

	var recipe := RecipeData.new()
	recipe.id = "test_bread"
	recipe.display_name = "Test Bread"
	recipe.base_price = 50
	recipe.xp_reward = 25

	EconomyManager.sell_bread(recipe)

	assert_eq(GameManager.gold, 50, "Gold should be 50")
	assert_true(_gold_changed_received, "gold_changed signal should be emitted")
	assert_eq(_gold_changed_new, 50, "Signal should carry correct gold amount")


## Test sell_bread accumulates XP from multiple sales
func test_sell_bread_accumulates_xp() -> void:
	var recipe := RecipeData.new()
	recipe.id = "test_bread"
	recipe.display_name = "Test Bread"
	recipe.base_price = 30
	recipe.xp_reward = 15

	EconomyManager.sell_bread(recipe)
	EconomyManager.sell_bread(recipe)
	EconomyManager.sell_bread(recipe)

	assert_eq(GameManager.experience, 45, "Experience should be 45 (15 * 3)")
	assert_eq(GameManager.gold, 90, "Gold should be 90 (30 * 3)")


## Test sell_bread triggers level up when enough XP accumulates
func test_sell_bread_triggers_level_up() -> void:
	EventBus.level_up.connect(_on_level_up)

	var recipe := RecipeData.new()
	recipe.id = "valuable_bread"
	recipe.display_name = "Valuable Bread"
	recipe.base_price = 100
	recipe.xp_reward = 50

	# Sell 2 breads: 50 * 2 = 100 XP, which should trigger level up from 1 to 2
	EconomyManager.sell_bread(recipe)
	EconomyManager.sell_bread(recipe)

	assert_eq(GameManager.level, 2, "Should level up to 2")
	assert_true(_level_up_received, "level_up signal should be emitted")
	assert_eq(_level_up_value, 2, "Signal should carry correct level")


## Test sell_bread handles recipes with zero XP reward
func test_sell_bread_zero_xp() -> void:
	var recipe := RecipeData.new()
	recipe.id = "basic_bread"
	recipe.display_name = "Basic Bread"
	recipe.base_price = 10
	recipe.xp_reward = 0

	EconomyManager.sell_bread(recipe)

	assert_eq(GameManager.experience, 0, "Experience should remain 0")
	assert_eq(GameManager.gold, 10, "Gold should still be added")


## Test sell_bread with high XP triggers multiple level ups
func test_sell_bread_multiple_level_ups() -> void:
	EventBus.level_up.connect(_on_level_up)

	var recipe := RecipeData.new()
	recipe.id = "legendary_bread"
	recipe.display_name = "Legendary Bread"
	recipe.base_price = 500
	recipe.xp_reward = 300

	# Sell enough for multiple level ups: 300 * 5 = 1500 XP
	# Level 1->2: 100 XP, Level 2->3: 250 XP (total 350)
	# So 5 sales = 1500 XP should reach multiple levels
	for i in range(5):
		EconomyManager.sell_bread(recipe)

	assert_gt(GameManager.level, 1, "Should have leveled up multiple times")


## Signal handlers
func _on_experience_changed(old: int, new: int) -> void:
	_experience_changed_received = true
	_experience_changed_old = old
	_experience_changed_new = new


func _on_level_up(new_level: int) -> void:
	_level_up_received = true
	_level_up_value = new_level


func _on_gold_changed(old: int, new: int) -> void:
	_gold_changed_received = true
	_gold_changed_old = old
	_gold_changed_new = new
