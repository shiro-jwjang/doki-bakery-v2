extends Node

## GameConstants Singleton
## Centralized magic numbers for the entire game
## SNA-180: Magic Numbers 중앙화

## ==================== GAME PLAY CONSTANTS ====================

## Maximum level a player can achieve
const MAX_LEVEL: int = 10

## Number of display slots available
const SLOT_COUNT: int = 4

## ==================== SYSTEM CONSTANTS ====================

## Current save data format version
## Increment this when save format changes to prevent loading incompatible data
const SAVE_VERSION: int = 1

## ==================== UI CONSTANTS ====================

## Default viewport width for the game window
const VIEWPORT_WIDTH: int = 1200

## Default viewport height for the game window
const VIEWPORT_HEIGHT: int = 1000

## Maximum number of notifications visible at once
const MAX_NOTIFICATIONS: int = 3

## ==================== INITIALIZATION ====================


func _init() -> void:
	## Prevent GameConstants from being instantiated
	## It should only be used as an autoload singleton
	pass


## ==================== GETTER METHODS ====================
## These provide a consistent interface for accessing constants
## and allow for potential future dynamic values


## Get the maximum level
static func get_max_level() -> int:
	return MAX_LEVEL


## Get the slot count
static func get_slot_count() -> int:
	return SLOT_COUNT


## Get the save version
static func get_save_version() -> int:
	return SAVE_VERSION


## Get the viewport width
static func get_viewport_width() -> int:
	return VIEWPORT_WIDTH


## Get the viewport height
static func get_viewport_height() -> int:
	return VIEWPORT_HEIGHT


## Get the max notifications
static func get_max_notifications() -> int:
	return MAX_NOTIFICATIONS
