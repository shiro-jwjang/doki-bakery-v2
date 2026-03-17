extends GutTest

## Test Suite for HUD Gold Popup
## Tests that gold popups appear when gold changes
## SNA-94: HUD 골드 변동 팝업 애니메이션

var hud: Node


func before_each() -> void:
	# Reset GameManager state
	GameManager.gold = 100


func after_each() -> void:
	if hud != null and is_instance_valid(hud):
		hud.queue_free()
		hud = null


## Helper: Check if scene loading is possible (requires display)
func _can_load_scenes() -> bool:
	return DisplayServer.get_name() != "headless"


## Test that GoldPopup is spawned when gold changes
func test_gold_popup_spawns_on_gold_change() -> void:
	#if not _can_load_scenes():
	#	pending("HUD tests require GUI mode")
	#	return

	var hud_scene = preload("res://scenes/ui/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	# Trigger gold change
	GameManager.add_gold(50)
	await wait_physics_frames(5)

	# Search for GoldPopup in HUD children
	var popup = _find_gold_popup(hud)
	assert_not_null(popup, "GoldPopup should be spawned when gold changes")


## Test that popup shows correct text for positive change
func test_gold_popup_shows_positive_amount() -> void:
	#if not _can_load_scenes():
	#	pending("HUD tests require GUI mode")
	#	return

	var hud_scene = preload("res://scenes/ui/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	GameManager.add_gold(30)
	await wait_physics_frames(5)

	var popup = _find_gold_popup(hud)
	if popup == null:
		fail_test("GoldPopup not found")
		return

	var label = popup.get_node_or_null("Label")
	assert_not_null(label, "Popup must have a Label")
	assert_eq(label.text, "+30G ↑", "Should show positive amount with arrow")
	assert_eq(label.modulate, Color.GREEN, "Positive amount should be green")


## Test that popup shows correct text for negative change
func test_gold_popup_shows_negative_amount() -> void:
	#if not _can_load_scenes():
	#	pending("HUD tests require GUI mode")
	#	return

	var hud_scene = preload("res://scenes/ui/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	GameManager.spend_gold(10)
	await wait_physics_frames(5)

	var popup = _find_gold_popup(hud)
	if popup == null:
		fail_test("GoldPopup not found")
		return

	var label = popup.get_node_or_null("Label")
	assert_eq(label.text, "-10G ↓", "Should show negative amount with arrow")
	assert_eq(label.modulate, Color.RED, "Negative amount should be red")


## Test that popup disappears after a delay
func test_gold_popup_auto_disappears() -> void:
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)
	await wait_physics_frames(2)

	# Set short lifetime for testing before triggering
	hud.gold_popup_lifetime = 0.5

	GameManager.add_gold(10)
	# Wait enough frames for signal propagation and node creation
	await wait_physics_frames(10)

	var popup = _find_gold_popup(hud)
	assert_not_null(popup, "Popup should exist initially")

	# Wait for lifetime (0.5s) + buffer
	await wait_seconds(0.8)

	assert_true(not is_instance_valid(popup), "Popup should be freed after delay")


## Helper: Find GoldPopup node in parent's children
func _find_gold_popup(parent: Node) -> Node:
	print("HUD children: ")
	for child in parent.get_children():
		print("- ", child.name)
		if child.name.begins_with("GoldPopup"):
			return child
	return null
