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


## SNA-178: Test lazy loading for recipes - first call loads data
func test_get_recipe_lazy_loads_on_first_call() -> void:
	DataManager.clear_recipe_cache()
	var recipe := DataManager.get_recipe("bread_001")
	assert_not_null(recipe, "Should return recipe after lazy load")
	assert_eq(recipe.id, "bread_001")


## SNA-178: Test lazy loading for recipes - second call uses cache
func test_get_recipe_uses_cache_on_second_call() -> void:
	DataManager.clear_recipe_cache()
	var recipe1 := DataManager.get_recipe("bread_001")
	var recipe2 := DataManager.get_recipe("bread_001")
	assert_same(recipe1, recipe2, "Should return same cached instance")


## SNA-178: Test lazy loading for levels - first call loads data
func test_get_level_lazy_loads_on_first_call() -> void:
	DataManager.clear_level_cache()
	var level := DataManager.get_level(1)
	assert_not_null(level, "Should return level data after lazy load")
	assert_eq(level.level, 1)


## SNA-178: Test lazy loading for levels - second call uses cache
func test_get_level_uses_cache_on_second_call() -> void:
	DataManager.clear_level_cache()
	var level1 := DataManager.get_level(1)
	var level2 := DataManager.get_level(1)
	assert_same(level1, level2, "Should return same cached instance")


## SNA-178: Test lazy loading for shop stages - first call loads data
func test_get_shop_stage_lazy_loads_on_first_call() -> void:
	DataManager.clear_shop_cache()
	var shop := DataManager.get_shop_stage(1)
	assert_not_null(shop, "Should return shop data after lazy load")
	assert_eq(shop.shop_level, 1)


## SNA-178: Test lazy loading for shop stages - second call uses cache
func test_get_shop_stage_uses_cache_on_second_call() -> void:
	DataManager.clear_shop_cache()
	var shop1 := DataManager.get_shop_stage(1)
	var shop2 := DataManager.get_shop_stage(1)
	assert_same(shop1, shop2, "Should return same cached instance")


## SNA-178: Test get_all_recipes triggers lazy load
func test_get_all_recipes_triggers_lazy_load() -> void:
	DataManager.clear_recipe_cache()
	var recipes := DataManager.get_all_recipes()
	assert_true(recipes.size() > 0, "Should load and return recipes")


## SNA-178: Test get_all_levels triggers lazy load
func test_get_all_levels_triggers_lazy_load() -> void:
	DataManager.clear_level_cache()
	var levels := DataManager.get_all_levels()
	assert_true(levels.size() > 0, "Should load and return levels")


## SNA-178: Test get_all_shop_stages triggers lazy load
func test_get_all_shop_stages_triggers_lazy_load() -> void:
	DataManager.clear_shop_cache()
	var shops := DataManager.get_all_shop_stages()
	assert_true(shops.size() > 0, "Should load and return shop stages")
