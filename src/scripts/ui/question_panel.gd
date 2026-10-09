class_name QuestionPanel
extends VBoxContainer
## Área central superior: enunciado, tags de dificuldade/categoria e alternativas.

const OPTION_NORMAL = Color(1, 1, 1, 1)
const OPTION_CORRECT = Color(0.2, 1, 0.3, 1)
const OPTION_WRONG = Color(1, 0.2, 0.2, 1)

var _question_plate: LabelPlate
var _difficulty_plate: LabelPlate
var _category_plate: LabelPlate
var _option_plates: Array[LabelPlate] = []


func _ready() -> void:
	position = Vector2(276, 30)
	size = Vector2(600, 300)
	add_theme_constant_override("separation", 12)

	_build_question_plate()
	_build_tags()
	_build_options()
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
	_question_plate = LabelPlate.create(Vector2(600, 60), 24, Color.WHITE, Vector2(600, 50))
	_question_plate.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_question_plate)


func _build_tags() -> void:
	var tags := HBoxContainer.new()
	tags.alignment = BoxContainer.ALIGNMENT_CENTER
	tags.add_theme_constant_override("separation", 20)

	_difficulty_plate = LabelPlate.create(Vector2(120, 28), 16)
	_category_plate = LabelPlate.create(Vector2(120, 28), 16)
	tags.add_child(_difficulty_plate)
	tags.add_child(_category_plate)
	add_child(tags)


func _build_options() -> void:
	for _i in GameConfig.MAX_OPTIONS:
		var plate := LabelPlate.create(Vector2(440, 30), 20, Color(0.85, 0.85, 0.85), Vector2(440, 30), 80)
		_option_plates.append(plate)
		add_child(plate)
