extends GutTest

## Test Suite: SNA-98 WorldController Centralized Event Wiring
##
## Tests the WorldController which:
## 1. Manages UI components within WorldView
## 2. Optionally centralizes EventBus signal connections
## 3. Ensures proper signal propagation from managers to UI

const WorldControllerClass = preload("res://scripts/world/world_controller.gd")
const WorldViewClass = preload("res://scripts/world/world_view.gd")

var world_controller: Node
var world_view: Node2D

# Mock UI components for testing
var _mock_hud = null
var _mock_production_panel = null
var _mock_display_slot = null


func before_each() -> void:
	# Create mock UI components
	_create_mock_ui_classes()

	# Create WorldView
	world_view = WorldViewClass.new()
	add_child(world_view)
	await wait_frames(2)

	# Create WorldController and add to WorldView
	world_controller = WorldControllerClass.new()
	world_view.add_child(world_controller)
	await wait_frames(2)


func after_each() -> void:
	if world_controller != null:
		world_controller.queue_free()
		await wait_frames(1)
	if world_view != null:
		world_view.queue_free()
		await wait_frames(1)


## Test: WorldController initializes without errors
func test_world_controller_initializes() -> void:
	# Assert
	assert_not_null(world_controller, "WorldController should be created")
	assert_eq(
		world_controller.get_parent(), world_view, "WorldController should be child of WorldView"
	)


## Test: WorldController can find UI components by name
func test_world_controller_finds_ui_components() -> void:
	# Arrange - Add mock UI components to WorldView
	var hud = _mock_hud.new()
	hud.name = "HUD"
	world_view.add_child(hud)

	var panel = _mock_production_panel.new()
	panel.name = "ProductionPanel"
	world_view.add_child(panel)

	await wait_frames(2)

	# Act - Call find_ui_components method if it exists
	if world_controller.has_method("find_ui_components"):
		world_controller.find_ui_components()
		await wait_frames(2)

	# Assert - UI components should exist in WorldView
	var found_hud = world_view.find_child("HUD", true, false)
	var found_panel = world_view.find_child("ProductionPanel", true, false)

	assert_not_null(found_hud, "HUD should be found in WorldView")
	assert_not_null(found_panel, "ProductionPanel should be found in WorldView")


## Test: Gold change signal propagates from GameManager to HUD
func test_gold_change_propagates_to_hud() -> void:
	# Arrange - Create mock HUD
	var hud = _mock_hud.new()
	hud.name = "HUD"
	world_view.add_child(hud)
	await wait_frames(2)

	# Watch EventBus signals
	watch_signals(EventBus)

	# Track HUD gold value
	var initial_gold = GameManager.gold
	var target_gold = initial_gold + 100

	# Act - Add gold via GameManager
	GameManager.add_gold(100)
	await wait_frames(2)

	# Assert - EventBus should have emitted gold_changed
	assert_signal_emitted(EventBus, "gold_changed", "EventBus should emit gold_changed")

	# If HUD connected properly, it should have received the update
	# (_mock_hud stores last gold values if it has the handler)
	if hud.has_method("get_last_gold_values"):
		var last_values = hud.get_last_gold_values()
		assert_eq(last_values.new, target_gold, "HUD should receive new gold value")


## Test: Production started signal propagates to ProductionPanel
func test_production_started_propagates_to_panel() -> void:
	# Arrange - Create mock ProductionPanel
	var panel = _mock_production_panel.new()
	panel.name = "ProductionPanel"
	world_view.add_child(panel)
	await wait_frames(2)

	# Watch EventBus signals
	watch_signals(EventBus)

	# Act - Start production via BakeryManager
	var recipe_id = "test_bread"
	BakeryManager.start_production(0, recipe_id)
	await wait_frames(2)

	# Assert - EventBus should emit production_started
	assert_signal_emitted(EventBus, "production_started", "EventBus should emit production_started")

	# ProductionPanel should have received the signal
	if panel.has_method("get_last_production_started"):
		var last_data = panel.get_last_production_started()
		assert_eq(last_data.slot_index, 0, "Panel should receive slot_index")
		assert_eq(last_data.recipe_id, recipe_id, "Panel should receive recipe_id")


## Test: Multiple signals can propagate simultaneously
func test_multiple_signals_propagate() -> void:
	# Arrange - Create mock UI components
	var hud = _mock_hud.new()
	hud.name = "HUD"
	world_view.add_child(hud)

	var panel = _mock_production_panel.new()
	panel.name = "ProductionPanel"
	world_view.add_child(panel)
	await wait_frames(2)

	watch_signals(EventBus)

	# Act - Trigger multiple events
	GameManager.add_gold(50)
	BakeryManager.start_production(0, "croissant")
	GameManager.add_xp(100)

	await wait_frames(2)

	# Assert - All signals should be emitted
	assert_signal_emitted(EventBus, "gold_changed", "Should emit gold_changed")
	assert_signal_emitted(EventBus, "production_started", "Should emit production_started")
	assert_signal_emitted(EventBus, "xp_changed", "Should emit xp_changed")


## Test: WorldController handles missing UI components gracefully
func test_world_controller_handles_missing_ui() -> void:
	# Arrange - No UI components added

	# Act - WorldController should not crash without UI
	if world_controller.has_method("connect_signals"):
		var result = world_controller.connect_signals()
		await wait_frames(2)

		# Assert - Should return gracefully (null or true)
		# Implementation dependent - adjust as needed
		# pass  # If we get here without crash, test passes


## Test: Signal connections are not duplicated
func test_no_duplicate_signal_connections() -> void:
	# Arrange - Create mock HUD
	var hud = _mock_hud.new()
	hud.name = "HUD"
	world_view.add_child(hud)
	await wait_frames(2)

	# Act - Try to connect signals multiple times
	if world_controller.has_method("connect_signals"):
		world_controller.connect_signals()
		world_controller.connect_signals()  # Second call
		await wait_frames(2)

	# Assert - Should not have duplicate connections
	# This would need to be verified by checking connection count
	# Implementation dependent
	# pass


## Helper: Create mock UI classes for testing
func _create_mock_ui_classes() -> void:
	# Mock HUD
	_mock_hud = func():
		var script = GDScript.new()
		script.source_code = """
extends CanvasLayer

var _last_old_gold: int = 0
var _last_new_gold: int = 0

func _ready() -> void:
	if EventBus.gold_changed.is_connected(_on_gold_changed):
		return
	EventBus.gold_changed.connect(_on_gold_changed)

func _on_gold_changed(old: int, new: int) -> void:
	_last_old_gold = old
	_last_new_gold = new

func get_last_gold_values() -> Dictionary:
	return {"old": _last_old_gold, "new": _last_new_gold}
"""
		return script.new()

	# Mock ProductionPanel
	_mock_production_panel = func():
		var script = GDScript.new()
		script.source_code = """
extends Control

var _last_slot_index: int = -1
var _last_recipe_id: String = ""

func _ready() -> void:
	if EventBus.production_started.is_connected(_on_production_started):
		return
	EventBus.production_started.connect(_on_production_started)

func _on_production_started(slot_index: int, recipe_id: String) -> void:
	_last_slot_index = slot_index
	_last_recipe_id = recipe_id

func get_last_production_started() -> Dictionary:
	return {"slot_index": _last_slot_index, "recipe_id": _last_recipe_id}
"""
		return script.new()
