class_name UIEventRouter
extends Node

## UIEventRouter
##
## Manages EventBus signal connections and forwards events to UI components.
##
## SNA-186: EventBus → UI 신호 전달 전담
##
## Responsibilities:
## - Connect EventBus signals to UI component methods
## - Forward EventBus events to appropriate UI components
## - Manage EventBus signal lifecycle

## Reference to UIComponentRegistry for accessing UI components
var _component_registry: Node = null

## Direct component references (for testing/backward compatibility)
var _direct_components: Dictionary = {}

## Flag indicating if EventBus connections have been established
var _connections_established: bool = false


## Connect all EventBus signals to UI component handlers.
func connect_event_bus() -> void:
	connect_event_bus_signals()


## Connect UI component signals (alias for compatibility)
func connect_ui_signals() -> void:
	# Reserved for future UI signal connections
	pass


## Connect all EventBus signals to UI component handlers.
func connect_event_bus_signals() -> void:
	# Gold/XP changes → HUD
	if not EventBusAutoload.gold_changed.is_connected(_on_gold_changed):
		EventBusAutoload.gold_changed.connect(_on_gold_changed)

	if not EventBusAutoload.experience_changed.is_connected(_on_experience_changed):
		EventBusAutoload.experience_changed.connect(_on_experience_changed)

	if not EventBusAutoload.level_up.is_connected(_on_level_up):
		EventBusAutoload.level_up.connect(_on_level_up)

	# Premium currency changes → HUD
	if not EventBusAutoload.premium_changed.is_connected(_on_premium_changed):
		EventBusAutoload.premium_changed.connect(_on_premium_changed)

	# Production events → ProductionPanel
	if not EventBusAutoload.production_started.is_connected(_on_production_started):
		EventBusAutoload.production_started.connect(_on_production_started)

	if not EventBusAutoload.production_progressed.is_connected(_on_production_progressed):
		EventBusAutoload.production_progressed.connect(_on_production_progressed)

	if not EventBusAutoload.production_completed.is_connected(_on_production_completed):
		EventBusAutoload.production_completed.connect(_on_production_completed)

	# Baking finished → DisplaySlots
	if not EventBusAutoload.baking_finished.is_connected(_on_baking_finished):
		EventBusAutoload.baking_finished.connect(_on_baking_finished)

	if not EventBusAutoload.production_cleared.is_connected(_on_production_cleared):
		EventBusAutoload.production_cleared.connect(_on_production_cleared)

	if not EventBusAutoload.bread_sold.is_connected(_on_bread_sold):
		EventBusAutoload.bread_sold.connect(_on_bread_sold)

	_connections_established = true


## Validate that all required EventBus connections are established.
## Returns a dictionary with validation results.
func validate_connections() -> Dictionary:
	var results: Dictionary = {}

	# Check EventBus signal connections
	results["gold_changed_connected"] = EventBusAutoload.gold_changed.is_connected(_on_gold_changed)
	results["premium_changed_connected"] = EventBusAutoload.premium_changed.is_connected(
		_on_premium_changed
	)
	results["experience_changed_connected"] = EventBusAutoload.experience_changed.is_connected(
		_on_experience_changed
	)
	results["production_started_connected"] = EventBusAutoload.production_started.is_connected(
		_on_production_started
	)
	results["production_completed_connected"] = EventBusAutoload.production_completed.is_connected(
		_on_production_completed
	)

	# Overall status
	results["all_connected"] = _connections_established

	return results


## Set the component registry for accessing UI components.
func set_component_registry(p_registry: Node) -> void:
	_component_registry = p_registry


## Get the component registry.
func get_component_registry() -> Node:
	return _component_registry


# ==================== Helper Methods ====================


## Safely call a method on a component if it exists.
## This helper method reduces boilerplate for has_method + call pattern.
## Parameters:
## - component: The Node to call the method on (can be null)
## - method_name: The name of the method to call
## - args: Array of arguments to pass to the method (optional)
func call_safe_method(component: Node, method_name: String, args: Array = []) -> void:
	if component and component.has_method(method_name):
		component.callv(method_name, args)


# ==================== EventBus Signal Handlers ====================


## Forward gold changes to HUD
func _on_gold_changed(old: int, new: int) -> void:
	call_safe_method(get_hud(), "_on_gold_changed", [old, new])


## Forward premium changes to HUD
func _on_premium_changed(_old: int, new: int) -> void:
	call_safe_method(get_hud(), "_on_premium_changed", [_old, new])


## Forward XP changes to HUD
func _on_experience_changed(old: int, new: int) -> void:
	call_safe_method(get_hud(), "_on_experience_changed", [old, new])


## Forward level up to HUD
func _on_level_up(new_level: int) -> void:
	call_safe_method(get_hud(), "_on_level_up", [new_level])


## Forward production started to ProductionPanel
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	call_safe_method(get_production_panel(), "on_production_started", [slot_index, recipe_id])


## Forward production progress to ProductionPanel
func _on_production_progressed(slot_index: int, progress: float) -> void:
	call_safe_method(get_production_panel(), "on_production_progressed", [slot_index, progress])


## Forward production completed to ProductionPanel
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	call_safe_method(get_production_panel(), "on_production_completed", [slot_index, recipe_id])


## Forward baking finished to DisplaySlots (find empty slot and fill)
func _on_baking_finished(recipe_id: String) -> void:
	var slots = get_display_slots()
	if slots and slots.has_method("get_empty_slot"):
		var empty_slot = slots.get_empty_slot()
		if empty_slot and empty_slot.has_method("setup"):
			var recipe = DataManager.get_recipe(recipe_id)
			if recipe:
				empty_slot.setup(recipe_id, recipe.base_price)


## Forward bread sold to DisplaySlots
func _on_bread_sold(recipe_id: String, price: int) -> void:
	call_safe_method(get_display_slots(), "on_bread_sold", [recipe_id, price])


## Handle production cleared signal -> Reset Slot UI to Empty
func _on_production_cleared(slot_index: int) -> void:
	var panel = get_production_panel()
	if panel and panel.has_method("get_slot_ui"):
		var slot_ui = panel.get_slot_ui(slot_index)
		if slot_ui and slot_ui.has_method("setup"):
			slot_ui.setup(slot_index)


# ==================== Backward Compatibility Setters/Getters ====================
## These methods support the old direct reference pattern used in tests


## Set HUD component directly (for testing/backward compatibility)
func set_hud(hud: Node) -> void:
	_direct_components["hud"] = hud


## Get HUD component (checks registry then direct reference)
func get_hud() -> Node:
	if _component_registry and _component_registry.has_method("get_hud"):
		return _component_registry.get_hud()
	return _direct_components.get("hud")


## Set ProductionPanel component directly (for testing/backward compatibility)
func set_production_panel(panel: Node) -> void:
	_direct_components["production_panel"] = panel


## Get ProductionPanel component (checks registry then direct reference)
func get_production_panel() -> Node:
	if _component_registry and _component_registry.has_method("get_production_panel"):
		return _component_registry.get_production_panel()
	return _direct_components.get("production_panel")


## Set DisplaySlots component directly (for testing/backward compatibility)
func set_display_slots(slots: Node) -> void:
	_direct_components["display_slots"] = slots


## Get DisplaySlots component (checks registry then direct reference)
func get_display_slots() -> Node:
	if _component_registry and _component_registry.has_method("get_display_slots"):
		return _component_registry.get_display_slots()
	return _direct_components.get("display_slots")


## Set BreadMenu component directly (for testing/backward compatibility)
func set_bread_menu(menu: Node) -> void:
	_direct_components["bread_menu"] = menu


## Get BreadMenu component (checks registry then direct reference)
func get_bread_menu() -> Node:
	if _component_registry and _component_registry.has_method("get_bread_menu"):
		return _component_registry.get_bread_menu()
	return _direct_components.get("bread_menu")
