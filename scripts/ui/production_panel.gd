extends Control

## ProductionPanel UI
##
## Displays production slot status and progress.
## Uses signal-based updates instead of polling BakeryManager.
## SNA-95: ProductionPanel ↔ BakeryManager 시그널 연결

## Slot UI data: slot_index → { label: Label, progress_bar: ProgressBar }
var _slot_data: Dictionary = {}


func _ready() -> void:
	# Connect to EventBus signals for production updates
	if not EventBus.production_started.is_connected(_on_production_started):
		EventBus.production_started.connect(_on_production_started)

	if not EventBus.production_completed.is_connected(_on_production_completed):
		EventBus.production_completed.connect(_on_production_completed)


## Get slot UI dictionary for a given slot index.
## Returns { label: Label, progress_bar: ProgressBar } or null if not found.
func get_slot_ui(slot_index: int) -> Dictionary:
	if _slot_data.has(slot_index):
		return _slot_data[slot_index]
	return {}


## Handle production started signal
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	var ui := _get_or_create_slot(slot_index)
	ui.label.text = "베이킹 중 %s" % recipe_id
	ui.progress_bar.value = 0.0


## Handle production completed signal
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	var ui := _get_or_create_slot(slot_index)
	ui.label.text = "완료! %s" % recipe_id
	ui.progress_bar.value = 1.0


## Get or create slot UI container
func _get_or_create_slot(slot_index: int) -> Dictionary:
	if _slot_data.has(slot_index):
		return _slot_data[slot_index]

	# Create container
	var container := VBoxContainer.new()
	container.name = "Slot%d" % slot_index

	# Label for status
	var label := Label.new()
	label.name = "StatusLabel"
	label.text = "빈 슬롯"
	container.add_child(label)

	# Progress bar
	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	container.add_child(progress_bar)

	add_child(container)

	var ui := {
		"label": label,
		"progress_bar": progress_bar,
		"container": container,
	}
	_slot_data[slot_index] = ui
	return ui
