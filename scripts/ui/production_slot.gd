extends "res://scripts/ui/base_ui_component.gd"

## ProductionSlot UI
##
## Individual slot UI within the ProductionPanel.

var slot_index: int = -1

var _status_label: Label = null
var _progress_bar: ProgressBar = null

## Public accessors for testing
var label: Label:
	get:
		return _status_label
	set(value):
		_status_label = value

var progress_bar: ProgressBar:
	get:
		return _progress_bar
	set(value):
		_progress_bar = value


func _ready() -> void:
	# Try to get nodes from scene tree, or create them if instantiated via code
	_status_label = get_node_or_null("%StatusLabel")
	_progress_bar = get_node_or_null("%ProgressBar")

	# Create nodes if they don't exist (for code instantiation)
	if _status_label == null:
		_status_label = Label.new()
		add_child(_status_label)
	if _progress_bar == null:
		_progress_bar = ProgressBar.new()
		add_child(_progress_bar)


func setup(index: int) -> void:
	slot_index = index
	safe_update(
		func():
			_status_label.text = "빈 슬롯"
			_progress_bar.value = 0.0
	)


func set_production(recipe_id: String) -> void:
	safe_update(
		func():
			var recipe = DataManager.get_recipe(recipe_id)
			var d_name = recipe.get_display_name_or_id() if recipe else recipe_id
			_status_label.text = "베이킹 중 %s" % d_name
			_progress_bar.value = 0.0
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
	)
