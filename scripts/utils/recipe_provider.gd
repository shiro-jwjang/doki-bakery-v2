## RecipeProvider interface for recipe lookup
## Allows mocking recipe data in tests
class_name RecipeProvider
extends RefCounted


## Get recipe by ID
func get_recipe(_recipe_id: String) -> Resource:
	push_error("RecipeProvider.get_recipe() must be implemented")
	return null
