extends Node

## DataManager Autoload
## 정적 데이터(.tres) 로딩/캐싱/조회

# 리소스 타입 preload
const RecipeData = preload("res://resources/data/recipe_data.gd")
const LevelData = preload("res://resources/config/level_data.gd")
const ShopData = preload("res://resources/config/shop_data.gd")

# 리소스 경로
const RECIPES_PATH := "res://resources/data/recipes/"
const LEVELS_PATH := "res://resources/config/levels/"
const SHOPS_PATH := "res://resources/config/shops/"

var _recipes: Dictionary = {}  # id -> RecipeData
var _levels: Dictionary = {}  # level -> LevelData
var _shop_stages: Dictionary = {}  # stage -> ShopData


func _ready() -> void:
	_load_all_data()


func _load_all_data() -> void:
	_load_recipes()
	_load_levels()
	_load_shops()


func _load_recipes() -> void:
	## SNA-155: Use predefined list for web, DirAccess for desktop
	var web_files := ["bread_croissant.tres"] if OS.has_feature("web") else []
	_load_resources(RECIPES_PATH, "id", _recipes, "display_name", web_files)
	print("DataManager: Loaded %d recipes" % _recipes.size())


func _load_levels() -> void:
	## SNA-155: Use predefined list for web, DirAccess for desktop
	var web_files := []
	if OS.has_feature("web"):
		for i in range(1, 11):
			web_files.append("level_%02d.tres" % i)
	_load_resources(LEVELS_PATH, "level", _levels, "", web_files)
	print("DataManager: Loaded %d levels" % _levels.size())


func _load_shops() -> void:
	## SNA-155: Use predefined list for web, DirAccess for desktop
	var web_files := []
	if OS.has_feature("web"):
		for i in range(1, 6):
			web_files.append("shop_level_%d.tres" % i)
	_load_resources(SHOPS_PATH, "shop_level", _shop_stages, "", web_files)
	print("DataManager: Loaded %d shop stages" % _shop_stages.size())


## Generic resource loader - SNA-172 + SNA-155 web support
## Loads all .tres files from a directory and stores them in a dictionary
## path: Directory path to load from
## id_prop: Property name to use as dictionary key (e.g., "id", "level", "shop_level")
## target_dict: Dictionary to store loaded resources in
## required_prop: Optional additional property to validate (e.g., "display_name" for recipes)
## web_files: Optional list of files for web platform (DirAccess doesn't work reliably on web)
func _load_resources(
	path: String, id_prop: String, target_dict: Dictionary, required_prop: String = "", web_files: Array = []
) -> void:
	var files_to_load: Array = []

	# SNA-155: Use predefined list for web, DirAccess for desktop
	if OS.has_feature("web") and not web_files.is_empty():
		files_to_load = web_files
	else:
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
				files_to_load.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	# Load the files
	for file_name in files_to_load:
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
				"DataManager: File %s is not a valid resource (missing '%s')"
				% [file_name, id_prop]
			)


## 레시피 조회
func get_recipe(id: String) -> RecipeData:
	return _recipes.get(id)


## 레벨 데이터 조회
func get_level(level: int) -> LevelData:
	return _levels.get(level)


## 매장 단계 조회
func get_shop_stage(stage: int) -> ShopData:
	return _shop_stages.get(stage)


## 모든 레시피 반환
func get_all_recipes() -> Array:
	return _recipes.values()


## 모든 레벨 반환
func get_all_levels() -> Array:
	return _levels.values()


## 모든 매장 단계 반환
func get_all_shop_stages() -> Array:
	return _shop_stages.values()


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
