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
	_overlay = $Overlay as ColorRect
	_ko_label = $KOLabel as Label
	_team_label = $TeamLabel as Label
	_stats_row = $StatsRow as HBoxContainer
	_correct_label = $StatsRow/CorrectLabel as Label
	_errors_label = $StatsRow/ErrorsLabel as Label
	_message_label = $MessageLabel as Label
	UITheme.apply_font(self)


func play(winning_team: String, correct_count: int, error_count: int) -> void:
	visible = true
	_overlay.color = Color(0, 0, 0, 0.88)
	_ko_label.visible = true
	_team_label.visible = true
	_stats_row.visible = true
	_message_label.visible = true
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
