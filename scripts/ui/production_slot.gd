class_name ProductionSlot
extends Button

## ProductionSlot UI
##
## Individual slot UI within the ProductionPanel.
## SNA-168: M3 UI component integration

var slot_index: int = -1

@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _icon: TextureRect = %Icon

## Public getters for UI elements (for testing)
var label: Label:
	get:
		return _status_label

var progress_bar: ProgressBar:
	get:
		return _progress_bar


## Safely execute a callable only if this component is inside the scene tree.
##
## This prevents errors from attempting to update UI elements when the node
## has been removed from the scene tree or not yet added.
##
## @param callable: The function to execute if inside tree
func safe_update(callable: Callable) -> void:
	if is_inside_tree():
		callable.call()


func setup(index: int) -> void:
	slot_index = index
	safe_update(
		func():
			_status_label.text = "빈 슬롯"
			_progress_bar.value = 0.0
			_icon.texture = null
	)


func set_production(recipe_id: String) -> void:
	safe_update(
		func():
			var recipe = DataManager.get_recipe(recipe_id)
			var d_name = recipe.get_display_name_or_id() if recipe else recipe_id
			_status_label.text = "베이킹 중 %s" % d_name
			_progress_bar.value = 0.0

			if recipe and recipe.icon:
				_icon.texture = recipe.icon
			else:
				_icon.texture = null
	)


func set_progress(progress: float) -> void:
	safe_update(func(): _progress_bar.value = progress)


func set_completed(recipe_id: String) -> void:
	safe_update(
		func():
			var recipe = DataManager.get_recipe(recipe_id)
			var d_name = recipe.get_display_name_or_id() if recipe else recipe_id
			_status_label.text = "완료! %s" % d_name
			_progress_bar.value = 1.0

			if recipe and recipe.icon:
				_icon.texture = recipe.icon
			else:
				_icon.texture = null
	)
