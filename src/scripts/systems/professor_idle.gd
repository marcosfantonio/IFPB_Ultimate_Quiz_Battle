class_name ProfessorIdle
extends Node2D
## Ciclo de idle, movimentação e poses do professor Damiao.

enum MoveState { WAITING, OUTBOUND, TURN_PREP, WAITING_AT_RIGHT, RETURNING }

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
@onready var _fatality_silhouette: Sprite2D = $FatalitySilhouette

var _elapsed: float = 0.0
var _frame_index: int = 0
var _base_position: Vector2
var _base_flip_h: bool = false
var _move_countdown: float = 0.0
var _movement_state: MoveState = MoveState.WAITING
var _movement_elapsed: float = 0.0
var _holding_turn_pose: bool = false
var _fatality_active: bool = false
var _battle_intro_mode: bool = false
var _intro_frame_index: int = 0
var _base_z_index: int = 0
var _fatality_return_flip: bool = false


func _ready() -> void:
	_base_position = position
	_base_flip_h = _sprite.flip_h
	_base_z_index = z_index
	_shadow.flip_h = _base_flip_h
	_fatality_silhouette.scale = _sprite.scale * 1.5
	_fatality_silhouette.flip_h = _base_flip_h
	_display_frame(IDLE_FRAMES[_frame_index])
	_move_countdown = _random_move_interval()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _fatality_active:
		return
	if _battle_intro_mode:
		_elapsed += delta
		while _elapsed >= GameConfig.PROFESSOR_IDLE_FRAME_DURATION:
			_elapsed -= GameConfig.PROFESSOR_IDLE_FRAME_DURATION
			_intro_frame_index = (_intro_frame_index + 1) % 2
			var intro_frame: Texture2D = GameAssets.TEX_PROFESSOR_IDLE_1 if _intro_frame_index == 0 else GameAssets.TEX_PROFESSOR_IDLE_2
			_display_frame(intro_frame)
		return
	if not _holding_turn_pose:
		_elapsed += delta
		while _elapsed >= GameConfig.PROFESSOR_IDLE_FRAME_DURATION:
			_elapsed -= GameConfig.PROFESSOR_IDLE_FRAME_DURATION
			_frame_index = (_frame_index + 1) % IDLE_FRAMES.size()
			_display_frame(IDLE_FRAMES[_frame_index])

	match _movement_state:
		MoveState.WAITING:
			_move_countdown -= delta
			if _move_countdown <= 0.0:
				_movement_state = MoveState.OUTBOUND
				_movement_elapsed = 0.0
		MoveState.OUTBOUND, MoveState.TURN_PREP:
			_process_outbound_movement(delta)
		MoveState.WAITING_AT_RIGHT:
			_movement_elapsed += delta
			if _movement_elapsed >= GameConfig.PROFESSOR_MOVE_PAUSE:
				_movement_state = MoveState.RETURNING
				_movement_elapsed = 0.0
		MoveState.RETURNING:
			_process_return_movement(delta)


func _process_outbound_movement(delta: float) -> void:
	_movement_elapsed += delta
	var turn_pose_start: float = maxf(
		0.0,
		GameConfig.PROFESSOR_MOVE_DURATION - GameConfig.PROFESSOR_TURN_PREPARE_TIME
	)
	if _movement_state == MoveState.OUTBOUND and _movement_elapsed >= turn_pose_start:
		_movement_state = MoveState.TURN_PREP
		_holding_turn_pose = true
		_display_frame(GameAssets.TEX_PROFESSOR_IDLE_3)

	var progress: float = clampf(_movement_elapsed / GameConfig.PROFESSOR_MOVE_DURATION, 0.0, 1.0)
	position.x = lerpf(_base_position.x, _base_position.x + GameConfig.PROFESSOR_MOVE_DISTANCE, _ease_in_out(progress))
	if progress >= 1.0:
		position.x = _base_position.x + GameConfig.PROFESSOR_MOVE_DISTANCE
		_sprite.flip_h = not _base_flip_h
		_shadow.flip_h = _sprite.flip_h
		_holding_turn_pose = false
		_display_frame(IDLE_FRAMES[_frame_index])
		_movement_state = MoveState.WAITING_AT_RIGHT
		_movement_elapsed = 0.0


func _process_return_movement(delta: float) -> void:
	_movement_elapsed += delta
	var progress: float = clampf(_movement_elapsed / GameConfig.PROFESSOR_MOVE_DURATION, 0.0, 1.0)
	position.x = lerpf(
		_base_position.x + GameConfig.PROFESSOR_MOVE_DISTANCE,
		_base_position.x,
		_ease_in_out(progress)
	)
	if progress >= 1.0:
		position.x = _base_position.x
		_sprite.flip_h = _base_flip_h
		_shadow.flip_h = _base_flip_h
		_movement_state = MoveState.WAITING
		_movement_elapsed = 0.0
		_move_countdown = _random_move_interval()


func begin_fatality() -> void:
	_fatality_active = true
	_fatality_return_flip = _sprite.flip_h
	_holding_turn_pose = true
	_movement_state = MoveState.WAITING
	_movement_elapsed = 0.0
	_shadow.flip_h = _fatality_return_flip
	_fatality_silhouette.flip_h = _fatality_return_flip
	set_fatality_spotlight(true)
	_display_frame(GameAssets.TEX_PROFESSOR_IDLE_RAGE)


func set_battle_intro_mode(active: bool) -> void:
	if _fatality_active:
		return
	_battle_intro_mode = active
	_elapsed = 0.0
	_holding_turn_pose = false
	_movement_state = MoveState.WAITING
	_movement_elapsed = 0.0
	_move_countdown = _random_move_interval()
	_sprite.flip_h = _base_flip_h
	_shadow.flip_h = _base_flip_h
	_fatality_silhouette.flip_h = _base_flip_h
	_intro_frame_index = 0
	_frame_index = 0
	_display_frame(GameAssets.TEX_PROFESSOR_IDLE_1)


func set_fatality_spotlight(active: bool) -> void:
	if not _fatality_active:
		return
	_fatality_silhouette.visible = false
	z_index = GameConfig.PROFESSOR_FATALITY_Z_INDEX if active else _base_z_index


func set_fatality_pose(texture: Texture2D) -> void:
	if _fatality_active:
		_display_frame(texture)


func move_fatality_to_y(target_y: float, duration: float) -> void:
	if not _fatality_active:
		return
	var movement := create_tween()
	movement.tween_property(self, "position:y", target_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await movement.finished


func return_from_fatality() -> Tween:
	if not _fatality_active:
		return null
	position = Vector2(_base_position.x, GameConfig.PROFESSOR_FATALITY_EXIT_Y)
	_sprite.flip_h = _fatality_return_flip
	_shadow.flip_h = _fatality_return_flip
	_display_frame(GameAssets.TEX_PROFESSOR_JUMPING_2)
	var movement := create_tween()
	movement.tween_property(
		self,
		"position:y",
		_base_position.y - 140.0,
		GameConfig.PROFESSOR_FATALITY_RETURN_JUMP_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement.tween_callback(func() -> void: _display_frame(GameAssets.TEX_PROFESSOR_JUMPING))
	movement.tween_property(
		self,
		"position:y",
		_base_position.y,
		GameConfig.PROFESSOR_FATALITY_RETURN_IDLE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement.tween_callback(func() -> void: position = _base_position)
	return movement


func finish_fatality() -> void:
	if not _fatality_active:
		return
	position = _base_position
	_sprite.flip_h = _base_flip_h
	_shadow.flip_h = _base_flip_h
	_fatality_silhouette.flip_h = _base_flip_h
	_fatality_silhouette.visible = false
	z_index = _base_z_index
	_fatality_active = false
	_holding_turn_pose = false
	_movement_state = MoveState.WAITING
	_movement_elapsed = 0.0
	_move_countdown = _random_move_interval()
	_display_frame(IDLE_FRAMES[_frame_index])


func _display_frame(texture: Texture2D) -> void:
	_sprite.texture = texture
	_shadow.texture = texture
	_fatality_silhouette.texture = texture


func _random_move_interval() -> float:
	return randf_range(
		GameConfig.PROFESSOR_MOVE_INTERVAL_RANGE.x,
		GameConfig.PROFESSOR_MOVE_INTERVAL_RANGE.y
	)


func _ease_in_out(value: float) -> float:
	return 0.5 - cos(value * PI) * 0.5
