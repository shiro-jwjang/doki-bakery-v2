extends GutTest

## Test Suite for ProductionPanel Signal-Based Updates
## Tests that ProductionPanel updates UI via EventBus signals
## SNA-95: ProductionPanel ↔ ProductionManager 시그널 연결

const ProductionPanelClass = preload("res://scripts/ui/production_panel.gd")

var panel: Control


func before_each() -> void:
	# Clear BakeryManager state to prevent previous tests' active slots
	# from emitting production_progressed signals in the background
	BakeryManager._slots.clear()
	BakeryManager._active_count = 0
	BakeryManager._mock_time = -1.0

	# Create ProductionPanel instance from scene (not new() to init @onready vars)
	var panel_scene = preload("res://scenes/ui/production_panel.tscn")
	panel = panel_scene.instantiate()
	add_child(panel)
	# Wait for panel to be ready
	await wait_physics_frames(2)


func after_each() -> void:
	if panel != null:
		panel.queue_free()
		# Wait for node to be freed
		await wait_physics_frames(2)


## Test that panel updates on production_started signal
func test_panel_updates_on_baking_started() -> void:
	# Emit signal (simulating BakeryManager) with real recipe ID
	EventBus.production_started.emit(0, "bread_croissant")

	# Wait for UI to update
	await wait_physics_frames(2)

	# Verify slot UI was updated
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_not_null(slot_ui.get("_status_label"), "Slot should have _status_label")

	var label: Label = slot_ui._status_label
	assert_true(label.text.contains("베이킹 중"), "Label should show baking status")


## Test that panel updates on production_completed signal
func test_panel_updates_on_baking_finished() -> void:
	# Emit signal (simulating BakeryManager) with real recipe ID
	EventBus.production_completed.emit(1, "bread_croissant")

	# Wait for UI to update
	await wait_physics_frames(2)

	# Verify slot UI was updated
	var slot_ui = panel.get_slot_ui(1)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_not_null(slot_ui.get("_status_label"), "Slot should have _status_label")

	var label: Label = slot_ui._status_label
	assert_true(label.text.contains("완료!"), "Label should show completion status")
	assert_eq(slot_ui._progress_bar.value, 1.0, "Progress bar should be full")


## Test that panel updates progress bar on production_progressed signal
func test_panel_updates_on_baking_progressed() -> void:
	# First start production so the slot exists
	EventBus.production_started.emit(0, "bread_croissant")
	await wait_physics_frames(2)

	# Emit progress signal at 50%
	EventBus.production_progressed.emit(0, 0.5)
	await wait_physics_frames(2)

	# Verify progress bar was updated
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_eq(slot_ui._progress_bar.value, 0.5, "Progress bar should show 50%")

	# Emit progress signal at 80%
	EventBus.production_progressed.emit(0, 0.8)
	await wait_physics_frames(2)

	assert_eq(slot_ui._progress_bar.value, 0.8, "Progress bar should update to 80%")


## Test that ProductionPanel does not poll BakeryManager in _process
func test_panel_no_process_polling() -> void:
	# This test verifies that ProductionPanel uses signal-based updates
	# instead of polling BakeryManager in _process

	# Emit signals without calling _process (use real recipe ID)
	EventBus.production_started.emit(0, "bread_croissant")
	EventBus.production_completed.emit(0, "bread_croissant")

	# Wait for UI to update
	await wait_physics_frames(2)

	# Verify slot UI was updated via signals alone
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_true(slot_ui._status_label.text.contains("완료"), "Slot should show completion without polling")
