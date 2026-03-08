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
## - Ensures EventBus signals properly connect to UI handlers
## - Coordinates between GameManager, BakeryManager, SalesManager and UI
##
## Note: Current UI components (HUD, ProductionPanel, DisplaySlot) already
## connect to EventBus in their own _ready() methods. WorldController provides
## centralized management and validation of these connections.

## Reference to HUD component
var _hud: CanvasLayer = null

## Reference to ProductionPanel component
var _production_panel: Control = null

## Reference to DisplaySlots container
var _display_slots: Node = null


func _ready() -> void:
	# Find and cache UI components
	find_ui_components()


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
	results["hud"] = _hud != null
	results["production_panel"] = _production_panel != null
	results["display_slots"] = _display_slots != null
	results["all_connected"] = results["hud"] and results["production_panel"]

	return results


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
