class_name BattleResultsScreen
extends Control
## Animação de vitória antes de voltar ao menu principal.

signal finished

const DISPLAY_TIME = 10.0
const ENTRANCE_TIME = 1.05
const KO_DISPLAY_TIME = 1.8
const FADE_TIME = 1.0

var _overlay: ColorRect
var _team_label: Label
var _stats_row: HBoxContainer
var _correct_label: Label
var _errors_label: Label
var _message_label: Label
var _ko_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 950
	_build_overlay()
	_build_labels()
	UITheme.apply_font(self)


func play(winning_team: String, correct_count: int, error_count: int) -> void:
	visible = true
	_overlay.color = Color(0, 0, 0, 0.88)
	_team_label.text = "Equipe %s venceu!" % winning_team
	_correct_label.text = "%d acertos" % correct_count
	_errors_label.text = "%d erros" % error_count
	_ko_label.visible = true
	_ko_label.modulate.a = 0.0
	_ko_label.scale = Vector2(0.5, 0.5)
	_team_label.scale = Vector2(0.8, 0.8)
	_team_label.modulate.a = 0.0
	_stats_row.modulate.a = 0.0
	_message_label.modulate.a = 0.0

	var ko_entrance := create_tween().set_parallel(true)
	ko_entrance.tween_property(_ko_label, "modulate:a", 1.0, 0.3)
	ko_entrance.tween_property(_ko_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await ko_entrance.finished
	await get_tree().create_timer(KO_DISPLAY_TIME - 0.6).timeout
	var ko_fade := create_tween()
	ko_fade.tween_property(_ko_label, "modulate:a", 0.0, 0.25)
	await ko_fade.finished
	_ko_label.visible = false

	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(_team_label, "modulate:a", 1.0, 0.6)
	entrance.tween_property(_team_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(_stats_row, "modulate:a", 1.0, 0.5).set_delay(0.2)
	entrance.tween_property(_message_label, "modulate:a", 1.0, 0.8).set_delay(0.25)
	await entrance.finished
	var team_blink := create_tween().set_loops()
	team_blink.tween_property(_team_label, "modulate:a", 0.25, 0.4)
	team_blink.tween_property(_team_label, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(DISPLAY_TIME - ENTRANCE_TIME).timeout
	team_blink.kill()

	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(_overlay, "color", Color(0, 0, 0, 1), FADE_TIME)
	fade_out.tween_property(_team_label, "modulate:a", 0.0, FADE_TIME)
	fade_out.tween_property(_stats_row, "modulate:a", 0.0, FADE_TIME)
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
	_ko_label = Label.new()
	_ko_label.text = "K.O."
	_ko_label.position = Vector2(126, 230)
	_ko_label.size = Vector2(900, 150)
	_ko_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ko_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ko_label.add_theme_font_size_override("font_size", 112)
	_ko_label.add_theme_color_override("font_color", Color(1, 0.18, 0.12))
	_ko_label.visible = false
	add_child(_ko_label)

	_team_label = Label.new()
	_team_label.position = Vector2(126, 230)
	_team_label.size = Vector2(900, 90)
	_team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_team_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_team_label.add_theme_font_size_override("font_size", 38)
	_team_label.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	add_child(_team_label)

	_stats_row = HBoxContainer.new()
	_stats_row.position = Vector2(0, 330)
	_stats_row.size = Vector2(GameConfig.SCREEN_SIZE.x, 48)
	_stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_stats_row.add_theme_constant_override("separation", 0)
	var prefix := _create_stat_label("Venceu! com ", Color.WHITE)
	_correct_label = _create_stat_label("0 acertos", Color(0.2, 1.0, 0.3))
	var conjunction := _create_stat_label(" e ", Color.WHITE)
	_errors_label = _create_stat_label("0 erros", Color(1.0, 0.25, 0.25))
	_stats_row.add_child(prefix)
	_stats_row.add_child(_correct_label)
	_stats_row.add_child(conjunction)
	_stats_row.add_child(_errors_label)
	add_child(_stats_row)

	_message_label = Label.new()
	_message_label.text = "ÓTIMO JOGO!"
	_message_label.position = Vector2(126, 395)
	_message_label.size = Vector2(900, 70)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 36)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_message_label)


func _create_stat_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	return label
