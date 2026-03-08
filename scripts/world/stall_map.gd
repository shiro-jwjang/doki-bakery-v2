extends TileMapLayer
## StallMap TileMapLayer
## SNA-89: TileMapLayer 노점상 맵 배치
##
## This script sets up the stall map with floor, stall, and parasol tiles.

# Tile source IDs (matching stall_tileset.tres)
const SOURCE_FLOOR = 0
const SOURCE_STALL = 1
const SOURCE_PARASOL = 2

# Atlas coordinates (all tiles are at 0,0 in their respective sources)
const ATLAS_COORDS = Vector2i(0, 0)
const ALT_TILE = 0


func _ready() -> void:
	_setup_map()


## Setup the stall map layout
func _setup_map() -> void:
	# Create a 6x6 floor base
	for x in range(6):
		for y in range(6):
			set_cell(Vector2i(x, y), SOURCE_FLOOR, ATLAS_COORDS, ALT_TILE)

	# Add stalls at specific locations
	set_cell(Vector2i(2, 2), SOURCE_STALL, ATLAS_COORDS, ALT_TILE)
	set_cell(Vector2i(3, 2), SOURCE_STALL, ATLAS_COORDS, ALT_TILE)
	set_cell(Vector2i(2, 3), SOURCE_STALL, ATLAS_COORDS, ALT_TILE)

	# Add parasols at specific locations
	set_cell(Vector2i(1, 1), SOURCE_PARASOL, ATLAS_COORDS, ALT_TILE)
	set_cell(Vector2i(4, 4), SOURCE_PARASOL, ATLAS_COORDS, ALT_TILE)
