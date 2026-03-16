extends Node

## BakeryManagerTestHelper
##
## Test helper class for BakeryManager tests.
## Provides utility methods to reduce test code duplication.
## SNA-190: BakeryManager 테스트 헬퍼 클래스 도입

const BakeryManagerClass = preload("res://scripts/autoload/bakery_manager.gd")
const RecipeDataClass = preload("res://resources/data/recipe_data.gd")
const MockTimeProviderClass = preload("res://scripts/utils/mock_time_provider.gd")
const MockRecipeProviderClass = preload("res://scripts/utils/mock_recipe_provider.gd")

var _manager: Node
var _mock_time_provider: MockTimeProvider
var _mock_recipe_provider: MockRecipeProvider


## Create and configure a BakeryManager instance for testing.
## Returns the configured manager instance.
func create_manager(max_slots: int = 3) -> Node:
	_manager = BakeryManagerClass.new()
	_manager._max_slots = max_slots
	_manager._slots = []
	_manager._active_count = 0
	return _manager


## Create a mock recipe with the specified parameters.
## Returns the created recipe instance.
func create_mock_recipe(recipe_id: String, production_time: float = 10.0) -> RecipeData:
	var recipe = RecipeDataClass.new()
	recipe.id = recipe_id
	recipe.production_time = production_time
	return recipe


## Set up mock time provider with optional initial time.
## Returns the configured mock time provider.
func setup_mock_time(initial_time: float = 0.0) -> MockTimeProvider:
	_mock_time_provider = MockTimeProviderClass.new()
	_mock_time_provider.reset_time()
	if initial_time > 0.0:
		_mock_time_provider.set_time(initial_time)
	return _mock_time_provider


## Set up mock recipe provider with default test recipes.
## Returns the configured mock recipe provider.
func setup_mock_recipes() -> MockRecipeProvider:
	_mock_recipe_provider = MockRecipeProviderClass.new()

	# Add standard test recipes
	var default_recipes := [
		create_mock_recipe("bread_001", 10.0),
		create_mock_recipe("croissant", 10.0),
		create_mock_recipe("baguette", 10.0),
		create_mock_recipe("muffin", 10.0)
	]

	for recipe in default_recipes:
		_mock_recipe_provider.add_recipe(recipe)

	return _mock_recipe_provider


## Get the mock time provider instance.
func get_mock_time_provider() -> MockTimeProvider:
	return _mock_time_provider


## Get the mock recipe provider instance.
func get_mock_recipe_provider() -> MockRecipeProvider:
	return _mock_recipe_provider


## Get the BakeryManager instance.
func get_manager() -> Node:
	return _manager


## Inject mock providers into the manager.
func inject_providers(manager: Node) -> void:
	if _mock_time_provider != null:
		manager.set_time_provider(_mock_time_provider)
	if _mock_recipe_provider != null:
		manager.set_recipe_provider(_mock_recipe_provider)


## Complete setup: create manager, providers, and inject dependencies.
## Returns the fully configured manager ready for testing.
func setup_complete(max_slots: int = 3) -> Node:
	create_manager(max_slots)
	setup_mock_time()
	setup_mock_recipes()
	inject_providers(_manager)
	return _manager
