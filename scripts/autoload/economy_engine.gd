extends Node

## EconomyEngine Autoload
##
## Handles game economy operations including selling bread,
## calculating gold, and managing transactions. (SNA-72)


## Sell bread and add gold based on recipe's sell price
## Returns true if sale was successful, false otherwise
func sell_bread(recipe_id: String) -> bool:
	var recipe := DataManager.get_recipe(recipe_id)
	if recipe == null:
		return false

	GameManager.add_gold(recipe.base_price)
	return true
