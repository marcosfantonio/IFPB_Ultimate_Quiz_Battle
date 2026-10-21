@tool
class_name BattleHud
extends Control
## Agrupa a interface de gameplay (jogadores, pergunta e medidores),
## para mostrar/esconder tudo de uma vez.

var question_panel: QuestionPanel
var professor: ProfessorIdle
var _player_panels: Dictionary = {}
var _charge_bars: Dictionary = {}
var _fatality_hints: Dictionary = {}
var _question_timer: Label
var _fatality_ready := {1: false, 2: false}
var _fatality_enabled := false
var _pulse_time := 0.0
var _answer_buttons: Array[Button] = []
var _answer_labels: Array[Label] = []
var _player_one_key_labels: Array[Label] = []
var _player_two_key_labels: Array[Label] = []
var _is_local_match := true
signal answer_selected(option_index: int)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_1 := $Player1 as PlayerPanel
	panel_1.setup(1)
	_player_panels[1] = panel_1
	var panel_2 := $Player2 as PlayerPanel
	panel_2.setup(2)
	_player_panels[2] = panel_2
	question_panel = $QuestionPanel as QuestionPanel
	professor = $ProfessorDamiao as ProfessorIdle
	_charge_bars = {1: $Player1ChargeBar as ProgressBar, 2: $Player2ChargeBar as ProgressBar}
	_fatality_hints = {1: $Player1FatalityHint as Label, 2: $Player2FatalityHint as Label}
	_question_timer = $QuestionTimer as Label
	for index in 3:
		var button := $Answers.get_child(index) as Button
		_answer_buttons.append(button)
		_answer_labels.append(button.get_node("AnswerLabel") as Label)
		_player_one_key_labels.append(button.get_node("PlayerOneKey") as Label)
		_player_two_key_labels.append(button.get_node("PlayerTwoKey") as Label)
		button.pressed.connect(answer_selected.emit.bind(index))
	UITheme.apply_font(self)
	for player in [1, 2]:
		_fatality_hints[player].visible = false
		_charge_bars[player].visible = false


func get_panel(player: int) -> PlayerPanel:
	return _player_panels[player]


func set_hp(player: int, value: float) -> void:
	get_panel(player).set_hp(value)


func set_alt_pose(alt_pose: bool) -> void:
	for panel in _player_panels.values():
		panel.set_alt_pose(alt_pose)


func set_charge(player: int, amount: float, fatality_enabled: bool) -> void:
	_fatality_enabled = fatality_enabled
	_charge_bars[player].visible = fatality_enabled
	_charge_bars[player].value = clampf(amount, 0.0, 100.0)
	_fatality_ready[player] = fatality_enabled and amount >= 100.0
	_fatality_hints[player].visible = _fatality_ready[player]
	_fatality_hints[player].text = "APERTE SHIFT" if player == 1 else "APERTE ESPAÇO"
	if not _fatality_ready[player]:
		_charge_bars[player].modulate = Color.WHITE
		_charge_bars[player].position.x = 85.0 if player == 1 else 872.0
		_fatality_hints[player].modulate = Color.WHITE


func set_question_timer(visible_timer: bool, seconds_remaining: float) -> void:
	_question_timer.visible = visible_timer
	if visible_timer:
		var seconds := maxi(ceili(seconds_remaining), 0)
		_question_timer.text = "%02d:%02d" % [seconds / 60, seconds % 60]


func show_answers(question: Question) -> void:
	for index in _answer_buttons.size():
		var button := _answer_buttons[index]
		var visible_option := index < question.options.size()
		button.visible = visible_option
		if visible_option:
			_answer_labels[index].text = question.options[index]
			_player_two_key_labels[index].visible = _is_local_match
			_fit_answer_font(_answer_labels[index])
			_set_answer_style(index, Color.WHITE, Color(0.7, 0.75, 0.82))
			call_deferred("_fit_answer_font", _answer_labels[index])


func _fit_answer_font(label: Label) -> void:
	const MAX_FONT_SIZE := 24
	const MIN_FONT_SIZE := 11
	var available_width := maxf(label.size.x, 260.0)
	var available_height := maxf(label.size.y, 76.0)
	for font_size in range(MAX_FONT_SIZE, MIN_FONT_SIZE - 1, -1):
		var estimated_line_width := font_size * 0.65
		var estimated_lines := ceili(label.text.length() * estimated_line_width / available_width)
		var estimated_height := estimated_lines * font_size * 1.25
		if estimated_height <= available_height:
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", MIN_FONT_SIZE)


func set_local_match(is_local: bool) -> void:
	_is_local_match = is_local
	var player_one_color := Color(0.9, 0.12, 0.12, 1) if is_local else Color(1.0, 0.72, 0.12, 1)
	for key_label in _player_one_key_labels:
		key_label.add_theme_color_override("font_color", player_one_color)
	for key_label in _player_two_key_labels:
		key_label.visible = is_local


func highlight_answer(correct_index: int, chosen_index: int, was_correct: bool) -> void:
	for index in _answer_buttons.size():
		if was_correct and index == correct_index:
			_set_answer_style(index, Color(0.55, 1.0, 0.62), Color(0.1, 0.65, 0.18))
		elif index == chosen_index:
			_set_answer_style(index, Color(1.0, 0.58, 0.58), Color(0.75, 0.12, 0.12))


func _set_answer_style(index: int, fill: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	_answer_buttons[index].add_theme_stylebox_override("normal", style)
	_answer_buttons[index].add_theme_stylebox_override("hover", style)
	_answer_buttons[index].add_theme_stylebox_override("pressed", style)


func _process(delta: float) -> void:
	if not visible:
		return
	_pulse_time += delta
	for player in [1, 2]:
		if not _fatality_ready[player]:
			continue
		var pulse := 0.35 + (sin(_pulse_time * 11.0) + 1.0) * 0.325
		_charge_bars[player].modulate = Color.WHITE.lerp(Color(1.0, 0.92, 0.35), pulse)
		_fatality_hints[player].modulate.a = 0.25 + (sin(_pulse_time * 9.0) + 1.0) * 0.375
		_charge_bars[player].position.x = (85.0 if player == 1 else 872.0) + sin(_pulse_time * 35.0) * 2.2


func set_intro_mode(active: bool) -> void:
	question_panel.visible = not active
	if active:
		_question_timer.visible = false
	for player in [1, 2]:
		_charge_bars[player].visible = _fatality_enabled and not active
		_fatality_hints[player].visible = _fatality_ready[player] and not active
	for panel in _player_panels.values():
		panel.set_intro_mode(active)
