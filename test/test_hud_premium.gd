extends GutTest

## Test cases for HUD Premium Currency (legendary_golden_bread) Display

var hud: CanvasLayer
var world_controller: Node

func before_each():
	# Reset GameManager state
	GameManager.legendary_bread = 0
	
	# Instantiate and add HUD to tree
	hud = load("res://scenes/ui/hud.tscn").instantiate()
	add_child_autofree(hud)
	
	# Instantiate and add WorldController, inject HUD
	world_controller = load("res://scripts/world/world_controller.gd").new()
	world_controller.set_hud(hud)
	add_child_autofree(world_controller)
	
	# Wait a frame to ensure all nodes are _ready()
	# Because world_controller uses find_ui_components() and _connect_event_bus_signals() in _ready()

func test_premium_currency_display_initial():
	var premium_label = hud.get_node("Control/GoldenBreadBox/Label")
	assert_not_null(premium_label, "GoldenBreadBox Label should exist")
	assert_eq(premium_label.text, "0", "HUD should display 0 as initial premium currency")

func test_premium_currency_updates():
	var premium_label = hud.get_node("Control/GoldenBreadBox/Label")
	
	# Change premium currency using GameManager setter
	# This should trigger EventBus.premium_changed which routes to HUD via WorldController
	GameManager.legendary_bread = 100
	
	assert_eq(premium_label.text, "100", "HUD should update label text to 100 when premium currency changes")
