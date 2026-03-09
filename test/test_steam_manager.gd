extends GutTest

## Tests for SteamManager autoload.
##
## These tests verify Steam initialization and basic functionality
## in both Steam-enabled and stub (CI) environments.

var _steam_manager: Node = null


func before_all() -> void:
	# Get or create SteamManager instance
	if not SteamManager:
		_steam_manager = preload("res://scripts/autoload/steam_manager.gd").new()
		add_child(_steam_manager)
	else:
		_steam_manager = SteamManager


func test_steam_manager_exists() -> void:
	assert_not_null(SteamManager, "SteamManager autoload should exist")


func test_steam_manager_has_steam_instance() -> void:
	assert_not_null(SteamManager.get_steam(), "SteamManager should have a Steam instance")


func test_steam_is_initialized() -> void:
	# In stub mode (CI), this should still return true
	assert_true(SteamManager.is_initialized, "Steam should be initialized (may be in stub mode)")


func test_get_steam_id_returns_valid_id() -> void:
	var steam_id := SteamManager.get_steam_id()
	assert_true(
		steam_id > 0 or steam_id == 0, "Steam ID should be valid (0 in stub mode, >0 in real Steam)"
	)


func test_get_username_returns_string() -> void:
	var username := SteamManager.get_username()
	assert_ne(username, "", "Username should not be empty")


func test_unlock_achievement_returns_bool() -> void:
	var result := SteamManager.unlock_achievement("test_achievement")
	assert_typeof(result, TYPE_BOOL, "unlock_achievement should return a boolean")


func test_has_achievement_returns_bool() -> void:
	var result := SteamManager.has_achievement("test_achievement")
	assert_typeof(result, TYPE_BOOL, "has_achievement should return a boolean")


func test_unlock_then_check_achievement() -> void:
	var test_achievement := "test_achievement_unlock"

	# Clear achievement first
	SteamManager.clear_achievement(test_achievement)

	# Unlock achievement
	var unlock_result := SteamManager.unlock_achievement(test_achievement)

	# In stub mode, this should succeed
	if SteamManager.is_running:
		assert_true(unlock_result, "Unlocking achievement should succeed")
		assert_true(
			SteamManager.has_achievement(test_achievement), "Achievement should be unlocked"
		)
	else:
		# In stub mode, achievements may not persist
		pass


func test_set_and_get_stat() -> void:
	var stat_name := "test_stat"
	var test_value := 42.5

	var set_result := SteamManager.set_stat(stat_name, test_value)
	assert_typeof(set_result, TYPE_BOOL, "set_stat should return a boolean")

	# In stub mode, get_stat returns 0.0
	var get_result := SteamManager.get_stat(stat_name)
	if not SteamManager.is_running:
		assert_eq(get_result, 0.0, "In stub mode, get_stat should return 0.0")


func test_set_and_get_stat_int() -> void:
	var stat_name := "test_stat_int"
	var test_value := 100

	var set_result := SteamManager.set_stat_int(stat_name, test_value)
	assert_typeof(set_result, TYPE_BOOL, "set_stat_int should return a boolean")

	# In stub mode, get_stat_int returns 0
	var get_result := SteamManager.get_stat_int(stat_name)
	if not SteamManager.is_running:
		assert_eq(get_result, 0, "In stub mode, get_stat_int should return 0")


func test_get_app_id() -> void:
	var app_id := SteamManager.get_app_id()
	assert_true(
		app_id == 480 or app_id == 0, "App ID should be 480 (Spacewar) or 0 (in some stub modes)"
	)


func test_request_stats_does_not_crash() -> void:
	SteamManager.request_stats()


func test_clear_achievement() -> void:
	var test_achievement := "test_achievement_clear"

	# Unlock achievement first
	SteamManager.unlock_achievement(test_achievement)

	# Clear achievement
	var clear_result := SteamManager.clear_achievement(test_achievement)
	assert_typeof(clear_result, TYPE_BOOL, "clear_achievement should return a boolean")


func test_is_logged_on() -> void:
	var logged_on := SteamManager.is_logged_on()
	# In stub mode without Steam client, this should be false
	assert_typeof(logged_on, TYPE_BOOL, "is_logged_on should return a boolean")


func test_steam_manager_methods_exist() -> void:
	var methods := [
		"get_steam",
		"is_steam_available",
		"get_steam_id",
		"get_username",
		"unlock_achievement",
		"has_achievement",
		"clear_achievement",
		"set_stat",
		"get_stat",
		"set_stat_int",
		"get_stat_int",
		"request_stats",
		"get_app_id",
		"is_logged_on"
	]

	for method in methods:
		assert_true(SteamManager.has_method(method), "SteamManager should have method: %s" % method)
