class_name Projectile
extends Node2D
## Projétil com trajetória em arco e rastro. Recebe pontos em coordenadas
## globais, voa até o alvo e emite `hit`. Não aplica dano nem toca som.

signal hit(attacker: int)

var _active: bool = false
var _attacker: int = 0
var _start: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _position: Vector2 = Vector2.ZERO
var _shadow_y: float = 0.0
var _trail: Array[Vector2] = []
var _time: float = 0.0
var _duration: float = 0.001
@onready var _ball_sprite: Sprite2D = $BallSprite
@onready var _ball_shadow: Sprite2D = $BallShadow


func _ready() -> void:
	_ball_shadow.flip_v = true
	_ball_shadow.modulate = Color(0.0, 0.0, 0.0, GameConfig.PROJECTILE_SHADOW_OPACITY)
	_ball_shadow.scale = Vector2(
		GameConfig.PROJECTILE_SCALE,
		GameConfig.PROJECTILE_SCALE * GameConfig.PROJECTILE_SHADOW_HEIGHT_RATIO
	)
	_ball_shadow.visible = false
	_ball_sprite.scale = Vector2.ONE * GameConfig.PROJECTILE_SCALE
	_ball_sprite.visible = false


func launch(attacker: int, from: Vector2, to: Vector2, shadow_y: float) -> void:
	_attacker = attacker
	_start = from
	_target = to
	_shadow_y = shadow_y
	_position = from
	_trail.clear()
	_trail.append(from)
	_time = 0.0
	_duration = maxf(from.distance_to(to) / GameConfig.PROJECTILE_SPEED, 0.001)
	_ball_sprite.rotation = 0.0
	_active = true
	_update_ball_visuals()
	queue_redraw()


func is_flying() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active:
		return

	_time += delta
	_ball_sprite.rotation += deg_to_rad(GameConfig.PROJECTILE_ROTATION_SPEED) * delta
	var t := clampf(_time / _duration, 0.0, 1.0)
	var base := _start.lerp(_target, t)
	# Arco parabólico: sin(pi * t) tem pico em t = 0.5
	var arc_offset := GameConfig.PROJECTILE_ARC_HEIGHT * sin(PI * t)

	_position = Vector2(base.x, base.y - arc_offset)
	_update_ball_visuals()
	_trail.append(_position)
	if _trail.size() > GameConfig.TRAIL_MAX_POINTS:
		_trail.pop_front()

	if t >= 1.0:
		_active = false
		_position = _target
		_ball_sprite.visible = false
		_ball_shadow.visible = false
		queue_redraw()
		hit.emit(_attacker)
		return

	queue_redraw()


func _draw() -> void:
	if not _active or _trail.size() < 2:
		return

	for i in range(1, _trail.size()):
		var alpha := float(i) / float(_trail.size())
		var color := Color(1, 0.9, 0.2, alpha)
		var width := GameConfig.TRAIL_WIDTH * alpha + 1.0
		draw_line(to_local(_trail[i - 1]), to_local(_trail[i]), color, width)



func _update_ball_visuals() -> void:
	var local_position := to_local(_position)
	var texture_height: float = GameAssets.TEX_PAPER_BALL.get_size().y
	var displayed_height: float = texture_height * GameConfig.PROJECTILE_SCALE
	_ball_sprite.position = local_position
	var shadow_top := to_local(Vector2(_position.x, _shadow_y))
	_ball_shadow.position = shadow_top + Vector2(0.0, displayed_height * GameConfig.PROJECTILE_SHADOW_HEIGHT_RATIO * 0.5)
	_ball_sprite.visible = _active
	_ball_shadow.visible = _active
