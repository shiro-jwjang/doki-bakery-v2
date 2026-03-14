class_name RecipeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var production_time: float = 1.0
@export var base_price: int = 10
@export var unlock_level: int = 1
@export var xp_reward: int = 10
@export var icon: Texture2D


func get_display_name_or_id() -> String:
	return display_name if display_name != "" else id
