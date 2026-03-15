## DataManagerRecipeProvider provides recipes from DataManager
## Used in production environment
class_name DataManagerRecipeProvider
extends RecipeProvider


## Get recipe from DataManager
func get_recipe(recipe_id: String) -> Resource:
	return DataManager.get_recipe(recipe_id)
