extends Node

## EconomyManager Autoload
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
	GameManager.add_xp(recipe.xp_reward)


## Award XP for production completion
## - Grants experience points based on recipe xp_reward
## - Does NOT grant gold (only for sales)
func award_production_xp(recipe: RecipeData) -> void:
	if recipe == null:
		return

	GameManager.add_xp(recipe.xp_reward)
