class_name Question
extends RefCounted
## Uma pergunta validada. Use Question.from_dict() para criar.

var text: String = ""
var options: Array[String] = []
var correct_index: int = 0
var difficulty: String = "medium"
var category: String = "Geral"


## Retorna null se o dicionário for inválido.
static func from_dict(data: Dictionary) -> Question:
	var raw_options: Variant = data.get("options", [])
	if not data.has("question") or not (raw_options is Array):
		return null
	if raw_options.size() < 2 or raw_options.size() > GameConfig.MAX_OPTIONS:
		return null
	var correct := int(data.get("correct", -1))
	if correct < 0 or correct >= raw_options.size():
		return null

	var question := Question.new()
	question.text = str(data["question"])
	for option in raw_options:
		question.options.append(str(option))
	question.correct_index = correct
	question.difficulty = str(data.get("difficulty", "medium"))
	question.category = str(data.get("category", "Geral"))
	return question


func is_correct(option_index: int) -> bool:
	return option_index == correct_index
