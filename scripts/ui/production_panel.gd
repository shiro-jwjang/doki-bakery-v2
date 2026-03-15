extends Control

## ProductionPanel UI
##
## Displays production slot status and progress.
## Uses signal-based updates instead of polling BakeryManager.
## SNA-95: ProductionPanel ↔ BakeryManager 시그널 연결
## SNA-96: 슬롯 클릭 → BreadMenu → 생산 시작

## Emitted when a slot is clicked
signal slot_clicked(slot_index: int)

## Slot UI data: slot_index → ProductionSlot
var _slot_data: Dictionary = {}

@export var slot_scene: PackedScene = preload("res://scenes/ui/production_slot.tscn")
var _container: VBoxContainer = null


func _ready() -> void:
	# Try to get container from scene tree, or create one if instantiated via code
	_container = get_node_or_null("MarginContainer/VBoxContainer")
	if _container == null:
		_container = VBoxContainer.new()
		add_child(_container)

	# Connect to EventBus signals
	if not EventBus.production_started.is_connected(on_production_started):
		EventBus.production_started.connect(on_production_started)
	if not EventBus.production_progressed.is_connected(on_production_progressed):
		EventBus.production_progressed.connect(on_production_progressed)
	if not EventBus.production_completed.is_connected(on_production_completed):
		EventBus.production_completed.connect(on_production_completed)

	# Initialize slots from BakeryManager count
	_initialize_slots()


func _initialize_slots() -> void:
	var total_slots = BakeryManager.get_max_slots()
	for i in range(total_slots):
		_get_or_create_slot(i)

	# Update existing slots state if any
	var active_slots = BakeryManager.get_slots()
	for slot_data in active_slots:
		var slot_ui = get_slot_ui(slot_data.slot_index)
		if slot_ui:
			if slot_data.is_completed:
				slot_ui.set_completed(
					slot_data.recipe.get_display_name_or_id() if slot_data.recipe else ""
				)
			elif slot_data.is_active:
				slot_ui.set_production(
					slot_data.recipe.get_display_name_or_id() if slot_data.recipe else ""
				)
				slot_ui.set_progress(slot_data.progress)


## Get slot UI node for a given slot index.
## Returns ProductionSlot or null if slot does not exist.
func get_slot_ui(slot_index: int) -> Node:
	if _slot_data.has(slot_index):
		return _slot_data[slot_index]
	return null


## Handle production started signal
func on_production_started(slot_index: int, recipe_id: String) -> void:
	var slot := _get_or_create_slot(slot_index)
	slot.set_production(recipe_id)


## Handle production progressed signal
func on_production_progressed(slot_index: int, progress: float) -> void:
	var slot: Node = get_slot_ui(slot_index)
	if slot != null:
		slot.set_progress(progress)


## Handle production completed signal
func on_production_completed(slot_index: int, recipe_id: String) -> void:
	var slot := _get_or_create_slot(slot_index)
	slot.set_completed(recipe_id)


## Get or create slot UI container
func _get_or_create_slot(slot_index: int) -> Node:
	if _slot_data.has(slot_index):
		return _slot_data[slot_index]

	var slot = slot_scene.instantiate()
	_container.add_child(slot)
	slot.setup(slot_index)
	var callback := _on_slot_button_pressed.bind(slot_index)
	if not slot.pressed.is_connected(callback):
		slot.pressed.connect(callback)

	_slot_data[slot_index] = slot
	return slot


## Handle slot button press
func _on_slot_button_pressed(slot_index: int) -> void:
	slot_clicked.emit(slot_index)
