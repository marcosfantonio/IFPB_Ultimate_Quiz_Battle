@tool
class_name BattleHud
extends Control
## Agrupa a interface de gameplay (jogadores, pergunta e dicas de teclas),
## para mostrar/esconder tudo de uma vez.

var question_panel: QuestionPanel
var _controls_hint: Control

var _player_panels: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_1 := $Player1 as PlayerPanel
	panel_1.setup(1)
	_player_panels[1] = panel_1
	var panel_2 := $Player2 as PlayerPanel
	panel_2.setup(2)
	_player_panels[2] = panel_2
	question_panel = $QuestionPanel as QuestionPanel
	_controls_hint = $ControlsHint as LabelPlate
	ControlsHint.configure(_controls_hint as LabelPlate)
	UITheme.apply_font(_controls_hint)


func get_panel(player: int) -> PlayerPanel:
	return _player_panels[player]


func set_hp(player: int, value: float) -> void:
	get_panel(player).set_hp(value)


func set_alt_pose(alt_pose: bool) -> void:
	for panel in _player_panels.values():
		panel.set_alt_pose(alt_pose)


func set_intro_mode(active: bool) -> void:
	question_panel.visible = not active
	_controls_hint.visible = not active
	for panel in _player_panels.values():
		panel.set_intro_mode(active)
