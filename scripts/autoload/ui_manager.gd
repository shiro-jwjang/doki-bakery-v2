extends Node

signal screen_changed(scene_name: String)

@export var scenes: Dictionary = {}


func change_screen(scene_name: String) -> void:
	if not scenes.has(scene_name):
		push_error("UIManager: Scene name not found - ", scene_name)
		return

	# Try to load game if GameManager is available (it handles its own caching/loading state)
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr and game_mgr.has_method("load_game"):
		game_mgr.load_game()

	var path: String = scenes[scene_name]
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("UIManager: Failed to load scene ", path, " with error code ", err)
	else:
		screen_changed.emit(scene_name)
