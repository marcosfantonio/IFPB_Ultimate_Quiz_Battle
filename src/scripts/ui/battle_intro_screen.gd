class_name BattleIntroScreen
extends Control
## Apresentação dos jogadores antes de começar a partida.

signal player_name_revealed(player: int)
signal battle_reveal_started
signal finished

const DARKEN_ALPHA = 0.9
const SCREEN_FADE_IN_TIME = 1.0
const NAME_HOLD_TIME = 0.8
const VS_HOLD_TIME = 0.5
const PLAYER_BLOCK_HOLD_TIME = 2.2
const OPENING_DARK_TIME = 0.2
const OPENING_PHRASE_FADE_TIME = 0.8
const NAME_REVEAL_START_TIME = 4.5
const FIGHT_HOLD_TIME = 2.0
const REVEAL_TIME = 1.5

var _overlay: ColorRect
var _player_1_block: VBoxContainer
var _player_2_block: VBoxContainer
var _versus_label: Label
var _fight_label: Label
var _opening_phrase: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 900
	_build_overlay()
	_build_player_blocks()
	_build_versus()
	_build_fight()
	_build_opening_phrase()
	UITheme.apply_font(self)


func play(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String) -> void:
	visible = true
	modulate.a = 1.0
	_overlay.color = Color(0, 0, 0, 1.0)
	_set_player_block(_player_1_block, player_1_name, player_1_team)
	_set_player_block(_player_2_block, player_2_name, player_2_team)
	_player_1_block.visible = false
	_player_2_block.visible = false
	_versus_label.visible = false
	_fight_label.visible = false
	_fight_label.modulate.a = 1.0
	_opening_phrase.visible = false

	var screen_fade := create_tween()
	screen_fade.tween_property(_overlay, "color", Color(0, 0, 0, DARKEN_ALPHA), SCREEN_FADE_IN_TIME)
	await screen_fade.finished
	await get_tree().create_timer(OPENING_DARK_TIME).timeout
	_opening_phrase.visible = true
	_opening_phrase.modulate.a = 0.0
	var phrase_fade := create_tween()
	phrase_fade.tween_property(_opening_phrase, "modulate:a", 1.0, OPENING_PHRASE_FADE_TIME)
	await phrase_fade.finished
	var wait_for_names: float = NAME_REVEAL_START_TIME - SCREEN_FADE_IN_TIME - OPENING_DARK_TIME - OPENING_PHRASE_FADE_TIME
	if wait_for_names > 0.0:
		await get_tree().create_timer(wait_for_names).timeout
	_opening_phrase.visible = false
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
	var fight_blink := create_tween().set_loops()
	fight_blink.tween_property(_fight_label, "modulate:a", 0.2, 0.2)
	fight_blink.tween_property(_fight_label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(FIGHT_HOLD_TIME).timeout
	fight_blink.kill()
	_fight_label.modulate.a = 1.0

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


func _build_opening_phrase() -> void:
	_opening_phrase = Label.new()
	_opening_phrase.text = "E na luta de hoje..."
	_opening_phrase.position = Vector2(126, 270)
	_opening_phrase.size = Vector2(900, 80)
	_opening_phrase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opening_phrase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_opening_phrase.add_theme_font_size_override("font_size", 34)
	_opening_phrase.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	add_child(_opening_phrase)
