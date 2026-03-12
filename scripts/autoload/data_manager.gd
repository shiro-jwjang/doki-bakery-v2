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
	if not DirAccess.dir_exists_absolute(RECIPES_PATH):
		push_error("DataManager: Recipes directory NOT FOUND at " + RECIPES_PATH)
		return

	var dir := DirAccess.open(RECIPES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = RECIPES_PATH + file_name
				var resource = load(full_path)
				# Use property check instead of 'is' for better reliability with resources
				if resource and resource.get("id") != null and resource.get("display_name") != null:
					_recipes[resource.id] = resource
				else:
					push_warning("DataManager: File %s is not a valid RecipeData" % file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("DataManager: Loaded %d recipes" % _recipes.size())
	else:
		push_error("DataManager: Failed to open recipes directory: " + RECIPES_PATH)


func _load_levels() -> void:
	var dir := DirAccess.open(LEVELS_PATH)
	if dir == null:
		push_warning("Levels directory not found: " + LEVELS_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(LEVELS_PATH + file_name)
			if resource and resource.get("level") != null:
				_levels[resource.level] = resource
			else:
				push_warning("DataManager: File %s is not a valid LevelData" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("DataManager: Loaded %d levels" % _levels.size())


func _load_shops() -> void:
	var dir := DirAccess.open(SHOPS_PATH)
	if dir == null:
		push_warning("Shops directory not found: " + SHOPS_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(SHOPS_PATH + file_name)
			if resource and resource.get("shop_level") != null:
				_shop_stages[resource.shop_level] = resource
			else:
				push_warning("DataManager: File %s is not a valid ShopData" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("DataManager: Loaded %d shop stages" % _shop_stages.size())


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
