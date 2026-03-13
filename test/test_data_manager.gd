extends GutTest


func test_data_manager_exists() -> void:
	assert_not_null(DataManager, "DataManager should exist as autoload")


func test_get_recipe_returns_recipe_data() -> void:
	var recipe := DataManager.get_recipe("bread_001")
	assert_not_null(recipe, "Should return recipe")
	assert_eq(recipe.id, "bread_001")


func test_get_recipe_returns_null_for_invalid_id() -> void:
	var recipe := DataManager.get_recipe("invalid_id")
	assert_null(recipe, "Should return null for invalid ID")


func test_get_level_returns_level_data() -> void:
	var level := DataManager.get_level(1)
	assert_not_null(level, "Should return level data")
	assert_eq(level.level, 1)


func test_get_level_returns_null_for_invalid_level() -> void:
	var level := DataManager.get_level(999)
	assert_null(level, "Should return null for invalid level")


func test_get_shop_stage_returns_shop_data() -> void:
	var shop := DataManager.get_shop_stage(1)
	assert_not_null(shop, "Should return shop data")
	assert_eq(shop.shop_level, 1)


func test_get_all_recipes_returns_array() -> void:
	var recipes := DataManager.get_all_recipes()
	assert_true(recipes is Array, "Should return array")
	assert_true(recipes.size() > 0, "Should have at least one recipe")


## SNA-166: Test get_xp_required_for_level returns correct XP for level 1
func test_get_xp_required_for_level_returns_0_for_level_1() -> void:
	var xp: int = DataManager.get_xp_required_for_level(1)
	assert_eq(xp, 0, "Level 1 should require 0 XP")


## SNA-166: Test get_xp_required_for_level returns correct XP for level 2
func test_get_xp_required_for_level_returns_100_for_level_2() -> void:
	var xp: int = DataManager.get_xp_required_for_level(2)
	assert_eq(xp, 100, "Level 2 should require 100 XP")


## SNA-166: Test get_xp_required_for_level returns correct XP for level 3
func test_get_xp_required_for_level_returns_250_for_level_3() -> void:
	var xp: int = DataManager.get_xp_required_for_level(3)
	assert_eq(xp, 250, "Level 3 should require 250 XP")


## SNA-166: Test get_xp_required_for_level returns correct XP for higher levels
func test_get_xp_required_for_level_returns_correct_xp_for_higher_levels() -> void:
	var xp_4: int = DataManager.get_xp_required_for_level(4)
	var xp_5: int = DataManager.get_xp_required_for_level(5)
	assert_eq(xp_4, 500, "Level 4 should require 500 XP")
	assert_eq(xp_5, 1000, "Level 5 should require 1000 XP")


## SNA-166: Test get_xp_required_for_level returns 0 for invalid level
func test_get_xp_required_for_level_returns_0_for_invalid_level() -> void:
	var xp: int = DataManager.get_xp_required_for_level(999)
	assert_eq(xp, 0, "Invalid level should return 0 XP")


## SNA-166: Test get_xp_required_for_level uses cached data
func test_get_xp_required_for_level_uses_cached_data() -> void:
	var xp1: int = DataManager.get_xp_required_for_level(2)
	var xp2: int = DataManager.get_xp_required_for_level(2)
	assert_eq(xp1, xp2, "Multiple calls should return same value")
	assert_eq(xp1, 100, "Should return correct XP value")
