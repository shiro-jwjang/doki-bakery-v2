extends Control

## ProductionPanel
##
## Displays production slots and their status.
## Updates via EventBus signals instead of polling BakeryManager.
## SNA-95: ProductionPanel ↔ ProductionManager 시그널 연결

## Dictionary to track slot UI elements
## Key: slot_index, Value: Dictionary with label and progress_bar
var _slot_ui: Dictionary = {}

## Number of production slots to display
var _max_slots: int = 3


func _ready() -> void:
	# Connect to EventBus signals
	EventBus.production_started.connect(_on_production_started)
	EventBus.production_completed.connect(_on_production_completed)

	# Initialize slot UI elements
	_init_slot_ui()


## Initialize slot UI elements
func _init_slot_ui() -> void:
	for i in range(_max_slots):
		var slot_container = HBoxContainer.new()
		slot_container.set_name("Slot_%d" % i)

		# Create label for slot status
		var label = Label.new()
		label.set_text("슬롯 %d: 비어있음" % i)
		label.set_name("StatusLabel")

		# Create progress bar
		var progress_bar = ProgressBar.new()
		progress_bar.set_min_value(0.0)
		progress_bar.set_max_value(1.0)
		progress_bar.set_value(0.0)
		progress_bar.set_name("ProgressBar")

		slot_container.add_child(label)
		slot_container.add_child(progress_bar)
		add_child(slot_container)

		# Store UI elements reference
		_slot_ui[i] = {"label": label, "progress_bar": progress_bar}


## Handle production_started signal
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	if slot_index in _slot_ui:
		var slot_data = _slot_ui[slot_index]
		slot_data.label.set_text("슬롯 %d: 베이킹 중 (%s)" % [slot_index, recipe_id])
		slot_data.progress_bar.set_value(0.0)


## Handle production_completed signal
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	if slot_index in _slot_ui:
		var slot_data = _slot_ui[slot_index]
		slot_data.label.set_text("슬롯 %d: 완료! (%s)" % [slot_index, recipe_id])
		slot_data.progress_bar.set_value(1.0)


## Get slot UI elements for testing
func get_slot_ui(slot_index: int) -> Dictionary:
	if slot_index in _slot_ui:
		return _slot_ui[slot_index]
	return {}
