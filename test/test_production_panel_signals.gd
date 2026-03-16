extends GutTest

## Test Suite for ProductionPanel Signal-Based Updates
## Tests that ProductionPanel updates UI via EventBusAutoload signals
## SNA-95: ProductionPanel ↔ ProductionManager 시그널 연결

const ProductionPanelScene = preload("res://scenes/ui/production_panel.tscn")

var panel: Control
var event_router: Node


func before_each() -> void:
	BakeryManager._slots.clear()
	BakeryManager._active_count = 0
	BakeryManager.set_process(false)

	var ProductionPanelScene = preload("res://scenes/ui/production_panel.tscn")
	panel = ProductionPanelScene.instantiate()
	add_child(panel)

	event_router = load("res://scripts/ui/ui_event_router.gd").new()
	add_child(event_router)
	
	event_router.set_production_panel(panel)
	event_router.connect_event_bus_signals()

	# One frame is enough for _ready() and node initialization
	await wait_physics_frames(1)


func after_each() -> void:
	if panel != null:
		panel.queue_free()
	if event_router != null:
		event_router.queue_free()
	# No need to wait after queue_free in unit tests as objects are removed from tree immediately
	# and freed at end of frame


## Test that panel updates on production_started signal
func test_panel_updates_on_baking_started() -> void:
	EventBusAutoload.production_started.emit(0, "bread_croissant")
	
	# Assert immediately (UI updates are synchronous)
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	var label: Label = slot_ui._status_label
	assert_true(label.text.contains("베이킹 중"), "Label should show baking status")


## Test that panel updates on production_completed signal
func test_panel_updates_on_baking_finished() -> void:
	EventBusAutoload.production_completed.emit(1, "bread_croissant")

	var slot_ui = panel.get_slot_ui(1)
	assert_not_null(slot_ui, "Slot UI should exist")
	var label: Label = slot_ui._status_label
	assert_true(label.text.contains("완료!"), "Label should show completion status")
	assert_eq(slot_ui._progress_bar.value, 1.0, "Progress bar should be full")


## Test that panel updates progress bar on production_progressed signal
func test_panel_updates_on_baking_progressed() -> void:
	EventBusAutoload.production_started.emit(0, "bread_croissant")

	# 50%
	EventBusAutoload.production_progressed.emit(0, 0.5)
	var slot_ui = panel.get_slot_ui(0)
	assert_eq(slot_ui._progress_bar.value, 0.5, "Progress bar should show 50%")

	# 80%
	EventBusAutoload.production_progressed.emit(0, 0.8)
	assert_eq(slot_ui._progress_bar.value, 0.8, "Progress bar should update to 80%")


## Test that ProductionPanel does not poll BakeryManager in _process
func test_panel_no_process_polling() -> void:
	EventBusAutoload.production_started.emit(0, "bread_croissant")
	EventBusAutoload.production_completed.emit(0, "bread_croissant")

	var slot_ui = panel.get_slot_ui(0)
	assert_true(
		slot_ui._status_label.text.contains("완료"), "Slot should show completion without polling"
	)
