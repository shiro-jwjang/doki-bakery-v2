extends Control

## ProductionPanel UI
##
## Displays production slot status and progress.
## Uses signal-based updates instead of polling BakeryManager.
## SNA-95: ProductionPanel ↔ BakeryManager 시그널 연결
## SNA-96: 슬롯 클릭 → BreadMenu → 생산 시작

## Emitted when a slot is clicked
signal slot_clicked(slot_index: int)

## Slot UI data: slot_index → { label, progress_bar, container, button }
var _slot_data: Dictionary = {}


func _ready() -> void:
	# Connect to EventBus signals for production updates
	if not EventBus.production_started.is_connected(_on_production_started):
		EventBus.production_started.connect(_on_production_started)

	if not EventBus.production_progressed.is_connected(_on_production_progressed):
		EventBus.production_progressed.connect(_on_production_progressed)

	if not EventBus.production_completed.is_connected(_on_production_completed):
		EventBus.production_completed.connect(_on_production_completed)


## Get slot UI dictionary for a given slot index.
## Returns { label: Label, progress_bar: ProgressBar, container: Control }
## or null if slot does not exist.
func get_slot_ui(slot_index: int) -> Variant:
	if _slot_data.has(slot_index):
		return _slot_data[slot_index]
	return null


## Handle production started signal
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	var ui := _get_or_create_slot(slot_index)
	ui.label.text = "베이킹 중 %s" % recipe_id
	ui.progress_bar.value = 0.0


## Handle production progressed signal
func _on_production_progressed(slot_index: int, progress: float) -> void:
	var ui: Variant = get_slot_ui(slot_index)
	if ui == null:
		return
	ui.progress_bar.value = progress


## Handle production completed signal
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	var ui := _get_or_create_slot(slot_index)
	ui.label.text = "완료! %s" % recipe_id
	ui.progress_bar.value = 1.0


## Get or create slot UI container
func _get_or_create_slot(slot_index: int) -> Dictionary:
	if _slot_data.has(slot_index):
		return _slot_data[slot_index]

	# Create button as container (clickable slot)
	var button := Button.new()
	button.name = "Slot%d" % slot_index
	button.toggle_mode = false
	button.pressed.connect(_on_slot_button_pressed.bind(slot_index))

	# Create inner container for label + progress
	var inner := VBoxContainer.new()
	button.add_child(inner)

	# Label for status
	var label := Label.new()
	label.name = "StatusLabel"
	label.text = "빈 슬롯"
	inner.add_child(label)

	# Progress bar
	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	inner.add_child(progress_bar)

	add_child(button)

	var ui := {
		"label": label,
		"progress_bar": progress_bar,
		"container": button,
		"button": button,
	}
	_slot_data[slot_index] = ui
	return ui


## Handle slot button press
func _on_slot_button_pressed(slot_index: int) -> void:
	slot_clicked.emit(slot_index)
