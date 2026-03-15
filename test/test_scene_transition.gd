extends "res://addons/gut/test.gd"

var ui_manager


func before_all() -> void:
	# Need to make sure UIManager exists
	ui_manager = get_node_or_null("/root/UIManager")
	if not ui_manager:
		ui_manager = load("res://scripts/autoload/ui_manager.gd").new()
		ui_manager.name = "UIManager"
		get_tree().root.add_child(ui_manager)


func after_all() -> void:
	# Cleanup if needed
	pass


func test_autoloads_accessible() -> void:
	var game_mgr = get_node_or_null("/root/GameManager")
	assert_not_null(game_mgr, "GameManager autoload should be accessible")

	var ui_mgr = get_node_or_null("/root/UIManager")
	assert_not_null(ui_mgr, "UIManager autoload should be accessible")


func test_title_to_world_transition() -> void:
	var title_scene = load("res://scenes/menus/title.tscn").instantiate()
	add_child_autofree(title_scene)

	# Simulate button press
	watch_signals(ui_manager)
	title_scene._on_start_button_pressed()

	assert_signal_emitted_with_parameters(ui_manager, "screen_changed", ["world_view"])


func test_save_data_loaded_on_transition() -> void:
	# 1. Back up the original GameManager
	var original_gm = get_node_or_null("/root/GameManager")
	if original_gm:
		get_tree().root.remove_child(original_gm)

	# 2. Setup partial double
	var game_manager_script = load("res://scripts/autoload/game_manager.gd")
	var double_game_mgr = partial_double(game_manager_script).new()
	double_game_mgr.name = "GameManager"
	get_tree().root.add_child(double_game_mgr)

	# 3. Test transition
	watch_signals(UIManager)
	UIManager.change_screen("world_view")

	assert_called(double_game_mgr, "load_game")
	assert_signal_emitted(UIManager, "screen_changed")

	# 4. Cleanup and restore
	get_tree().root.remove_child(double_game_mgr)
	double_game_mgr.queue_free()

	if original_gm:
		get_tree().root.add_child(original_gm)
