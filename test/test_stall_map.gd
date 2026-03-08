extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for StallMap TileMapLayer
## Tests the structure of the stall map including:
## - TileMapLayer node exists
## - Tiles are placed in the map
## - Tiles are within world bounds
## - TileSet sources are loaded correctly
## SNA-89: TileMapLayer 노점상 맵 배치

const STALL_MAP_SCENE_PATH = "res://scenes/world/stall_map.tscn"
const TILESET_PATH = "res://resources/tilesets/stall_tileset.tres"

var _stall_map: TileMapLayer


func before_each() -> void:
	# Load the stall map scene
	var scene_resource = load(STALL_MAP_SCENE_PATH)
	if scene_resource != null:
		_stall_map = scene_resource.instantiate()
		add_child_autofree(_stall_map)


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	pass


## ==================== BASIC SETUP TESTS ====================

## Test that StallMap scene can be loaded
func test_stall_map_scene_loads() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist at: %s" % STALL_MAP_SCENE_PATH)
	assert_not_null(_stall_map, "StallMap scene should be instantiated")


## Test that StallMap root is TileMapLayer
func test_stall_map_root_is_tilemaplayer() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")
	assert_true(
		_stall_map is TileMapLayer,
		"StallMap root should be TileMapLayer, got: %s" % _stall_map.get_class()
	)


## ==================== TILESET TESTS ====================

## Test that TileSet resource exists and can be loaded
func test_tileset_source_loaded() -> void:
	var tileset_resource = load(TILESET_PATH)
	assert_not_null(
		tileset_resource,
		"TileSet resource should exist at: %s" % TILESET_PATH
	)

	if tileset_resource != null:
		assert_true(
			tileset_resource is TileSet,
			"Resource should be a TileSet, got: %s" % tileset_resource.get_class()
		)


## Test that TileMapLayer has a TileSet assigned
func test_tilemaplayer_has_tileset() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")

	var tileset = _stall_map.tile_set
	assert_not_null(tileset, "TileMapLayer should have a TileSet assigned")

	if tileset != null:
		assert_true(
			tileset is TileSet,
			"TileMapLayer tile_set should be a TileSet, got: %s" % tileset.get_class()
		)


## ==================== TILE PLACEMENT TESTS ====================

## Test that tiles are actually placed in the map
func test_tilemap_has_cells() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")

	# Get all used cells
	var used_cells = _stall_map.get_used_cells()
	assert_true(
		used_cells.size() > 0,
		"TileMapLayer should have at least one tile placed, got: %d tiles" % used_cells.size()
	)


## Test that all used cells are within reasonable world bounds
func test_tilemap_within_world_bounds() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")

	var used_cells = _stall_map.get_used_cells()
	var min_x = 0
	var min_y = 0
	var max_x = 1200  # Reasonable world bounds based on viewport
	var max_y = 1000

	# Convert to tile coordinates (assuming 30x16 tiles)
	var tile_size_x = 30
	var tile_size_y = 16
	var max_tile_x = max_x / tile_size_x
	var max_tile_y = max_y / tile_size_y

	for cell in used_cells:
		var cell_coords = cell as Vector2i
		assert_true(
			cell_coords.x >= min_x and cell_coords.x <= max_tile_x,
			"Tile X coordinate %d should be within bounds [%d, %d]" % [cell_coords.x, min_x, max_tile_x]
		)
		assert_true(
			cell_coords.y >= min_y and cell_coords.y <= max_tile_y,
			"Tile Y coordinate %d should be within bounds [%d, %d]" % [cell_coords.y, min_y, max_tile_y]
		)


## ==================== TILE SOURCE TESTS ====================

## Test that TileSet has valid tile sources configured
func test_tileset_has_valid_sources() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")

	var tileset = _stall_map.tile_set
	if tileset == null:
		fail_test("TileMapLayer has no TileSet assigned")

	# Check that TileSet has at least one source
	var source_count = tileset.get_source_count()
	assert_true(
		source_count > 0,
		"TileSet should have at least one source, got: %d" % source_count
	)


## ==================== INTEGRATION TESTS ====================

## Test complete scene structure
func test_stall_map_complete_structure() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")

	# Verify TileSet is assigned
	var tileset = _stall_map.tile_set
	assert_not_null(tileset, "TileMapLayer should have a TileSet assigned")

	# Verify tiles are placed
	var used_cells = _stall_map.get_used_cells()
	assert_true(used_cells.size() > 0, "TileMapLayer should have tiles placed")


## Test scene can be added to tree without errors
func test_stall_map_add_to_scene_tree() -> void:
	if _stall_map == null:
		fail_test("StallMap scene file does not exist")

	# The scene was already added to the tree in before_each
	# Verify it's in the tree
	assert_true(_stall_map.is_inside_tree(), "StallMap should be inside scene tree")
