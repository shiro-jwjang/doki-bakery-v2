class_name DataManagerRecipeProvider
extends RecipeProvider

## Production implementation using DataManager


func get_recipe(id: String) -> RecipeData:
	return DataManager.get_recipe(id)
