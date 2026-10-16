class_name BattleResultsScreen
extends Control
## Animação de vitória antes de voltar ao menu principal.

signal finished

const DISPLAY_TIME = 10.0
const ENTRANCE_TIME = 1.05
const FADE_TIME = 1.0

var _overlay: ColorRect
var _team_label: Label
var _message_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 950
	_build_overlay()
	_build_labels()
	UITheme.apply_font(self)


func play(winning_team: String) -> void:
	visible = true
	_overlay.color = Color(0, 0, 0, 0.88)
	_team_label.text = winning_team
	_team_label.scale = Vector2(0.8, 0.8)
	_team_label.modulate.a = 0.0
	_message_label.modulate.a = 0.0

	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(_team_label, "modulate:a", 1.0, 0.6)
	entrance.tween_property(_team_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(_message_label, "modulate:a", 1.0, 0.8).set_delay(0.25)
	await entrance.finished
	await get_tree().create_timer(DISPLAY_TIME - ENTRANCE_TIME).timeout

	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(_overlay, "color", Color(0, 0, 0, 1), FADE_TIME)
	fade_out.tween_property(_team_label, "modulate:a", 0.0, FADE_TIME)
	fade_out.tween_property(_message_label, "modulate:a", 0.0, FADE_TIME)
	await fade_out.finished
	finished.emit()


func fade_to_menu(duration: float) -> void:
	var fade := create_tween()
	fade.tween_property(_overlay, "color", Color(0, 0, 0, 0), duration)
	await fade.finished
	visible = false


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.size = GameConfig.SCREEN_SIZE
	_overlay.color = Color(0, 0, 0, 0.88)
	add_child(_overlay)


func _build_labels() -> void:
	_team_label = Label.new()
	_team_label.position = Vector2(126, 230)
	_team_label.size = Vector2(900, 90)
	_team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_team_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_team_label.add_theme_font_size_override("font_size", 42)
	_team_label.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	add_child(_team_label)

	_message_label = Label.new()
	_message_label.text = "ÓTIMO JOGO!"
	_message_label.position = Vector2(126, 335)
	_message_label.size = Vector2(900, 70)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 36)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_message_label)
