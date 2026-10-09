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
var _trail: Array[Vector2] = []
var _time: float = 0.0
var _duration: float = 0.001


func launch(attacker: int, from: Vector2, to: Vector2) -> void:
	_attacker = attacker
	_start = from
	_target = to
	_position = from
	_trail.clear()
	_trail.append(from)
	_time = 0.0
	_duration = maxf(from.distance_to(to) / GameConfig.PROJECTILE_SPEED, 0.001)
	_active = true
	queue_redraw()


func is_flying() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active:
		return

	_time += delta
	var t := clampf(_time / _duration, 0.0, 1.0)
	var base := _start.lerp(_target, t)
	# Arco parabólico: sin(pi * t) tem pico em t = 0.5
	var arc_offset := GameConfig.PROJECTILE_ARC_HEIGHT * sin(PI * t)

	_position = Vector2(base.x, base.y - arc_offset)
	_trail.append(_position)
	if _trail.size() > GameConfig.TRAIL_MAX_POINTS:
		_trail.pop_front()

	if t >= 1.0:
		_active = false
		_position = _target
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

	draw_circle(to_local(_position), 10.0, Color(1, 0.85, 0.1))
	draw_circle(to_local(_position), 6.0, Color(1, 1, 0.8))
