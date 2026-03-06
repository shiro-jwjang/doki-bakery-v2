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
