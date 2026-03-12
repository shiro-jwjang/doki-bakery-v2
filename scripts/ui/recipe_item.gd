extends Button

## RecipeItem UI
##
## Individual recipe entry in the BreadMenu.

@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _price_label: Label = %PriceLabel

var recipe_id: String = ""

func setup(recipe: Resource) -> void:
	recipe_id = recipe.get("id") if recipe.has_method("get") else ""
	_name_label.text = recipe.get("display_name") if recipe.has_method("get") else recipe_id
	_price_label.text = "%dG" % (recipe.get("base_price") if recipe.has_method("get") else 0)
	
	if recipe.get("icon") != null:
		_icon.texture = recipe.get("icon")
