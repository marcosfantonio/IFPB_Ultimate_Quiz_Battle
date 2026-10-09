class_name BattleHud
extends Control
## Agrupa a interface de gameplay (jogadores, pergunta e dicas de teclas),
## para mostrar/esconder tudo de uma vez.

var question_panel: QuestionPanel

var _player_panels: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for id in GameConfig.PLAYERS:
		var panel := PlayerPanel.new()
		panel.setup(id)
		add_child(panel)
		_player_panels[id] = panel

	question_panel = QuestionPanel.new()
	add_child(question_panel)

	var hint := ControlsHint.create()
	add_child(hint)
	UITheme.apply_font(hint)


func get_panel(player: int) -> PlayerPanel:
	return _player_panels[player]


func set_hp(player: int, value: float) -> void:
	get_panel(player).set_hp(value)


func set_alt_pose(alt_pose: bool) -> void:
	for panel in _player_panels.values():
		panel.set_alt_pose(alt_pose)
