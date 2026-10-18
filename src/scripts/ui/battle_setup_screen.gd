class_name BattleSetupScreen
extends Control
## Cadastro dos representantes e equipes antes do início da batalha.

signal start_requested(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String)
signal back_requested

var _representative_edits: Array[LineEdit] = []
var _team_edits: Array[LineEdit] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600
	_representative_edits = [
		$Cards/Player1Card/Fields/RepresentativeEdit as LineEdit,
		$Cards/Player2Card/Fields/RepresentativeEdit as LineEdit,
	]
	_team_edits = [
		$Cards/Player1Card/Fields/TeamEdit as LineEdit,
		$Cards/Player2Card/Fields/TeamEdit as LineEdit,
	]
	$StartButton.pressed.connect(_on_start_pressed)
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()


func focus_first_field() -> void:
	if not _representative_edits.is_empty():
		_representative_edits[0].grab_focus()


func _on_start_pressed() -> void:
	var player_1_name := _representative_edits[0].text.strip_edges()
	var player_1_team := _team_edits[0].text.strip_edges()
	var player_2_name := _representative_edits[1].text.strip_edges()
	var player_2_team := _team_edits[1].text.strip_edges()
	if player_1_name.is_empty():
		player_1_name = "PLAYER 1"
	if player_1_team.is_empty():
		player_1_team = "EQUIPE 1"
	if player_2_name.is_empty():
		player_2_name = "PLAYER 2"
	if player_2_team.is_empty():
		player_2_team = "EQUIPE 2"
	start_requested.emit(player_1_name, player_1_team, player_2_name, player_2_team)
