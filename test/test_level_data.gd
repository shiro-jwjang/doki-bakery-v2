extends GutTest

const LevelDataClass = preload("res://resources/config/level_data.gd")

var level: Resource


func before_each() -> void:
	level = LevelDataClass.new()


func test_level_has_level_number() -> void:
	level.level = 5
	assert_eq(level.level, 5)


func test_level_has_required_xp() -> void:
	level.required_xp = 1000
	assert_eq(level.required_xp, 1000)


func test_level_has_gold_reward() -> void:
	level.gold_reward = 500
	assert_eq(level.gold_reward, 500)


func test_level_has_unlock_recipes() -> void:
	level.unlock_recipes = ["bread_001", "bread_002"]
	assert_eq(level.unlock_recipes.size(), 2)
	assert_eq(level.unlock_recipes[0], "bread_001")
	assert_eq(level.unlock_recipes[1], "bread_002")


func test_level_default_values() -> void:
	var default_level = LevelDataClass.new()
	assert_eq(default_level.level, 1, "Default level should be 1")
	assert_eq(default_level.required_xp, 100, "Default required XP should be 100")
	assert_eq(default_level.gold_reward, 50, "Default gold reward should be 50")
	assert_eq(default_level.unlock_recipes.size(), 0, "Default unlock recipes should be empty")


func test_level_unlock_recipes_can_be_empty() -> void:
	level.unlock_recipes = []
	assert_eq(level.unlock_recipes.size(), 0)
