extends GutTest

## Test suite for SNA-172: DataManager loading method deduplication
## Tests the new _load_resources() helper method

var data_manager: Node


func before_each() -> void:
	# Create a fresh DataManager instance for testing
	data_manager = autofree(Node.new())
	# Add the DataManager script
	var script = load("res://scripts/autoload/data_manager.gd")
	data_manager.set_script(script)


func after_each() -> void:
	if data_manager:
		data_manager.queue_free()


## Test that _load_resources method exists
func test_load_resources_method_exists() -> void:
	assert_true(
		data_manager.has_method("_load_resources"), "DataManager should have _load_resources method"
	)


## Test _load_resources with valid path and property
func test_load_resources_valid_path() -> void:
	# Create a temporary dictionary to load into
	var target_dict: Dictionary = {}

	# Load recipes using the new method
	data_manager._load_resources("res://resources/data/recipes/", "id", target_dict)

	# Verify that recipes were loaded
	assert_gt(target_dict.size(), 0, "Should load at least one recipe")


## Test _load_resources with non-existent path
func test_load_resources_invalid_path() -> void:
	var target_dict: Dictionary = {}

	# This should not crash and should leave dict empty
	data_manager._load_resources("res://nonexistent/path/", "id", target_dict)

	assert_eq(target_dict.size(), 0, "Should have empty dict for invalid path")


## Test _load_resources loads correct data
func test_load_resources_loads_levels() -> void:
	var target_dict: Dictionary = {}

	data_manager._load_resources("res://resources/config/levels/", "level", target_dict)

	# Verify levels were loaded with correct keys
	assert_gt(target_dict.size(), 0, "Should load at least one level")

	# Check that level 1 exists
	assert_true(target_dict.has(1), "Should have level 1")


## Test _load_resources loads shop data
func test_load_resources_loads_shops() -> void:
	var target_dict: Dictionary = {}

	data_manager._load_resources("res://resources/config/shops/", "shop_level", target_dict)

	# Verify shops were loaded
	assert_gt(target_dict.size(), 0, "Should load at least one shop stage")


## Test that original methods still work after refactoring
func test_backward_compatibility_load_recipes() -> void:
	# Call the original _load_recipes method
	data_manager._load_recipes()

	# Verify data was loaded via getter
	var all_recipes = data_manager.get_all_recipes()
	assert_gt(all_recipes.size(), 0, "Should load recipes via original method")


func test_backward_compatibility_load_levels() -> void:
	data_manager._load_levels()

	var all_levels = data_manager.get_all_levels()
	assert_gt(all_levels.size(), 0, "Should load levels via original method")


func test_backward_compatibility_load_shops() -> void:
	data_manager._load_shops()

	var all_shops = data_manager.get_all_shop_stages()
	assert_gt(all_shops.size(), 0, "Should load shops via original method")


## Test that _load_all_data still works
func test_load_all_data_integration() -> void:
	data_manager._load_all_data()

	# Verify all data types were loaded
	assert_gt(data_manager.get_all_recipes().size(), 0, "Should have recipes")
	assert_gt(data_manager.get_all_levels().size(), 0, "Should have levels")
	assert_gt(data_manager.get_all_shop_stages().size(), 0, "Should have shops")


## Test that get_recipe still works
func test_get_recipe_after_load() -> void:
	data_manager._load_all_data()

	# Get first recipe from all recipes
	var all_recipes = data_manager.get_all_recipes()
	if all_recipes.size() > 0:
		var first_recipe = all_recipes[0]
		var recipe_id = first_recipe.id

		var retrieved = data_manager.get_recipe(recipe_id)
		assert_not_null(retrieved, "Should retrieve recipe by ID")
		assert_eq(retrieved.id, recipe_id, "Retrieved recipe should match ID")
