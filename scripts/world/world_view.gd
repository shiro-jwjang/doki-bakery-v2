extends Node2D

## WorldView Root Scene
## Main scene for the bakery world view.
## Contains:
## - Camera2D for viewport (1200x1000)
## - CanvasLayers for Background, Entities, UI
## - YSort for entity depth ordering
## SNA-88: WorldView 루트 씬 구성 + Y-Sort 레이어
## SNA-114: YSort 헬퍼 메서드 및 뷰포트 명시

# Viewport configuration (matches project.godot settings)
const VIEWPORT_WIDTH: int = 1200
const VIEWPORT_HEIGHT: int = 1000

# Node references (cached for performance)
@onready var _y_sort: Node2D = $Entities/YSort


func _ready() -> void:
	# Verify YSort node exists and has Y-sort enabled
	assert(_y_sort != null, "YSort node not found at $Entities/YSort")
	assert(_y_sort.y_sort_enabled, "YSort node should have y_sort_enabled = true")


## Adds an entity to the YSort layer for proper depth ordering.
## Entities added this way will be sorted by their Y position,
## with higher Y values rendered in front of lower Y values.
## SNA-114
func add_entity(entity: Node2D) -> void:
	assert(_y_sort != null, "YSort node not found at $Entities/YSort")
	assert(entity != null, "Cannot add null entity to YSort")
	_y_sort.add_child(entity)
