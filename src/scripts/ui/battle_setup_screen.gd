class_name BattleSetupScreen
extends Control
## Cadastro dos representantes e equipes antes do início da batalha.

signal start_requested(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String)
signal back_requested

const CARD_SIZE = Vector2(440, 250)
const FIELD_SIZE = Vector2(360, 46)

var _representative_edits: Array[LineEdit] = []
var _team_edits: Array[LineEdit] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600
	_build_overlay()
	_build_cards()
	_build_start_button()
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()


func focus_first_field() -> void:
	if not _representative_edits.is_empty():
		_representative_edits[0].grab_focus()


func _build_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.size = GameConfig.SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.78)
	add_child(overlay)


func _build_cards() -> void:
	var cards := HBoxContainer.new()
	cards.position = Vector2((GameConfig.SCREEN_SIZE.x - CARD_SIZE.x * 2.0 - 36.0) * 0.5, 178)
	cards.size = Vector2(CARD_SIZE.x * 2.0 + 36.0, CARD_SIZE.y)
	cards.add_theme_constant_override("separation", 36)
	add_child(cards)

	for player_id in GameConfig.PLAYERS:
		var config: Dictionary = GameConfig.PLAYERS[player_id]
		var card := PanelContainer.new()
		card.custom_minimum_size = CARD_SIZE
		card.size = CARD_SIZE
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.035, 0.055, 0.08, 0.97)
		card_style.set_border_width_all(3)
		card_style.border_color = config["color"]
		card_style.set_content_margin_all(24.0)
		card.add_theme_stylebox_override("panel", card_style)

		var fields := VBoxContainer.new()
		fields.alignment = BoxContainer.ALIGNMENT_CENTER
		fields.add_theme_constant_override("separation", 14)
		var title := Label.new()
		title.text = config["name"]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", config["color"])
		fields.add_child(title)

		var representative := _create_field("NOME DO REPRESENTANTE")
		var team := _create_field("NOME DA EQUIPE")
		_representative_edits.append(representative)
		_team_edits.append(team)
		fields.add_child(representative)
		fields.add_child(team)
		card.add_child(fields)
		cards.add_child(card)


func _create_field(placeholder: String) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.custom_minimum_size = FIELD_SIZE
	field.add_theme_color_override("font_color", Color.WHITE)
	field.add_theme_color_override("font_placeholder_color", Color(0.72, 0.75, 0.8))
	field.add_theme_color_override("caret_color", Color(1, 0.82, 0.1))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.11, 0.15)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.32, 0.38, 0.44)
	normal.set_content_margin_all(10.0)
	var focused := StyleBoxFlat.new()
	focused.bg_color = Color(0.08, 0.11, 0.15)
	focused.set_border_width_all(2)
	focused.border_color = Color(1, 0.82, 0.1)
	focused.set_content_margin_all(10.0)
	field.add_theme_stylebox_override("normal", normal)
	field.add_theme_stylebox_override("focus", focused)
	return field


func _build_start_button() -> void:
	var button := Button.new()
	button.text = "INICIAR BATALHA"
	button.position = Vector2((GameConfig.SCREEN_SIZE.x - 320.0) * 0.5, 490)
	button.custom_minimum_size = Vector2(320, 58)
	button.size = Vector2(320, 58)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.55, 0.22)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.35, 1.0, 0.45)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.72, 0.3)
	hover.set_border_width_all(3)
	hover.border_color = Color(0.65, 1.0, 0.65)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)
	button.pressed.connect(_on_start_pressed)
	add_child(button)


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
