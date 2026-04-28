extends Node

signal screen_changed(scene_name: String)

@export var scenes: Dictionary = {}


func change_screen(scene_name: String) -> void:
	if not scenes.has(scene_name):
		push_error("UIManager: Scene name not found - ", scene_name)
		return

	# SNA-189: Load game using SaveManager.load_from_disk() and GameManager.set_state()
	var save_data := SaveManager.load_from_disk()
	if not save_data.is_empty():
		GameManager.set_state(save_data.get("game", {}), int(save_data.get("version", 1)))
		if SalesManager.has_method("load_save_state"):
			SalesManager.load_save_state(save_data.get("sales", {}))
		if BakeryManager.has_method("load_save_state"):
			BakeryManager.load_save_state(save_data.get("bakery", {}))
		if SaveManager.has_method("apply_offline_progress"):
			SaveManager.apply_offline_progress(save_data)

	# Set game state to playing when entering world_view
	if scene_name == "world_view":
		GameManager.set_game_state("playing")

	var path: String = scenes[scene_name]
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("UIManager: Failed to load scene ", path, " with error code ", err)
	else:
		screen_changed.emit(scene_name)
