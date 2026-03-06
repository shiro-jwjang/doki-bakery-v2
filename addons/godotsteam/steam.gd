class_name Steam
extends Node

## Minimal Steam stub for development and CI environments.
## This provides the basic Steam interface structure without requiring the
## actual Steam SDK or GDExtension.

signal steam_stats_received(stats: Dictionary)
signal steam_achievement_unlocked(achievement: String)

var _initialized := false
var _app_id: int = 480
var _achievements := {}


func _init() -> void:
	pass


## Initialize Steam. Returns true if successful (or in stub mode).
func init(app_id: int = 480) -> bool:
	_app_id = app_id

	# In CI environments or without Steam, always return true
	var steam_running := _check_steam_running()
	if not steam_running:
		push_warning("Steam is not running - using stub mode")

	_initialized = true
	print("Steam initialized in stub mode (App ID: %d)" % _app_id)
	return true


## Check if Steam is available and running.
func is_steam_running() -> bool:
	return _check_steam_running()


## Check if Steam is initialized.
func is_valid() -> bool:
	return _initialized


## Check if the user is logged into Steam.
func is_logged_on() -> bool:
	if not _initialized:
		return false
	return _check_steam_running()


## Get the current Steam user's Steam ID.
func get_steam_id() -> int:
	if not _initialized:
		return 0
	return 76561198000000000  # Stub Steam ID


## Get the current user's display name.
func get_user_name() -> String:
	if not _initialized:
		return ""
	return "SteamUserStub"


## Set an achievement.
func set_achievement(achievement: String) -> bool:
	if not _initialized:
		return false

	_achievements[achievement] = true
	print("Steam achievement unlocked (stub): %s" % achievement)
	steam_achievement_unlocked.emit(achievement)
	return true


## Get whether an achievement is unlocked.
func get_achievement(achievement: String) -> bool:
	if not _initialized:
		return false
	return _achievements.get(achievement, false)


## Clear an achievement (for testing purposes).
func clear_achievement(achievement: String) -> bool:
	if not _initialized:
		return false

	_achievements.erase(achievement)
	print("Steam achievement cleared (stub): %s" % achievement)
	return true


## Reset all achievements (for testing purposes).
func clear_all_achievements() -> bool:
	if not _initialized:
		return false

	_achievements.clear()
	print("All Steam achievements cleared (stub)")
	return true


## Get all achievements with their unlock status.
func get_all_achievements() -> Dictionary:
	if not _initialized:
		return {}
	return _achievements.duplicate()


## Request stats from Steam.
func request_stats() -> void:
	if not _initialized:
		return

	# In stub mode, immediately return empty stats
	steam_stats_received.emit({})


## Set a stat value.
func set_stat(stat_name: String, value: float) -> bool:
	if not _initialized:
		return false

	print("Steam stat set (stub): %s = %f" % [stat_name, value])
	return true


## Get a stat value.
func get_stat(_stat_name: String) -> float:
	if not _initialized:
		return 0.0

	return 0.0  # Stub value


## Unlock a stat (for incrementing stats).
func set_stat_int(stat_name: String, value: int) -> bool:
	if not _initialized:
		return false

	print("Steam stat int set (stub): %s = %d" % [stat_name, value])
	return true


## Get an integer stat value.
func get_stat_int(_stat_name: String) -> int:
	if not _initialized:
		return 0

	return 0  # Stub value


## Get the current App ID.
func get_app_id() -> int:
	return _app_id


## Run callbacks (should be called in _process).
func run_callbacks() -> void:
	# In stub mode, no callbacks to process
	pass


func _check_steam_running() -> bool:
	# Check if steam_appid.txt exists
	if not FileAccess.file_exists("user://steam_appid.txt"):
		if not FileAccess.file_exists("res://steam_appid.txt"):
			return false

	# Check for steam_api library (Linux)
	if OS.has_feature("linux"):
		return false  # Stub mode

	return false  # Always return false for stub mode
