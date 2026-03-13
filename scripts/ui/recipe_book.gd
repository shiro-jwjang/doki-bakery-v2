extends Control

## RecipeBook UI
##
## 레시피북 UI + EventBus 시그널 연동
## SNA-142: RecipeBook UI + 아바타 세이브/로드 연동

const RecipeItemScene = preload("res://scenes/ui/recipe_item.tscn")

@onready var _title_label: Label = $Panel/VBoxContainer/Header/TitleLabel
@onready var _close_button: Button = $Panel/VBoxContainer/Header/CloseButton
@onready var _search_box: LineEdit = $Panel/VBoxContainer/Controls/SearchBox
@onready var _filter_option: OptionButton = $Panel/VBoxContainer/Controls/FilterOption
@onready var _sort_option: OptionButton = $Panel/VBoxContainer/Controls/SortOption
@onready var _scroll_container: ScrollContainer = $Panel/VBoxContainer/ScrollContainer
@onready var _bread_grid: GridContainer = $Panel/VBoxContainer/ScrollContainer/BreadGrid
@onready var _detail_popup: Panel = $DetailPopup
@onready var _detail_name_label: Label = $DetailPopup/VBoxContainer/DetailNameLabel
@onready var _detail_icon: TextureRect = $DetailPopup/VBoxContainer/DetailIcon
@onready var _detail_desc_label: Label = $DetailPopup/VBoxContainer/DetailDescLabel
@onready var _detail_price_label: Label = $DetailPopup/VBoxContainer/DetailPriceLabel
@onready var _detail_difficulty_label: Label = $DetailPopup/VBoxContainer/DetailDifficultyLabel
@onready var _detail_close_button: Button = $DetailPopup/VBoxContainer/DetailCloseButton

var _current_filter: String = "all"
var _current_sort: String = "name"
var _recipe_items: Array = []


func _ready() -> void:
	# 필터/정렬 옵션 초기화
	_setup_filter_options()
	_setup_sort_options()

	# 시그널 연결
	_close_button.pressed.connect(_on_close_pressed)
	_search_box.text_changed.connect(_on_search_text_changed)
	_filter_option.item_selected.connect(_on_filter_item_selected)
	_sort_option.item_selected.connect(_on_sort_item_selected)
	_detail_close_button.pressed.connect(_on_detail_close_pressed)

	# 레시피 로드
	_load_recipes()


@warning_ignore("native_method_override")
func show() -> void:
	visible = true
	EventBus.recipe_book_opened.emit()


@warning_ignore("native_method_override")
func hide() -> void:
	visible = false
	EventBus.recipe_book_closed.emit()


## 레시피 로드 및 표시
func _load_recipes() -> void:
	var all_recipes = DataManager.get_all_recipes()
	_recipe_items.clear()

	# 기존 아이템 제거
	for child in _bread_grid.get_children():
		child.queue_free()

	# 레시피 아이템 생성
	for recipe in all_recipes:
		var item = RecipeItemScene.instantiate()
		_bread_grid.add_child(item)
		item.setup(recipe)
		item.pressed.connect(_on_item_pressed.bind(recipe.id))
		_recipe_items.append(item)

	# 현재 필터/정렬 적용
	_apply_current_filter_and_sort()


## 필터 옵션 설정
func _setup_filter_options() -> void:
	_filter_option.clear()
	_filter_option.add_item("전체", 0)
	_filter_option.add_item("해금됨", 1)
	_filter_option.add_item("해금안됨", 2)
	_filter_option.selected = 0


## 정렬 옵션 설정
func _setup_sort_options() -> void:
	_sort_option.clear()
	_sort_option.add_item("이름순", 0)
	_sort_option.add_item("난이도순", 1)
	_sort_option.add_item("판매가순", 2)
	_sort_option.selected = 0


## 필터 적용
func apply_filter(filter_type: String) -> void:
	_current_filter = filter_type
	_apply_current_filter_and_sort()


## 정렬 적용
func apply_sort(sort_type: String) -> void:
	_current_sort = sort_type
	_apply_current_filter_and_sort()


## 빵 상세 정보 표시
func show_bread_details(recipe_id: String) -> void:
	var recipe = DataManager.get_recipe(recipe_id)
	if not recipe:
		return

	_detail_name_label.text = recipe.display_name
	_detail_desc_label.text = recipe.description
	_detail_price_label.text = "가격: %dG" % recipe.base_price
	_detail_difficulty_label.text = "난이도: Lv.%d" % recipe.unlock_level

	if recipe.icon:
		_detail_icon.texture = recipe.icon
	else:
		_detail_icon.texture = null

	_detail_popup.visible = true
	EventBus.bread_details_viewed.emit(recipe_id)


## 현재 필터와 정렬 적용
func _apply_current_filter_and_sort() -> void:
	var all_recipes = DataManager.get_all_recipes()
	var filtered_recipes = []

	# 필터링
	for recipe in all_recipes:
		var should_show = false

		match _current_filter:
			"all":
				should_show = true
			"unlocked":
				should_show = recipe.unlock_level <= GameManager.level
			"locked":
				should_show = recipe.unlock_level > GameManager.level

		if should_show:
			filtered_recipes.append(recipe)

	# 정렬
	match _current_sort:
		"difficulty":
			filtered_recipes.sort_custom(_compare_by_difficulty)
		"price":
			filtered_recipes.sort_custom(_compare_by_price)
		"name":
			filtered_recipes.sort_custom(_compare_by_name)

	# 검색어 적용
	var search_text = _search_box.text.to_lower()
	if search_text != "":
		var searched_recipes = []
		for recipe in filtered_recipes:
			if search_text in recipe.display_name.to_lower():
				searched_recipes.append(recipe)
		filtered_recipes = searched_recipes

	# 아이템 표시/숨김 및 순서 변경
	# 모든 아이템을 숨김
	for item in _recipe_items:
		item.visible = false
		_bread_grid.remove_child(item)

	# 필터링된 순서대로 다시 추가
	for recipe in filtered_recipes:
		for item in _recipe_items:
			if "recipe_id" in item and item.recipe_id == recipe.id:
				item.visible = true
				_bread_grid.add_child(item)
				break


## 난이도 비교 함수
func _compare_by_difficulty(a: Resource, b: Resource) -> bool:
	return a.unlock_level < b.unlock_level


## 가격 비교 함수 (내림차순)
func _compare_by_price(a: Resource, b: Resource) -> bool:
	return a.base_price > b.base_price


## 이름 비교 함수
func _compare_by_name(a: Resource, b: Resource) -> bool:
	return a.display_name < b.display_name


## 닫기 버튼 클릭
func _on_close_pressed() -> void:
	hide()


## 검색어 변경
func _on_search_text_changed(_new_text: String) -> void:
	_apply_current_filter_and_sort()


## 필터 옵션 선택
func _on_filter_item_selected(index: int) -> void:
	match index:
		0:
			apply_filter("all")
		1:
			apply_filter("unlocked")
		2:
			apply_filter("locked")


## 정렬 옵션 선택
func _on_sort_item_selected(index: int) -> void:
	match index:
		0:
			apply_sort("name")
		1:
			apply_sort("difficulty")
		2:
			apply_sort("price")


## 아이템 클릭
func _on_item_pressed(recipe_id: String) -> void:
	show_bread_details(recipe_id)


## 상세 팝업 닫기
func _on_detail_close_pressed() -> void:
	_detail_popup.visible = false
