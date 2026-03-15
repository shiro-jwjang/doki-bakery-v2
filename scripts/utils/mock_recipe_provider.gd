## MockRecipeProvider for testing
## Allows controlled recipe data in tests
class_name MockRecipeProvider
extends RecipeProvider

var _mock_recipe: Resource = null


## Set mock recipe
func set_recipe(recipe: Resource) -> void:
	_mock_recipe = recipe


## Clear mock recipe
func clear_recipe() -> void:
	_mock_recipe = null


## Get mock recipe
func get_recipe(_recipe_id: String) -> Resource:
	return _mock_recipe
