extends "res://scripts/ui/base_ui_component.gd"

## ProductionSlot UI
##
## Individual slot UI within the ProductionPanel.
## SNA-204: Auto-repeat toggle button added

var slot_index: int = -1

@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _icon: TextureRect = %Icon
@onready var _auto_repeat_button: CheckBox = %AutoRepeatCheckBox

## Public getters for UI elements (for testing)
var label: Label:
	get:
		return _status_label

var progress_bar: ProgressBar:
	get:
		return _progress_bar

var auto_repeat_button: CheckBox:
	get:
		return _auto_repeat_button


func setup(index: int) -> void:
	slot_index = index
	safe_update(
		func():
			_status_label.text = "빈 슬롯"
			_progress_bar.value = 0.0
			_icon.texture = null
			_update_auto_repeat_button()
	)

	# Connect auto-repeat button signal if it exists
	if _auto_repeat_button != null:
		if not _auto_repeat_button.toggled.is_connected(_on_auto_repeat_toggled):
			_auto_repeat_button.toggled.connect(_on_auto_repeat_toggled)


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

			_update_auto_repeat_button()
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

			_update_auto_repeat_button()
	)


## Update auto-repeat button state based on BakeryManager
func _update_auto_repeat_button() -> void:
	if _auto_repeat_button == null:
		return

	var is_set := false
	if BakeryManager.has_method("is_auto_repeat_set"):
		is_set = BakeryManager.is_auto_repeat_set(slot_index)

	# Temporarily disconnect to avoid triggering the toggle signal
	_auto_repeat_button.toggled.disconnect(_on_auto_repeat_toggled)
	_auto_repeat_button.button_pressed = is_set
	_auto_repeat_button.toggled.connect(_on_auto_repeat_toggled)


## Handle auto-repeat toggle button pressed
func _on_auto_repeat_toggled(button_pressed: bool) -> void:
	if slot_index < 0:
		return

	if button_pressed:
		# Get current recipe from slot and set auto-repeat
		var slots := BakeryManager.get_slots()
		for slot in slots:
			if slot.slot_index == slot_index and slot.recipe:
				if BakeryManager.has_method("set_auto_repeat"):
					BakeryManager.set_auto_repeat(slot_index, slot.recipe.id)
				break
	else:
		# Clear auto-repeat
		if BakeryManager.has_method("clear_auto_repeat"):
			BakeryManager.clear_auto_repeat(slot_index)
