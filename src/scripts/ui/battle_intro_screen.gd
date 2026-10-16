class_name BattleIntroScreen
extends Control
## Apresentação dos jogadores antes de começar a partida.

signal player_name_revealed(player: int)
signal battle_reveal_started
signal finished

const DARKEN_ALPHA = 0.9
const INTRO_SILENCE_TIME = 4.5
const NAME_HOLD_TIME = 0.8
const VS_HOLD_TIME = 0.5
const PLAYER_BLOCK_HOLD_TIME = 2.2
const FIGHT_HOLD_TIME = 2.0
const REVEAL_TIME = 1.5

var _overlay: ColorRect
var _player_1_block: VBoxContainer
var _player_2_block: VBoxContainer
var _versus_label: Label
var _fight_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 900
	_build_overlay()
	_build_player_blocks()
	_build_versus()
	_build_fight()
	UITheme.apply_font(self)


func play(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String) -> void:
	visible = true
	modulate.a = 1.0
	_overlay.color = Color(0, 0, 0, DARKEN_ALPHA)
	_set_player_block(_player_1_block, player_1_name, player_1_team)
	_set_player_block(_player_2_block, player_2_name, player_2_team)
	_player_1_block.visible = false
	_player_2_block.visible = false
	_versus_label.visible = false
	_fight_label.visible = false

	await get_tree().create_timer(INTRO_SILENCE_TIME).timeout
	_player_1_block.visible = true
	player_name_revealed.emit(1)
	await get_tree().create_timer(NAME_HOLD_TIME).timeout
	_versus_label.visible = true
	await get_tree().create_timer(VS_HOLD_TIME).timeout
	_player_2_block.visible = true
	player_name_revealed.emit(2)
	await get_tree().create_timer(PLAYER_BLOCK_HOLD_TIME).timeout
	_player_1_block.visible = false
	_player_2_block.visible = false
	_versus_label.visible = false
	_fight_label.visible = true
	await get_tree().create_timer(FIGHT_HOLD_TIME).timeout

	battle_reveal_started.emit()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, REVEAL_TIME)
	await fade.finished
	visible = false
	finished.emit()


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.size = GameConfig.SCREEN_SIZE
	_overlay.color = Color(0, 0, 0, DARKEN_ALPHA)
	add_child(_overlay)


func _build_player_blocks() -> void:
	_player_1_block = _create_player_block(Vector2(40, 260), 1)
	_player_2_block = _create_player_block(Vector2(712, 260), 2)
	add_child(_player_1_block)
	add_child(_player_2_block)


func _create_player_block(at: Vector2, player: int) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.position = at
	block.size = Vector2(400, 120)
	block.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.name = "Representative"
	name_label.custom_minimum_size = Vector2(400, 54)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", GameConfig.PLAYERS[player]["color"])
	block.add_child(name_label)
	var team_label := Label.new()
	team_label.name = "Team"
	team_label.custom_minimum_size = Vector2(400, 38)
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	team_label.add_theme_font_size_override("font_size", 23)
	team_label.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	block.add_child(team_label)
	return block


func _set_player_block(block: VBoxContainer, representative: String, team: String) -> void:
	var name_label := block.get_node("Representative") as Label
	var team_label := block.get_node("Team") as Label
	name_label.text = representative
	team_label.text = team


func _build_versus() -> void:
	_versus_label = Label.new()
	_versus_label.text = "VS"
	_versus_label.position = Vector2(476, 285)
	_versus_label.size = Vector2(200, 80)
	_versus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_versus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_versus_label.add_theme_font_size_override("font_size", 58)
	_versus_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_versus_label)


func _build_fight() -> void:
	_fight_label = Label.new()
	_fight_label.text = "FIGHT!"
	_fight_label.position = Vector2(276, 260)
	_fight_label.size = Vector2(600, 100)
	_fight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fight_label.add_theme_font_size_override("font_size", 64)
	_fight_label.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	add_child(_fight_label)
