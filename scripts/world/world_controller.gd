extends Node

## WorldController
##
## Central controller for WorldView that manages UI components and
## ensures proper EventBus signal wiring between Autoload managers
## and WorldView child nodes.
##
## SNA-98: EventBus 중앙 배선 스크립트
##
## Responsibilities:
## - Manages UI components within WorldView hierarchy
## - Connects EventBus signals to UI component methods
## - Coordinates between GameManager, BakeryManager, SalesManager and UI

## Reference to HUD component
var _hud: CanvasLayer = null

## Reference to ProductionPanel component
var _production_panel: Control = null

## Reference to DisplaySlots container
var _display_slots: Node = null

## Flag indicating if EventBus connections have been established
var _connections_established: bool = false


func _ready() -> void:
	# Find and cache UI components
	find_ui_components()
	# Connect EventBus signals to UI handlers
	_connect_event_bus_signals()


## Connect EventBus signals to this controller for forwarding to UI.
func _connect_event_bus_signals() -> void:
	# Gold/XP changes → HUD
	if not EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.connect(_on_gold_changed)

	if not EventBus.xp_changed.is_connected(_on_xp_changed):
		EventBus.xp_changed.connect(_on_xp_changed)

	if not EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.connect(_on_level_up)

	# Production events → ProductionPanel
	if not EventBus.production_started.is_connected(_on_production_started):
		EventBus.production_started.connect(_on_production_started)

	if not EventBus.production_progressed.is_connected(_on_production_progressed):
		EventBus.production_progressed.connect(_on_production_progressed)

	if not EventBus.production_completed.is_connected(_on_production_completed):
		EventBus.production_completed.connect(_on_production_completed)

	# Baking finished → DisplaySlots
	if not EventBus.baking_finished.is_connected(_on_baking_finished):
		EventBus.baking_finished.connect(_on_baking_finished)

	if not EventBus.bread_sold.is_connected(_on_bread_sold):
		EventBus.bread_sold.connect(_on_bread_sold)

	_connections_established = true


## Find and cache UI components within WorldView hierarchy.
## Returns a dictionary with found components.
func find_ui_components() -> Dictionary:
	var components: Dictionary = {}

	# Look for HUD in parent or siblings
	var parent := get_parent()
	if parent:
		# Check siblings
		for sibling in parent.get_children():
			if sibling == self:
				continue
			if sibling is CanvasLayer and sibling.name.to_lower().contains("hud"):
				_hud = sibling
				components["hud"] = _hud
			elif sibling is Control:
				if sibling.name.to_lower().contains("production"):
					_production_panel = sibling
					components["production_panel"] = _production_panel
				elif sibling.name.to_lower().contains("display"):
					_display_slots = sibling
					components["display_slots"] = _display_slots

	# Also search in scene tree for autoload-style HUD
	if _hud == null:
		var tree := get_tree()
		if tree and tree.root:
			for child in tree.root.get_children():
				if child is CanvasLayer and child.name.to_lower().contains("hud"):
					_hud = child
					components["hud"] = _hud
					break

	return components


## Validate that all required EventBus connections are established.
## Returns a dictionary with validation results.
func validate_connections() -> Dictionary:
	var results: Dictionary = {}

	# Check EventBus signal connections
	results["gold_changed_connected"] = EventBus.gold_changed.is_connected(_on_gold_changed)
	results["xp_changed_connected"] = EventBus.xp_changed.is_connected(_on_xp_changed)
	results["production_started_connected"] = EventBus.production_started.is_connected(
		_on_production_started
	)
	results["production_completed_connected"] = EventBus.production_completed.is_connected(
		_on_production_completed
	)

	# Check UI component presence
	results["hud"] = _hud != null
	results["production_panel"] = _production_panel != null
	results["display_slots"] = _display_slots != null

	# Overall status
	results["all_connected"] = _connections_established

	return results


# ==================== EventBus Signal Handlers ====================


## Forward gold changes to HUD
func _on_gold_changed(old: int, new: int) -> void:
	if _hud and _hud.has_method("update_gold"):
		_hud.update_gold(old, new)


## Forward XP changes to HUD
func _on_xp_changed(old: int, new: int) -> void:
	if _hud and _hud.has_method("update_xp"):
		_hud.update_xp(old, new)


## Forward level up to HUD
func _on_level_up(new_level: int) -> void:
	if _hud and _hud.has_method("update_level"):
		_hud.update_level(new_level)


## Forward production started to ProductionPanel
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	if _production_panel and _production_panel.has_method("on_production_started"):
		_production_panel.on_production_started(slot_index, recipe_id)


## Forward production progress to ProductionPanel
func _on_production_progressed(slot_index: int, progress: float) -> void:
	if _production_panel and _production_panel.has_method("on_production_progressed"):
		_production_panel.on_production_progressed(slot_index, progress)


## Forward production completed to ProductionPanel
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	if _production_panel and _production_panel.has_method("on_production_completed"):
		_production_panel.on_production_completed(slot_index, recipe_id)


## Forward baking finished to DisplaySlots
func _on_baking_finished(recipe_id: String) -> void:
	if _display_slots and _display_slots.has_method("on_baking_finished"):
		_display_slots.on_baking_finished(recipe_id)


## Forward bread sold to DisplaySlots
func _on_bread_sold(recipe_id: String, price: int) -> void:
	if _display_slots and _display_slots.has_method("on_bread_sold"):
		_display_slots.on_bread_sold(recipe_id, price)


# ==================== Getters/Setters ====================


## Get the HUD component reference.
func get_hud() -> Variant:
	return _hud


## Get the ProductionPanel component reference.
func get_production_panel() -> Variant:
	return _production_panel


## Get the DisplaySlots container reference.
func get_display_slots() -> Variant:
	return _display_slots


## Manually set HUD reference (useful for testing).
func set_hud(hud: CanvasLayer) -> void:
	_hud = hud


## Manually set ProductionPanel reference (useful for testing).
func set_production_panel(panel: Control) -> void:
	_production_panel = panel


## Manually set DisplaySlots reference (useful for testing).
func set_display_slots(slots: Node) -> void:
	_display_slots = slots
