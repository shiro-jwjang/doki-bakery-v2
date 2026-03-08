extends GutTest

## Test Suite for ProductionPanel Signal-Based Updates
## Tests that ProductionPanel updates UI via EventBus signals
## SNA-95: ProductionPanel ↔ ProductionManager 시그널 연결

const ProductionPanelClass = preload("res://scripts/ui/production_panel.gd")

var panel: Control


func before_each() -> void:
	# Create ProductionPanel instance
	panel = ProductionPanelClass.new()
	add_child(panel)
	# Wait for panel to be ready
	await wait_frames(2)


func after_each() -> void:
	if panel != null:
		panel.queue_free()
		# Wait for node to be freed
		await wait_frames(2)


## Test that panel updates on production_started signal
func test_panel_updates_on_baking_started() -> void:
	# Emit signal (simulating BakeryManager)
	EventBus.production_started.emit(0, "test_bread")

	# Wait for UI to update
	await wait_frames(2)

	# Verify slot UI was updated
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_not_null(slot_ui.get("label"), "Slot should have a label")

	var label: Label = slot_ui.label
	assert_true(label.text.contains("베이킹 중"), "Label should show baking status")
	assert_true(label.text.contains("test_bread"), "Label should show recipe ID")


## Test that panel updates on production_completed signal
func test_panel_updates_on_baking_finished() -> void:
	# Emit signal (simulating BakeryManager)
	EventBus.production_completed.emit(1, "test_bread")

	# Wait for UI to update
	await wait_frames(2)

	# Verify slot UI was updated
	var slot_ui = panel.get_slot_ui(1)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_not_null(slot_ui.get("label"), "Slot should have a label")

	var label: Label = slot_ui.label
	assert_true(label.text.contains("완료!"), "Label should show completion status")
	assert_eq(slot_ui.progress_bar.value, 1.0, "Progress bar should be full")


## Test that panel updates progress bar on production_progressed signal
func test_panel_updates_on_baking_progressed() -> void:
	# First start production so the slot exists
	EventBus.production_started.emit(0, "test_bread")
	await wait_frames(2)

	# Emit progress signal at 50%
	EventBus.production_progressed.emit(0, 0.5)
	await wait_frames(2)

	# Verify progress bar was updated
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_eq(slot_ui.progress_bar.value, 0.5, "Progress bar should show 50%")

	# Emit progress signal at 80%
	EventBus.production_progressed.emit(0, 0.8)
	await wait_frames(2)

	assert_eq(slot_ui.progress_bar.value, 0.8, "Progress bar should update to 80%")


## Test that ProductionPanel does not poll BakeryManager in _process
func test_panel_no_process_polling() -> void:
	# This test verifies that ProductionPanel uses signal-based updates
	# instead of polling BakeryManager in _process

	# Emit signals without calling _process
	EventBus.production_started.emit(0, "bread_01")
	EventBus.production_completed.emit(0, "bread_01")

	# Wait for UI to update
	await wait_frames(2)

	# Verify slot UI was updated via signals alone
	var slot_ui = panel.get_slot_ui(0)
	assert_not_null(slot_ui, "Slot UI should exist")
	assert_true(slot_ui.label.text.contains("완료"), "Slot should show completion without polling")
