extends Node

## DataManager Autoload
## 정적 데이터(.tres) 로딩/캐싱/조회
## SNA-178: Lazy loading 도입 - 필요 시점에 on-demand 로딩

# 리소스 타입 preload
const RecipeData = preload("res://resources/data/recipe_data.gd")
const LevelData = preload("res://resources/config/level_data.gd")
const ShopData = preload("res://resources/config/shop_data.gd")

# 리소스 경로
const RECIPES_PATH := "res://resources/data/recipes/"
const LEVELS_PATH := "res://resources/config/levels/"
const SHOPS_PATH := "res://resources/config/shops/"

# SNA-194: 웹 빌드 호환성을 위해 리소스 파일들을 명시적으로 나열
# 웹 빌드에서 DirAccess.list_dir_begin()이 제대로 작동하지 않는 문제 해결
const RECIPE_FILES := [
	"bread_002.tres",
	"bread_003.tres",
	"bread_004.tres",
	"bread_005.tres",
	"bread_006.tres",
	"bread_croissant.tres"
]

const LEVEL_FILES := [
	"level_01.tres",
	"level_02.tres",
	"level_03.tres",
	"level_04.tres",
	"level_05.tres",
	"level_06.tres",
	"level_07.tres",
	"level_08.tres",
	"level_09.tres",
	"level_10.tres"
]

const SHOP_FILES := [
	"shop_level_1.tres",
	"shop_level_2.tres",
	"shop_level_3.tres",
	"shop_level_4.tres",
	"shop_level_5.tres"
]

var _recipes: Dictionary = {}  # id -> RecipeData
var _levels: Dictionary = {}  # level -> LevelData
var _shop_stages: Dictionary = {}  # stage -> ShopData

# SNA-178: Lazy loading state flags
var _recipes_loaded := false
var _levels_loaded := false
var _shops_loaded := false


## SNA-178: _ready에서 더 이상 모든 데이터를 로드하지 않음
func _ready() -> void:
	pass  # Lazy loading: 필요 시점에 로드


## SNA-178: 레시피 lazy loading
func _ensure_recipes_loaded() -> void:
	if not _recipes_loaded:
		_load_recipes()
		_recipes_loaded = true


## SNA-178: 레벨 lazy loading
func _ensure_levels_loaded() -> void:
	if not _levels_loaded:
		_load_levels()
		_levels_loaded = true


## SNA-178: 매장 lazy loading
func _ensure_shops_loaded() -> void:
	if not _shops_loaded:
		_load_shops()
		_shops_loaded = true


func _load_recipes() -> void:
	_load_resources_from_list(RECIPES_PATH, RECIPE_FILES, "id", _recipes, "display_name")
	print("DataManager: Loaded %d recipes" % _recipes.size())


func _load_levels() -> void:
	_load_resources_from_list(LEVELS_PATH, LEVEL_FILES, "level", _levels)
	print("DataManager: Loaded %d levels" % _levels.size())


func _load_shops() -> void:
	_load_resources_from_list(SHOPS_PATH, SHOP_FILES, "shop_level", _shop_stages)
	print("DataManager: Loaded %d shop stages" % _shop_stages.size())


## SNA-194: 리소스 로더 - 명시적 파일 목록 사용 (웹 빌드 호환)
## Loads .tres files from an explicit list of filenames
## path: Directory path to load from
## file_list: Array of filenames to load
## id_prop: Property name to use as dictionary key (e.g., "id", "level", "shop_level")
## target_dict: Dictionary to store loaded resources in
## required_prop: Optional additional property to validate (e.g., "display_name" for recipes)
func _load_resources_from_list(
	path: String,
	file_list: Array,
	id_prop: String,
	target_dict: Dictionary,
	required_prop: String = ""
) -> void:
	for file_name in file_list:
		var full_path = path + file_name
		var resource = load(full_path)

		# Validate resource
		if resource and resource.get(id_prop) != null:
			# Check for additional required property if specified
			if required_prop == "" or resource.get(required_prop) != null:
				target_dict[resource.get(id_prop)] = resource
			else:
				push_warning(
					(
						"DataManager: File %s missing required property '%s'"
						% [file_name, required_prop]
					)
				)
		else:
			push_warning(
				"DataManager: File %s is not a valid resource (missing '%s')" % [file_name, id_prop]
			)


## Generic resource loader - SNA-172
## Loads all .tres files from a directory and stores them in a dictionary
## path: Directory path to load from
## id_prop: Property name to use as dictionary key (e.g., "id", "level", "shop_level")
## target_dict: Dictionary to store loaded resources in
## required_prop: Optional additional property to validate (e.g., "display_name" for recipes)
func _load_resources(
	path: String, id_prop: String, target_dict: Dictionary, required_prop: String = ""
) -> void:
	# Check if directory exists
	if not DirAccess.dir_exists_absolute(path):
		push_warning("DataManager: Directory not found: " + path)
		return

	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("DataManager: Failed to open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# Skip directories and non-.tres files
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = path + file_name
			var resource = load(full_path)

			# Validate resource
			if resource and resource.get(id_prop) != null:
				# Check for additional required property if specified
				if required_prop == "" or resource.get(required_prop) != null:
					target_dict[resource.get(id_prop)] = resource
				else:
					push_warning(
						(
							"DataManager: File %s missing required property '%s'"
							% [file_name, required_prop]
						)
					)
			else:
				push_warning(
					(
						"DataManager: File %s is not a valid resource (missing '%s')"
						% [file_name, id_prop]
					)
				)
		file_name = dir.get_next()
	dir.list_dir_end()


## SNA-178: 레시피 조회 - lazy loading 적용
func get_recipe(id: String) -> RecipeData:
	_ensure_recipes_loaded()
	return _recipes.get(id)


## SNA-178: 레벨 데이터 조회 - lazy loading 적용
func get_level(level: int) -> LevelData:
	_ensure_levels_loaded()
	return _levels.get(level)


## SNA-178: 매장 단계 조회 - lazy loading 적용
func get_shop_stage(stage: int) -> ShopData:
	_ensure_shops_loaded()
	return _shop_stages.get(stage)


## SNA-178: 모든 레시피 반환 - lazy loading 적용
func get_all_recipes() -> Array:
	_ensure_recipes_loaded()
	return _recipes.values()


## SNA-178: 모든 레벨 반환 - lazy loading 적용
func get_all_levels() -> Array:
	_ensure_levels_loaded()
	return _levels.values()


## SNA-178: 모든 매장 단계 반환 - lazy loading 적용
func get_all_shop_stages() -> Array:
	_ensure_shops_loaded()
	return _shop_stages.values()


## SNA-178: 레시피 캐시 비우기
func clear_recipe_cache() -> void:
	_recipes.clear()
	_recipes_loaded = false


## SNA-178: 레벨 캐시 비우기
func clear_level_cache() -> void:
	_levels.clear()
	_levels_loaded = false


## SNA-178: 매장 캐시 비우기
func clear_shop_cache() -> void:
	_shop_stages.clear()
	_shops_loaded = false


## 레벨에서 해금되는 아이템 목록 조회
func get_unlocks_for_level(level: int) -> Array:
	var level_data = get_level(level)
	if level_data:
		return level_data.unlock_recipes
	return []


## SNA-166: 레벨별 필요 경험치 반환
func get_xp_required_for_level(level: int) -> int:
	var level_data = get_level(level)
	if level_data:
		return level_data.required_xp
	return 0
