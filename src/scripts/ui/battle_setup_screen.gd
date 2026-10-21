class_name BattleSetupScreen
extends Control
## Cadastro dos representantes e equipes antes do início da batalha.

signal start_requested(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String)
signal back_requested

var _representative_edits: Array[LineEdit] = []
var _team_edits: Array[LineEdit] = []
var _navigation_controls: Array[Control] = []
var _navigation_index := 0


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
	$BackButton.pressed.connect(func() -> void: back_requested.emit())
	UITheme.apply_font(self)
	_navigation_controls = [
		_representative_edits[0], _team_edits[0],
		_representative_edits[1], _team_edits[1],
		$StartButton as Button, $BackButton as Button,
	]


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			return
		var direction := -1 if event.keycode in [KEY_UP, KEY_LEFT] else 1
		var current_index := _navigation_controls.find(focused)
		_navigation_index = posmod((current_index if current_index >= 0 else _navigation_index) + direction, _navigation_controls.size())
		_navigation_controls[_navigation_index].grab_focus()
		get_viewport().set_input_as_handled()


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
