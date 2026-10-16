class_name IdleAnimator
extends Node
## Alterna aleatoriamente entre a pose normal e a alternativa dos alunos.
## Só emite o sinal; quem desenha decide o que fazer com ele.

signal pose_changed(player: int, alt_pose: bool)

var _player_id: int = 0
var _timer: float = 0.0
var _showing_alt: bool = false
var _alt_duration: float = 1.5
var _next_alt_in: float = 0.0


func setup(player: int) -> void:
	_player_id = player
	_next_alt_in = randf_range(GameConfig.IDLE_FIRST_DELAY_RANGE.x, GameConfig.IDLE_FIRST_DELAY_RANGE.y)


func _process(delta: float) -> void:
	_timer += delta
	if not _showing_alt:
		if _timer >= _next_alt_in:
			_showing_alt = true
			_timer = 0.0
			_alt_duration = randf_range(GameConfig.IDLE_POSE_RANGE.x, GameConfig.IDLE_POSE_RANGE.y)
			pose_changed.emit(_player_id, true)
	elif _timer >= _alt_duration:
		_showing_alt = false
		_timer = 0.0
		_next_alt_in = randf_range(GameConfig.IDLE_WAIT_RANGE.x, GameConfig.IDLE_WAIT_RANGE.y)
		pose_changed.emit(_player_id, false)
