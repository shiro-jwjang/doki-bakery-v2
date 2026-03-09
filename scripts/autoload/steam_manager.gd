extends Node

## Steam Manager Autoload
##
## Manages Steam initialization and provides a global interface for Steam features.
## This singleton initializes Steam on startup and handles Steam callbacks.

var is_initialized := false
var is_running := false
var _steam: Node = null


func _init() -> void:
	# Create Steam instance (stub implementation)
	_steam = load("res://addons/godotsteam/steam.gd").new()


func _ready() -> void:
	# Add steam instance to scene tree to prevent orphan warnings
	if _steam != null and not _steam.is_inside_tree():
		add_child(_steam)
		
	# Read steam_appid.txt if it exists
	var app_id := 480  # Default to Spacewar test app ID

	var appid_file := FileAccess.open("res://steam_appid.txt", FileAccess.READ)
	if appid_file:
		var content := appid_file.get_as_text().strip_edges()
		if content.is_valid_int():
			app_id = content.to_int()
		appid_file.close()

	# Initialize Steam
	if _steam:
		is_initialized = _steam.init(app_id)
		is_running = _steam.is_steam_running()

		if is_initialized:
			print("Steam initialized successfully (App ID: %d)" % app_id)
			if not is_running:
				print("Steam client not running - stub mode active")
		else:
			push_error("Failed to initialize Steam")


func _process(_delta: float) -> void:
	# Run Steam callbacks each frame
	if _steam and _steam.has_method("run_callbacks"):
		_steam.run_callbacks()


## Get the Steam instance
func get_steam() -> Node:
	return _steam


## Check if Steam is available and initialized
func is_steam_available() -> bool:
	return is_initialized and is_running


## Get the current user's Steam ID
func get_steam_id() -> int:
	if _steam and _steam.has_method("get_steam_id"):
		return _steam.get_steam_id()
	return 0


## Get the current user's display name
func get_username() -> String:
	if _steam and _steam.has_method("get_user_name"):
		return _steam.get_user_name()
	return ""


## Set an achievement
func unlock_achievement(achievement: String) -> bool:
	if _steam and _steam.has_method("set_achievement"):
		return _steam.set_achievement(achievement)
	return false


## Get whether an achievement is unlocked
func has_achievement(achievement: String) -> bool:
	if _steam and _steam.has_method("get_achievement"):
		return _steam.get_achievement(achievement)
	return false


## Clear an achievement (for testing)
func clear_achievement(achievement: String) -> bool:
	if _steam and _steam.has_method("clear_achievement"):
		return _steam.clear_achievement(achievement)
	return false


## Set a stat value
func set_stat(stat_name: String, value: float) -> bool:
	if _steam and _steam.has_method("set_stat"):
		return _steam.set_stat(stat_name, value)
	return false


## Get a stat value
func get_stat(stat_name: String) -> float:
	if _steam and _steam.has_method("get_stat"):
		return _steam.get_stat(stat_name)
	return 0.0


## Set an integer stat value
func set_stat_int(stat_name: String, value: int) -> bool:
	if _steam and _steam.has_method("set_stat_int"):
		return _steam.set_stat_int(stat_name, value)
	return false


## Get an integer stat value
func get_stat_int(stat_name: String) -> int:
	if _steam and _steam.has_method("get_stat_int"):
		return _steam.get_stat_int(stat_name)
	return 0


## Request stats from Steam
func request_stats() -> void:
	if _steam and _steam.has_method("request_stats"):
		_steam.request_stats()


## Get the App ID
func get_app_id() -> int:
	if _steam and _steam.has_method("get_app_id"):
		return _steam.get_app_id()
	return 0


## Check if user is logged into Steam
func is_logged_on() -> bool:
	if _steam and _steam.has_method("is_logged_on"):
		return _steam.is_logged_on()
	return false
