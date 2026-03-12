class_name AvatarCompositor
extends Node2D

## SNA-150: 아바타 레이어 합성 시스템
## AvatarCompositor - 레이어 합성 및 애니메이션 동기화

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

	# 모든 레이어의 프레임 동기화
	for layer: AnimatedSprite2D in _layer_list:
		if layer and layer.sprite_frames:
			var max_frames: int = layer.sprite_frames.get_frame_count(current_animation)
			if frame < max_frames:
				layer.frame = frame


## 아바타 데이터 적용
func apply_avatar_data(data: AvatarData) -> void:
	if not data:
		return

	# 각 레이어에 텍스처 적용
	# Note: 실제 구현에서는 SpriteFrames를 동적으로 생성해야 함
	# 현재는 씬에 미리 설정된 SpriteFrames를 사용
