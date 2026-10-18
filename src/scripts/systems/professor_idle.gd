class_name ProfessorIdle
extends Node2D
## Animação idle em loop do professor Damiao.

const IDLE_FRAMES = [
	GameAssets.TEX_PROFESSOR_IDLE_1,
	GameAssets.TEX_PROFESSOR_IDLE_2,
	GameAssets.TEX_PROFESSOR_IDLE_1,
	GameAssets.TEX_PROFESSOR_IDLE_2,
	GameAssets.TEX_PROFESSOR_IDLE_1,
	GameAssets.TEX_PROFESSOR_IDLE_2,
	GameAssets.TEX_PROFESSOR_IDLE_3,
	GameAssets.TEX_PROFESSOR_IDLE_4,
	GameAssets.TEX_PROFESSOR_IDLE_5,
]

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Sprite2D = $Shadow
var _elapsed: float = 0.0
var _frame_index: int = 0
var _base_position: Vector2
var _base_flip_h: bool = false
var _move_countdown: float = 0.0
var _is_moving: bool = false
var _holding_turn_pose: bool = false


func _ready() -> void:
	_base_position = position
	_base_flip_h = _sprite.flip_h
	_shadow.flip_h = _base_flip_h
	_display_frame(IDLE_FRAMES[_frame_index])
	_move_countdown = randf_range(
		GameConfig.PROFESSOR_MOVE_INTERVAL_RANGE.x,
		GameConfig.PROFESSOR_MOVE_INTERVAL_RANGE.y
	)


func _process(delta: float) -> void:
	if not _holding_turn_pose:
		_elapsed += delta
		while _elapsed >= GameConfig.PROFESSOR_IDLE_FRAME_DURATION:
			_elapsed -= GameConfig.PROFESSOR_IDLE_FRAME_DURATION
			_frame_index = (_frame_index + 1) % IDLE_FRAMES.size()
			_display_frame(IDLE_FRAMES[_frame_index])

	if _is_moving:
		return
	_move_countdown -= delta
	if _move_countdown <= 0.0:
		_start_random_move()


func _start_random_move() -> void:
	_is_moving = true
	var move_right := create_tween()
	move_right.tween_property(
		self,
		"position:x",
		_base_position.x + GameConfig.PROFESSOR_MOVE_DISTANCE,
		GameConfig.PROFESSOR_MOVE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var time_before_turn: float = maxf(
		0.0,
		GameConfig.PROFESSOR_MOVE_DURATION - GameConfig.PROFESSOR_TURN_PREPARE_TIME
	)
	await get_tree().create_timer(time_before_turn).timeout
	_holding_turn_pose = true
	_display_frame(GameAssets.TEX_PROFESSOR_IDLE_3)
	await move_right.finished
	_sprite.flip_h = not _base_flip_h
	_shadow.flip_h = _sprite.flip_h
	_holding_turn_pose = false
	_display_frame(IDLE_FRAMES[_frame_index])
	await get_tree().create_timer(GameConfig.PROFESSOR_MOVE_PAUSE).timeout
	var return_home := create_tween()
	return_home.tween_property(
		self,
		"position:x",
		_base_position.x,
		GameConfig.PROFESSOR_MOVE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await return_home.finished
	position = _base_position
	_sprite.flip_h = _base_flip_h
	_shadow.flip_h = _base_flip_h
	_is_moving = false
	_move_countdown = randf_range(
		GameConfig.PROFESSOR_MOVE_INTERVAL_RANGE.x,
		GameConfig.PROFESSOR_MOVE_INTERVAL_RANGE.y
	)


func _display_frame(texture: Texture2D) -> void:
	_sprite.texture = texture
	_shadow.texture = texture
