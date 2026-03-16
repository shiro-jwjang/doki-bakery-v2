class_name AvatarCompositor
extends Node2D

## SNA-150: 아바타 레이어 합성 시스템
## AvatarCompositor - 레이어 합성 및 애니메이션 동기화

## 스프라이트 시트 프레임 크기 (50x60 pixels per frame)
const FRAME_WIDTH: int = 50
const FRAME_HEIGHT: int = 60
const FRAME_COUNT: int = 5

## 현재 재생 중인 애니메이션
var current_animation: String = ""

## 현재 프레임
var current_frame: int = 0

## 모든 레이어 목록
var _layer_list: Array[AnimatedSprite2D] = []

## 레이어 홀더
@onready var layers: Node2D = $Layers

## 애니메이션 레이어들 (Z-index 순서)
@onready var hairdn: AnimatedSprite2D = $Layers/HairDn
@onready var body: AnimatedSprite2D = $Layers/Body
@onready var eye: AnimatedSprite2D = $Layers/Eye
@onready var hairup: AnimatedSprite2D = $Layers/HairUp
@onready var hat: AnimatedSprite2D = $Layers/Hat


func _ready() -> void:
	# 레이어 목록 초기화
	_layer_list = [hairdn, body, eye, hairup, hat]

	# 기본 idle 애니메이션 재생 (씬에 베이크된 SpriteFrames 사용)
	play_animation("idle")


## 애니메이션 재생
func play_animation(anim_name: String) -> void:
	current_animation = anim_name
	current_frame = 0

	# 모든 레이어에 같은 애니메이션 재생
	for layer: AnimatedSprite2D in _layer_list:
		if layer and layer.sprite_frames:
			if layer.sprite_frames.has_animation(anim_name):
				layer.play(anim_name)


## 프레임 동기화
func _sync_frame(frame: int) -> void:
	current_frame = frame

	if current_animation.is_empty():
		return

	# 모든 레이어의 프레임 동기화
	for layer: AnimatedSprite2D in _layer_list:
		if layer and layer.sprite_frames:
			if not layer.sprite_frames.has_animation(current_animation):
				continue
			var max_frames: int = layer.sprite_frames.get_frame_count(current_animation)
			if frame < max_frames:
				layer.frame = frame


## 아바타 데이터 적용
func apply_avatar_data(data: AvatarData) -> void:
	if not data:
		return

	# 각 레이어에 텍스처 적용
	_set_layer_texture(hairdn, data.hairdn_texture)
	_set_layer_texture(body, data.body_texture)
	_set_layer_texture(eye, data.eye_texture)
	_set_layer_texture(hairup, data.hairup_texture)
	_set_layer_texture(hat, data.hat_texture)

	# idle 애니메이션 재생
	play_animation("idle")


## 개별 레이어에 스프라이트 시트 텍스처를 프레임 단위로 분할하여 적용
func _set_layer_texture(layer: AnimatedSprite2D, texture: Texture2D) -> void:
	if not layer:
		return

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 5.0)

	if texture:
		# 스프라이트 시트를 AtlasTexture로 프레임 분할
		for i in range(FRAME_COUNT):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
			frames.add_frame("idle", atlas)

	# 자동 생성된 "default" 애니메이션 제거
	if frames.has_animation("default"):
		frames.remove_animation("default")

	layer.sprite_frames = frames
