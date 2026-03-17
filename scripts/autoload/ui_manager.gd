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
		GameManager.set_state(save_data.get("game", {}))

	var path: String = scenes[scene_name]
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("UIManager: Failed to load scene ", path, " with error code ", err)
	else:
		screen_changed.emit(scene_name)
