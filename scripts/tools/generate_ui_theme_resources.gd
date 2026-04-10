@tool
extends SceneTree

const ATLAS_DIR := "res://assets/ui/atlas"
const GENERATED_DIR := "res://themes/generated"
const CONTROL_MANIFEST := "res://assets/ui/atlas/ui_controls_manifest.json"
const ICON_MANIFEST := "res://assets/ui/atlas/ui_icons_manifest.json"


func _initialize() -> void:
	var control_manifest: Dictionary = _load_manifest(CONTROL_MANIFEST)
	var icon_manifest: Dictionary = _load_manifest(ICON_MANIFEST)

	_ensure_directory("%s/styleboxes" % GENERATED_DIR)
	_ensure_directory("%s/textures" % GENERATED_DIR)
	_ensure_directory("%s/icons" % GENERATED_DIR)

	var control_atlas: Texture2D = _load_png_texture(str(control_manifest.get("atlas", "")))
	var icon_atlas: Texture2D = _load_png_texture(str(icon_manifest.get("atlas", "")))

	if control_atlas == null or icon_atlas == null:
		push_error("UI atlas textures are missing. Run build_ui_atlas.py first.")
		quit(1)
		return

	var control_styles: Dictionary = _build_styleboxes(control_manifest, control_atlas)
	var checkbox_textures: Dictionary = _build_atlas_textures(
		control_manifest,
		control_atlas,
		"%s/textures" % GENERATED_DIR,
		["checkbox_unchecked", "checkbox_checked", "checkbox_blocked", "slider_handle"]
	)
	var icon_textures: Dictionary = _build_atlas_textures(
		icon_manifest, icon_atlas, "%s/icons" % GENERATED_DIR
	)
	print(
		(
			"Generated atlas resources: %d styleboxes, %d control textures, %d icon textures"
			% [control_styles.size(), checkbox_textures.size(), icon_textures.size()]
		)
	)
	quit()


func _load_manifest(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing manifest: %s" % path)
		quit(1)
		return {}

	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Manifest is not a dictionary: %s" % path)
		quit(1)
		return {}

	return data


func _build_styleboxes(manifest: Dictionary, atlas: Texture2D) -> Dictionary:
	var results: Dictionary = {}
	var slots: Dictionary = manifest.get("slots", {})
	for style_name in [
		"button_normal",
		"button_hover",
		"button_pressed",
		"button_disabled",
		"panel_card",
		"panel_line",
		"input_fill",
		"input_outline",
		"progress_bg",
		"progress_fill"
	]:
		if not slots.has(style_name):
			continue

		var slot: Dictionary = slots[style_name]
		var stylebox: StyleBoxTexture = StyleBoxTexture.new()
		stylebox.texture = atlas
		stylebox.region_rect = _rect_from_list(slot["rect"])
		var slice: Array = slot.get("slice", [0, 0, 0, 0])
		stylebox.texture_margin_left = int(slice[0])
		stylebox.texture_margin_top = int(slice[1])
		stylebox.texture_margin_right = int(slice[2])
		stylebox.texture_margin_bottom = int(slice[3])
		stylebox.content_margin_left = max(int(slice[0]) - 2, 6)
		stylebox.content_margin_top = max(int(slice[1]) - 2, 6)
		stylebox.content_margin_right = max(int(slice[2]) - 2, 6)
		stylebox.content_margin_bottom = max(int(slice[3]) - 2, 6)
		stylebox.draw_center = true

		var output_path: String = "%s/styleboxes/%s.tres" % [GENERATED_DIR, style_name]
		var save_result: int = ResourceSaver.save(stylebox, output_path)
		if save_result != OK:
			push_error("Failed to save stylebox: %s" % output_path)
			quit(1)
			return {}

		results[style_name] = output_path

	return results


func _build_atlas_textures(
	manifest: Dictionary, atlas: Texture2D, output_dir: String, selected_slots: Array = []
) -> Dictionary:
	var results: Dictionary = {}
	var slots: Dictionary = manifest.get("slots", {})
	for slot_name in slots.keys():
		if not selected_slots.is_empty() and not selected_slots.has(slot_name):
			continue

		var slot: Dictionary = slots[slot_name]
		var texture: AtlasTexture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = _rect_from_list(slot["rect"])
		texture.filter_clip = true

		var output_path: String = "%s/%s.tres" % [output_dir, slot_name]
		var save_result: int = ResourceSaver.save(texture, output_path)
		if save_result != OK:
			push_error("Failed to save atlas texture: %s" % output_path)
			quit(1)
			return {}

		results[slot_name] = output_path

	return results


func _rect_from_list(values: Array) -> Rect2:
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


func _load_png_texture(relative_path: String) -> Texture2D:
	var image: Image = Image.new()
	var err: int = image.load(ProjectSettings.globalize_path(_to_res_path(relative_path)))
	if err != OK:
		push_error("Failed to load atlas PNG: %s" % relative_path)
		return null

	return ImageTexture.create_from_image(image)


func _to_res_path(relative_path: String) -> String:
	if relative_path.begins_with("res://"):
		return relative_path
	return "res://%s" % relative_path


func _ensure_directory(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
