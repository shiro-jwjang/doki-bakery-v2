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
	var dir := DirAccess.open(RECIPES_PATH)
	if dir == null:
		push_warning("Recipes directory not found: " + RECIPES_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(RECIPES_PATH + file_name) as RecipeData
			if resource:
				_recipes[resource.id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_levels() -> void:
	var dir := DirAccess.open(LEVELS_PATH)
	if dir == null:
		push_warning("Levels directory not found: " + LEVELS_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(LEVELS_PATH + file_name) as LevelData
			if resource:
				_levels[resource.level] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_shops() -> void:
	var dir := DirAccess.open(SHOPS_PATH)
	if dir == null:
		push_warning("Shops directory not found: " + SHOPS_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(SHOPS_PATH + file_name) as ShopData
			if resource:
				_shop_stages[resource.shop_level] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


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
