extends Node

## EconomyEngine Autoload
##
## Handles economic transactions including bread sales,
## gold earning, and experience point calculation.

const RecipeData = preload("res://resources/data/recipe_data.gd")


## Sell bread and grant rewards
## - Adds gold based on recipe base_price
## - Grants experience points based on recipe xp_reward
func sell_bread(recipe: RecipeData) -> void:
	if recipe == null:
		return

	GameManager.add_gold(recipe.base_price)
	GameManager.add_experience(recipe.xp_reward)
