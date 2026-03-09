extends GutTest

## Test Suite for GameManager Save System (SNA-70)
## Tests JSON serialization and save functionality

var _test_save_path: String = "user://test_save.json"


func before_each() -> void:
	# Reset GameManager state
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0
	GameManager.set_game_state("menu")

	# Clean up any existing test save file
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)


func after_each() -> void:
	# Clean up test save file
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)


## Test that save_game creates a file
func test_save_game_creates_file() -> void:
	var result: bool = GameManager.save_game(_test_save_path)

	assert_true(result, "save_game should return true on success")
	assert_true(FileAccess.file_exists(_test_save_path), "Save file should exist")


## Test that save_game saves default values
func test_save_game_default_values() -> void:
	GameManager.save_game(_test_save_path)

	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data

	assert_eq(int(data.get("gold", 0)), 0, "Default gold should be 0")
	assert_eq(int(data.get("premium", 0)), 0, "Default premium should be 0")
	assert_eq(int(data.get("level", 0)), 1, "Default level should be 1")
	assert_eq(int(data.get("xp", 0)), 0, "Default xp should be 0")


## Test that save_game saves actual game state
func test_save_game_actual_state() -> void:
	# Set up game state
	GameManager.gold = 500
	GameManager.add_premium(10)
	GameManager.add_xp(150)  # Should level up to 2 with 50 XP

	GameManager.save_game(_test_save_path)

	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data

	assert_eq(int(data.get("gold", 0)), 500, "Saved gold should match")
	assert_eq(int(data.get("premium", 0)), 10, "Saved premium should match")
	assert_eq(int(data.get("level", 0)), 2, "Saved level should be 2")
	assert_eq(int(data.get("xp", 0)), 50, "Saved xp should be 50")


## Test that save_game includes unlocked_recipes array
func test_save_game_unlocked_recipes() -> void:
	GameManager.save_game(_test_save_path)

	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data

	assert_true(data.has("unlocked_recipes"), "Save data should have unlocked_recipes")
	assert_true(data.unlocked_recipes is Array, "unlocked_recipes should be an array")


## Test that save_game includes shop_stage
func test_save_game_shop_stage() -> void:
	GameManager.save_game(_test_save_path)

	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data

	assert_true(data.has("shop_stage"), "Save data should have shop_stage")


## Test that save_game includes production_slots array
func test_save_game_production_slots() -> void:
	GameManager.save_game(_test_save_path)

	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data

	assert_true(data.has("production_slots"), "Save data should have production_slots")
	assert_true(data.production_slots is Array, "production_slots should be an array")


## Test save_game returns false on file write error
func test_save_game_write_error() -> void:
	# Use an invalid path that should fail
	var invalid_path := "invalid://save.json"
	var result: bool = GameManager.save_game(invalid_path)

	assert_false(result, "save_game should return false on write error")


## Test that saved JSON is valid
func test_save_game_valid_json() -> void:
	GameManager.save_game(_test_save_path)

	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)

	assert_eq(parse_result, OK, "Saved data should be valid JSON")
	assert_not_null(json.data, "Parsed data should not be null")
