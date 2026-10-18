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

var _question_plate: LabelPlate
var _difficulty_plate: LabelPlate
var _category_plate: LabelPlate
var _option_plates: Array[LabelPlate] = []
var _options_grid: GridContainer
var _tags: HBoxContainer


func _ready() -> void:
	position = Vector2(0, 23)
	size = GameConfig.SCREEN_SIZE
	add_theme_constant_override("separation", 8)

	_build_question_plate()
	_build_tags()
	_build_options()
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
			plate.set_text("[%s/%s] %s" % [
				GameConfig.key_label(1, i),
				GameConfig.key_label(2, i),
				question.options[i],
			])
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


func _build_question_plate() -> void:
	_question_plate = LabelPlate.create(Vector2(PANEL_WIDTH, QUESTION_HEIGHT), QUESTION_FONT_SIZE, Color.WHITE, Vector2(PANEL_WIDTH, QUESTION_HEIGHT))
	_question_plate.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_plate.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_question_plate)


func _build_tags() -> void:
	_tags = HBoxContainer.new()
	_tags.alignment = BoxContainer.ALIGNMENT_CENTER
	_tags.add_theme_constant_override("separation", 20)

	_difficulty_plate = LabelPlate.create(Vector2(120, TAG_HEIGHT), 16)
	_category_plate = LabelPlate.create(Vector2(120, TAG_HEIGHT), 16)
	_tags.add_child(_difficulty_plate)
	_tags.add_child(_category_plate)
	add_child(_tags)


func _build_options() -> void:
	_options_grid = GridContainer.new()
	_options_grid.columns = 1
	_options_grid.add_theme_constant_override("h_separation", GRID_GAP)
	_options_grid.add_theme_constant_override("v_separation", GRID_GAP)
	for _i in GameConfig.OPTIONS_PER_QUESTION:
		var plate_width := OPTION_WIDTH - OPTION_SIDE_MARGIN * 2.0
		var plate := LabelPlate.create(Vector2(plate_width, OPTION_HEIGHT), OPTION_FONT_SIZE, Color(0.85, 0.85, 0.85), Vector2.ZERO, int(OPTION_SIDE_MARGIN))
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		plate.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		plate.label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_option_plates.append(plate)
		_options_grid.add_child(plate)
	add_child(_options_grid)


func _resize_option_plate(plate: LabelPlate) -> void:
	var plate_size := Vector2(OPTION_WIDTH - OPTION_SIDE_MARGIN * 2.0, OPTION_HEIGHT)
	plate.custom_minimum_size = plate_size
	plate.background.custom_minimum_size = plate_size


func _center_horizontally() -> void:
	# Ocupa a largura da tela; cada grupo usa seu tamanho mínimo e fica centralizado.
	size.x = GameConfig.SCREEN_SIZE.x
	_question_plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tags.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_options_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
