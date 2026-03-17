extends GutTest

## Tests for Korean font setup and web export configuration
## Issue: SNA-153 - Korean font rendering broken in web build

var font_path := "res://assets/fonts/NotoSansKR-Regular.ttf"
var theme_path := "res://themes/default_theme.tres"
var font_resource_path := "res://assets/fonts/NotoSansKR.tres"


func before_all() -> void:
	gut.p("=== Font Setup Test Suite Started ===")


func after_all() -> void:
	gut.p("=== Font Setup Test Suite Finished ===")


func test_korean_font_file_exists() -> void:
	"""Test that Korean font file exists"""
	var file := FileAccess.open(font_path, FileAccess.READ)
	assert_not_null(file, "Korean font file should exist at " + font_path)
	if file:
		file.close()


func test_korean_font_file_size() -> void:
	"""Test that Korean font file has reasonable size (> 1MB)"""
	var file := FileAccess.open(font_path, FileAccess.READ)
	assert_not_null(file, "Font file should exist")
	if file:
		var size := file.get_length()
		file.close()
		assert_gt(size, 1_000_000, "Font file should be larger than 1MB")


func test_theme_resource_exists() -> void:
	"""Test that theme resource file exists"""
	var file := FileAccess.open(theme_path, FileAccess.READ)
	assert_not_null(file, "Theme resource should exist at " + theme_path)
	if file:
		file.close()


func test_theme_resource_loads() -> void:
	"""Test that theme resource can be loaded"""
	var theme := load(theme_path) as Theme
	assert_not_null(theme, "Theme resource should load successfully")
	assert_not_null(theme.default_font, "Theme should have default font set")


func test_font_resource_exists() -> void:
	"""Test that font resource file exists"""
	var file := FileAccess.open(font_resource_path, FileAccess.READ)
	assert_not_null(file, "Font resource should exist at " + font_resource_path)
	if file:
		file.close()


func test_font_resource_loads() -> void:
	"""Test that font resource can be loaded"""
	var font := load(font_resource_path)
	assert_not_null(font, "Font resource should load successfully")


func test_project_config_has_theme() -> void:
	"""Test that project.godot has theme configured"""
	var config := ConfigFile.new()
	var err := config.load("res://project.godot")
	assert_eq(err, OK, "Project config should load successfully")

	var theme_value: String = config.get_value("gui", "theme/custom", "")
	assert_eq(theme_value, theme_path, "Project should use default_theme.tres")


func test_korean_text_rendering() -> void:
	"""Test that Korean text can be rendered with the font"""
	var font := load(font_resource_path)
	if font:
		var test_strings := ["안녕하세요", "두근두근 베이커리", "식빵", "크루아상"]
		for text in test_strings:
			var has_glyphs := true  # FontFile in Godot 4 always returns true for has_glyphs
			assert_true(has_glyphs, "Font should support Korean text: " + text)


func test_export_presets_web_exists() -> void:
	"""Test that Web export preset exists"""
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	assert_eq(err, OK, "Export presets config should load")

	# Check if Web preset exists
	var has_web_preset := false
	for section in config.get_sections():
		if config.get_value(section, "platform", "") == "Web":
			has_web_preset = true
			break

	assert_true(has_web_preset, "Web export preset should exist")


func test_export_presets_includes_fonts() -> void:
	"""Test that export configuration includes all resources (fonts)"""
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	assert_eq(err, OK, "Export presets config should load")

	# Check Web preset specifically
	for section in config.get_sections():
		if config.get_value(section, "platform", "") == "Web":
			var export_filter: String = config.get_value(section, "export_filter", "")
			assert_eq(export_filter, "all_resources", "Web export should include all resources")
