extends Node

## UIComponentRegistry
##
## Manages UI component references and finding within WorldView hierarchy.
##
## SNA-186: UI 컴포넌트 관리 클래스
##
## Responsibilities:
## - Find and cache UI components within WorldView hierarchy
## - Provide getter/setter methods for UI components
## - Manage UI component lifecycle

## Root node for finding UI components (typically WorldView)
var _root_node: Node = null

## UI Component references
var _hud: Control = null
var _production_panel: Control = null
var _display_slots: Node = null
var _bread_menu: Control = null


## Find and cache UI components within WorldView hierarchy.
## Returns a dictionary with found components.
func find_components() -> Dictionary:
	var components: Dictionary = {}

	# If variables are already assigned via Inspector/setters, use them
	if not _hud:
		_hud = _find_node_relative("../UI/HUD")
	if not _production_panel:
		_production_panel = _find_node_relative("../UI/ProductionPanel")
	if not _display_slots:
		_display_slots = _find_node_relative("../UI/DisplaySlots")
	if not _bread_menu:
		_bread_menu = _find_node_relative("../UI/BreadMenu")

	if _hud:
		components["hud"] = _hud
	if _production_panel:
		components["production_panel"] = _production_panel
	if _display_slots:
		components["display_slots"] = _display_slots
	if _bread_menu:
		components["bread_menu"] = _bread_menu

	return components


## Set the root node for finding UI components.
func set_root_node(node: Node) -> void:
	_root_node = node


## Get the HUD component reference.
func get_hud() -> Control:
	return _hud


## Get the ProductionPanel component reference.
func get_production_panel() -> Control:
	return _production_panel


## Get the DisplaySlots container reference.
func get_display_slots() -> Node:
	return _display_slots


## Get the BreadMenu component reference.
func get_bread_menu() -> Control:
	return _bread_menu


## Set HUD reference.
func set_hud(p_hud: Control) -> void:
	_hud = p_hud


## Set ProductionPanel reference.
func set_production_panel(p_panel: Control) -> void:
	_production_panel = p_panel


## Set DisplaySlots reference.
func set_display_slots(p_slots: Node) -> void:
	_display_slots = p_slots


## Set BreadMenu reference.
func set_bread_menu(p_menu: Control) -> void:
	_bread_menu = p_menu


## Get all components as a dictionary.
func get_all_components() -> Dictionary:
	var components: Dictionary = {}
	if _hud:
		components["hud"] = _hud
	if _production_panel:
		components["production_panel"] = _production_panel
	if _display_slots:
		components["display_slots"] = _display_slots
	if _bread_menu:
		components["bread_menu"] = _bread_menu
	return components


## Check if HUD is set.
func has_hud() -> bool:
	return _hud != null


## Check if ProductionPanel is set.
func has_production_panel() -> bool:
	return _production_panel != null


## Check if DisplaySlots is set.
func has_display_slots() -> bool:
	return _display_slots != null


## Check if BreadMenu is set.
func has_bread_menu() -> bool:
	return _bread_menu != null


## Helper to find node relative to root node.
func _find_node_relative(path: String) -> Node:
	if not _root_node:
		return null

	return _root_node.get_node_or_null(path)
