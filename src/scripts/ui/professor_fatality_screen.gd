class_name ProfessorFatalityScreen
extends Control
## Camadas visuais do golpe especial do professor.

signal domino_impact_reached
signal domino_effect_finished
signal rage_fade_out_started
signal fatality_fade_started
signal fatality_fade_finished

var _overlay: ColorRect
var _rage_image: TextureRect
var _rage_white_flash: ColorRect
var _message: Label
var _special_image: TextureRect
var _domino: TextureRect
var _explosion: TextureRect

const SPECIAL_FRAMES = [
	GameAssets.TEX_PROFESSOR_SPECIAL_1,
	GameAssets.TEX_PROFESSOR_SPECIAL_2,
	GameAssets.TEX_PROFESSOR_SPECIAL_3,
	GameAssets.TEX_PROFESSOR_SPECIAL_4,
	GameAssets.TEX_PROFESSOR_SPECIAL_5,
	GameAssets.TEX_PROFESSOR_SPECIAL_6,
]
const SPECIAL_LOOP = [1, 2, 3, 4, 5, 6, 5, 4, 3, 2]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1200
	_overlay = $Overlay as ColorRect
	_rage_image = $RageImage as TextureRect
	_rage_white_flash = $RageWhiteFlash as ColorRect
	_message = $Message as Label
	_special_image = $SpecialImage as TextureRect
	_domino = $Domino as TextureRect
	_explosion = $Explosion as TextureRect
	_explosion.scale = Vector2.ONE * 4.0
	_explosion.pivot_offset = _explosion.size * 0.5
	UITheme.apply_font(self)


func show_rage_idle() -> void:
	visible = true
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0.9)
	_rage_image.visible = false
	_rage_white_flash.visible = false
	_message.visible = false
	_special_image.visible = false
	_domino.visible = false
	_explosion.visible = false


func set_fatality_victim_name(player_name: String) -> void:
	_message.text = "VOCÊ CHUTOU, %s?!" % player_name


func play_rage_image() -> void:
	visible = true
	_rage_white_flash.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_rage_white_flash.offset_left = 0.0
	_rage_white_flash.offset_top = 66.0
	_rage_white_flash.offset_right = GameConfig.SCREEN_SIZE.x
	_rage_white_flash.offset_bottom = 578.0
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0.9)
	_rage_image.visible = true
	_rage_white_flash.visible = true
	_rage_white_flash.color.a = 1.0
	_message.visible = true
	_special_image.visible = false
	_domino.visible = false
	_explosion.visible = false
	var fade_duration := GameConfig.PROFESSOR_RAGE_DURATION * 0.2
	var white_fade := create_tween()
	white_fade.tween_property(_rage_white_flash, "color:a", 0.0, fade_duration)
	white_fade.tween_interval(GameConfig.PROFESSOR_RAGE_DURATION - fade_duration * 2.0)
	white_fade.tween_callback(func() -> void: rage_fade_out_started.emit())
	white_fade.tween_property(_rage_white_flash, "color:a", 1.0, fade_duration)
	await white_fade.finished
	_rage_white_flash.visible = false
	_rage_image.visible = false


func show_jump_phase() -> void:
	visible = true
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0.9)
	_rage_image.visible = false
	_rage_white_flash.visible = false
	_message.visible = false
	_special_image.visible = false
	_domino.visible = false
	_explosion.visible = false


func play_special() -> void:
	_overlay.visible = false
	_rage_image.visible = false
	_rage_white_flash.visible = false
	_message.visible = false
	_domino.visible = false
	_explosion.visible = false
	_special_image.visible = true
	_rage_white_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rage_white_flash.visible = true
	_rage_white_flash.color.a = 1.0
	var fade_duration := GameConfig.PROFESSOR_RAGE_DURATION * 0.2
	fatality_fade_started.emit()
	var special_fade := create_tween()
	special_fade.tween_property(_rage_white_flash, "color:a", 0.0, fade_duration)
	var frame_count: int = ceili(
		GameConfig.PROFESSOR_SPECIAL_DURATION / GameConfig.PROFESSOR_SPECIAL_FRAME_DURATION
	)
	var loop_index: int = 0
	for _frame in range(frame_count):
		var frame_number: int = SPECIAL_LOOP[loop_index]
		_special_image.texture = SPECIAL_FRAMES[frame_number - 1]
		loop_index = (loop_index + 1) % SPECIAL_LOOP.size()
		await get_tree().create_timer(GameConfig.PROFESSOR_SPECIAL_FRAME_DURATION).timeout
	if special_fade.is_running():
		await special_fade.finished
	fatality_fade_finished.emit()
	var special_fade_out := create_tween()
	special_fade_out.tween_property(_rage_white_flash, "color:a", 1.0, fade_duration)
	await special_fade_out.finished
	_rage_white_flash.visible = false
	_special_image.visible = false
	visible = false


func start_domino_attack(target_center: Vector2, spin_direction: float) -> void:
	visible = true
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0.9)
	_rage_image.visible = false
	_message.visible = false
	_special_image.visible = false
	_explosion.visible = false
	_domino.visible = true
	_domino.modulate.a = 1.0
	_domino.rotation = 0.0
	# Surge do canto superior direito, parcialmente fora da tela.
	_domino.position = Vector2(target_center.x - _domino.size.x * 0.5, -_domino.size.y)
	_domino.pivot_offset = _domino.size * 0.5

	var fall := create_tween().set_parallel(true)
	fall.tween_property(
		_domino,
		"position",
		target_center - _domino.size * 0.5,
		GameConfig.PROFESSOR_DOMINO_FLIGHT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fall.tween_property(
		_domino,
		"rotation",
		TAU * GameConfig.PROFESSOR_DOMINO_SPIN_TURNS * spin_direction,
		GameConfig.PROFESSOR_DOMINO_FLIGHT_DURATION
	).set_trans(Tween.TRANS_LINEAR)
	fall.finished.connect(_on_domino_landed.bind(target_center), CONNECT_ONE_SHOT)


func _on_domino_landed(target_center: Vector2) -> void:
	_domino.visible = false
	_explosion.pivot_offset = _explosion.size * 0.5
	_explosion.position = target_center - _explosion.size * 0.5
	_explosion.modulate.a = 1.0
	_explosion.visible = true
	domino_impact_reached.emit()
	var explosion_fade := create_tween()
	explosion_fade.tween_property(_explosion, "modulate:a", 0.0, GameConfig.PROFESSOR_EXPLOSION_FADE_DURATION)
	explosion_fade.finished.connect(_on_domino_effect_finished, CONNECT_ONE_SHOT)


func _on_domino_effect_finished() -> void:
	_explosion.visible = false
	domino_effect_finished.emit()


func is_domino_effect_running() -> bool:
	return _explosion.visible


func fade_back_to_game() -> void:
	_overlay.visible = true
	_domino.visible = false
	_explosion.visible = false
	var fade := create_tween()
	fade.tween_property(_overlay, "color", Color(0, 0, 0, 0), GameConfig.PROFESSOR_FATALITY_SCREEN_FADE)
	await fade.finished
	visible = false
