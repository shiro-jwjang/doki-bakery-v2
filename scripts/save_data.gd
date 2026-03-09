## SaveData class for game save/load functionality
extends RefCounted

## Save data format version for compatibility
const VERSION: String = "1.1"

## Player's gold (standard currency)
var gold: int = 0

## Premium currency (legendary golden bread)
var legendary_bread: int = 0

## Current player level (1-10)
var level: int = 1

## Current experience points
var experience: int = 0

## Total play time in seconds
var play_time: float = 0.0

## Current game state
var game_state: String = "menu"

## Unlocked recipe IDs
var unlocked_recipes: Array = []

## Current shop stage (1-5)
var shop_stage: int = 1

## Production slots data
var production_slots: Array = []

## Save data version
var version: String = VERSION


## Convert to JSON string
func to_json() -> String:
	return JSON.stringify(
		{
			"version": version,
			"gold": gold,
			"legendary_bread": legendary_bread,
			"level": level,
			"experience": experience,
			"play_time": play_time,
			"game_state": game_state,
			"unlocked_recipes": unlocked_recipes,
			"shop_stage": shop_stage,
			"production_slots": production_slots
		}
	)


## Create SaveData from JSON string
## Returns null if JSON is invalid
static func from_json(json_string: String):
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return null

	var data: Dictionary = json.data
	# Create instance using script resource
	var ScriptResource = load("res://scripts/save_data.gd")
	var save_data: RefCounted = ScriptResource.new()

	# Check version compatibility
	if data.has("version"):
		save_data.version = data["version"]

	# Load fields with defaults for missing keys
	if data.has("gold"):
		save_data.gold = data["gold"]
	if data.has("legendary_bread"):
		save_data.legendary_bread = data["legendary_bread"]
	if data.has("level"):
		save_data.level = clamp(data["level"], 1, 10)  # Ensure valid level range
	if data.has("experience"):
		save_data.experience = data["experience"]
	if data.has("play_time"):
		save_data.play_time = data["play_time"]
	if data.has("game_state"):
		save_data.game_state = data["game_state"]
	if data.has("unlocked_recipes"):
		save_data.unlocked_recipes = data["unlocked_recipes"]
	if data.has("shop_stage"):
		save_data.shop_stage = data["shop_stage"]
	if data.has("production_slots"):
		save_data.production_slots = data["production_slots"]

	return save_data
