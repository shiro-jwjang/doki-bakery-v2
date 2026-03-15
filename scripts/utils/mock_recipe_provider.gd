## MockRecipeProvider for testing
## Allows controlled recipe data in tests
class_name MockRecipeProvider
extends RecipeProvider

var _recipes: Dictionary = {}


## Add a recipe to the mock registry
func add_recipe(recipe: RecipeData) -> void:
	_recipes[recipe.id] = recipe


## Set mock recipe (backward compatibility)
func set_recipe(recipe: Resource) -> void:
	if recipe and recipe.id:
		_recipes[recipe.id] = recipe


## Remove a recipe from the mock registry
func remove_recipe(id: String) -> void:
	_recipes.erase(id)


## Clear all recipes from the mock registry
func clear_recipes() -> void:
	_recipes.clear()


## Clear mock recipe (backward compatibility)
func clear_recipe() -> void:
	_recipes.clear()


## Get mock recipe
func get_recipe(recipe_id: String) -> RecipeData:
	return _recipes.get(recipe_id)
