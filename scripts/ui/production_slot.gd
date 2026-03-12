extends Button

## ProductionSlot UI
##
## Individual slot UI within the ProductionPanel.

@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar

var slot_index: int = -1

func setup(index: int) -> void:
	slot_index = index
	_status_label.text = "빈 슬롯"
	_progress_bar.value = 0.0

func set_production(recipe_id: String) -> void:
	var recipe = DataManager.get_recipe(recipe_id)
	var d_name = recipe.display_name if recipe else recipe_id
	_status_label.text = "베이킹 중 %s" % d_name
	_progress_bar.value = 0.0

func set_progress(progress: float) -> void:
	_progress_bar.value = progress

func set_completed(recipe_id: String) -> void:
	var recipe = DataManager.get_recipe(recipe_id)
	var d_name = recipe.display_name if recipe else recipe_id
	_status_label.text = "완료! %s" % d_name
	_progress_bar.value = 1.0
