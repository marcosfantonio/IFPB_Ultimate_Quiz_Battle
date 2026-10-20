@tool
class_name QuestionPanel
extends VBoxContainer
## Área central superior: enunciado, tags de dificuldade/categoria e alternativas.

const OPTION_NORMAL = Color(1, 1, 1, 1)
const OPTION_CORRECT = Color(0.2, 1, 0.3, 1)
const OPTION_WRONG = Color(1, 0.2, 0.2, 1)
const PANEL_WIDTH = 600.0
const OPTION_WIDTH = 520.0
const QUESTION_HEIGHT = 96.0
const TAG_HEIGHT = 28.0
const OPTION_HEIGHT = 54.0
const QUESTION_FONT_SIZE = 22
const OPTION_FONT_SIZE = 17
const GRID_GAP = 8
const OPTION_SIDE_MARGIN = 12.0
const PLAYER_ONE_COLOR = Color(1.0, 0.2, 0.2, 1.0)
const PLAYER_TWO_COLOR = Color(0.25, 0.55, 1.0, 1.0)
const PLAYER_ONE_KEYS = ["1", "2", "3"]
const PLAYER_TWO_KEYS = ["Z", "X", "C"]

var _question_plate: LabelPlate
var _difficulty_plate: LabelPlate
var _category_plate: LabelPlate
var _option_plates: Array[LabelPlate] = []
var _options_grid: GridContainer
var _tags: HBoxContainer


func _ready() -> void:
	position = Vector2(0, 23)
	size = Vector2(GameConfig.SCREEN_SIZE.x, GameConfig.SCREEN_SIZE.y - position.y)
	add_theme_constant_override("separation", 8)
	_question_plate = $QuestionPlate as LabelPlate
	_tags = $Tags as HBoxContainer
	_difficulty_plate = $Tags/DifficultyPlate as LabelPlate
	_category_plate = $Tags/CategoryPlate as LabelPlate
	_options_grid = $OptionsGrid as GridContainer
	for option_node in _options_grid.get_children():
		var plate := option_node as LabelPlate
		plate.add_theme_constant_override("margin_left", int(OPTION_SIDE_MARGIN))
		plate.add_theme_constant_override("margin_right", int(OPTION_SIDE_MARGIN))
		plate.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		plate.label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plate.label.add_theme_font_size_override("font_size", OPTION_FONT_SIZE)
		_add_option_key_hints(plate, _option_plates.size())
		plate.custom_minimum_size = Vector2(OPTION_WIDTH - OPTION_SIDE_MARGIN * 2.0, OPTION_HEIGHT)
		plate.background.custom_minimum_size = plate.custom_minimum_size
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_option_plates.append(plate)
	_question_plate.custom_minimum_size = Vector2(PANEL_WIDTH, QUESTION_HEIGHT)
	_question_plate.background.custom_minimum_size = _question_plate.custom_minimum_size
	_question_plate.label.custom_minimum_size = _question_plate.custom_minimum_size
	_question_plate.label.add_theme_font_size_override("font_size", QUESTION_FONT_SIZE)
	_question_plate.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_plate.label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_difficulty_plate.label.add_theme_font_size_override("font_size", 16)
	_category_plate.label.add_theme_font_size_override("font_size", 16)
	_center_horizontally()
	UITheme.apply_font(self)


func show_question(question: Question) -> void:
	_question_plate.set_text(question.text)

	var difficulty := QuestionStyle.difficulty(question.difficulty)
	_difficulty_plate.set_text(difficulty["text"])
	_difficulty_plate.set_text_color(difficulty["color"])

	var category := QuestionStyle.category(question.category)
	_category_plate.set_text(category["text"])
	_category_plate.set_text_color(category["color"])

	for i in _option_plates.size():
		var plate := _option_plates[i]
		if i < question.options.size():
			plate.set_text(question.options[i])
			plate.visible = true
		else:
			plate.visible = false
			continue
		_resize_option_plate(plate)
	_center_horizontally()
	reset_highlights()


## Pinta a alternativa correta de verde e, se for diferente, a escolhida de vermelho.
func highlight_answer(correct_index: int, chosen_index: int) -> void:
	for i in _option_plates.size():
		if i == correct_index:
			_option_plates[i].label.modulate = OPTION_CORRECT
		elif i == chosen_index:
			_option_plates[i].label.modulate = OPTION_WRONG


func reset_highlights() -> void:
	for plate in _option_plates:
		plate.label.modulate = OPTION_NORMAL


func _resize_option_plate(plate: LabelPlate) -> void:
	var plate_size := Vector2(OPTION_WIDTH - OPTION_SIDE_MARGIN * 2.0, OPTION_HEIGHT)
	plate.custom_minimum_size = plate_size
	plate.background.custom_minimum_size = plate_size


func _add_option_key_hints(plate: LabelPlate, index: int) -> void:
	var left_hint := Label.new()
	left_hint.name = "PlayerOneKey"
	left_hint.text = PLAYER_ONE_KEYS[index]
	left_hint.add_theme_color_override("font_color", PLAYER_ONE_COLOR)
	left_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_hint.offset_left = 8
	left_hint.offset_right = 34
	left_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.background.add_child(left_hint)

	var right_hint := Label.new()
	right_hint.name = "PlayerTwoKey"
	right_hint.text = PLAYER_TWO_KEYS[index]
	right_hint.add_theme_color_override("font_color", PLAYER_TWO_COLOR)
	right_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_hint.offset_left = -34
	right_hint.offset_right = -8
	right_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.background.add_child(right_hint)


func _center_horizontally() -> void:
	# Ocupa a largura da tela; cada grupo usa seu tamanho mínimo e fica centralizado.
	size.x = GameConfig.SCREEN_SIZE.x
	_question_plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tags.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_options_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
