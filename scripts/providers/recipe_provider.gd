class_name RecipeProvider
extends RefCounted

## Abstract base class for providing recipe data
## Allows mocking in tests without DataManager dependency


## Get recipe by ID
## Returns RecipeData or null if not found
## Must be overridden by subclasses
func get_recipe(_id: String) -> RecipeData:
	push_error("RecipeProvider.get_recipe() must be overridden")
	return null
