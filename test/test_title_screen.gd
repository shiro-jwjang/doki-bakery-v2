extends GutTest

const TITLE_SCENE = preload("res://scenes/menus/title.tscn")


func test_title_screen_has_title_label() -> void:
	var title_scene = TITLE_SCENE.instantiate()
	add_child_autofree(title_scene)

	var title_label = title_scene.find_child("TitleLabel", true, false)
	assert_not_null(title_label, "Title screen should have a TitleLabel node")
	assert_eq(title_label.text, "두근두근 베이커리", "Title label should display the game name")


func test_title_label_is_visible() -> void:
	var title_scene = TITLE_SCENE.instantiate()
	add_child_autofree(title_scene)

	var title_label = title_scene.find_child("TitleLabel", true, false)
	assert_true(title_label.visible, "Title label should be visible")


func test_title_label_has_font_configuration() -> void:
	var title_scene = TITLE_SCENE.instantiate()
	add_child_autofree(title_scene)

	var title_label = title_scene.find_child("TitleLabel", true, false)
	# Label should have a theme type variation configured
	assert_eq(
		title_label.theme_type_variation, &"HeaderLarge", "Title label should use HeaderLarge theme"
	)
