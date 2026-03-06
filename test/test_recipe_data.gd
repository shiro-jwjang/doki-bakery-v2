extends GutTest

const RecipeDataClass = preload("res://resources/data/recipe_data.gd")

var recipe: Resource


func before_each() -> void:
	recipe = RecipeDataClass.new()


func test_recipe_has_id() -> void:
	recipe.id = "bread_001"
	assert_eq(recipe.id, "bread_001")


func test_recipe_has_name() -> void:
	recipe.display_name = "크로와상"
	assert_eq(recipe.display_name, "크로와상")


func test_recipe_has_production_time() -> void:
	recipe.production_time = 5.0
	assert_eq(recipe.production_time, 5.0)


func test_recipe_has_price() -> void:
	recipe.base_price = 100
	assert_eq(recipe.base_price, 100)


func test_recipe_has_unlock_level() -> void:
	recipe.unlock_level = 3
	assert_eq(recipe.unlock_level, 3)


func test_recipe_icon_can_be_null() -> void:
	assert_null(recipe.icon, "Icon should be null by default")


func test_recipe_default_values() -> void:
	var default_recipe = RecipeDataClass.new()
	assert_eq(default_recipe.id, "", "Default id should be empty string")
	assert_eq(default_recipe.display_name, "", "Default name should be empty string")
	assert_eq(default_recipe.production_time, 1.0, "Default production time should be 1.0")
	assert_eq(default_recipe.base_price, 10, "Default base price should be 10")
	assert_eq(default_recipe.unlock_level, 1, "Default unlock level should be 1")
