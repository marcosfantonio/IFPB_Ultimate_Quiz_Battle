class_name QuestionRepository
extends RefCounted
## Carrega o banco de perguntas e sorteia sem repetir até esgotar o pool.

const FALLBACK_QUESTIONS = [
	{"question": "Capital do Brasil?", "options": ["São Paulo", "Rio", "Brasília", "Salvador", "Recife"], "correct": 2, "difficulty": "easy"},
	{"question": "7 × 8 = ?", "options": ["54", "56", "58", "64", "72"], "correct": 1, "difficulty": "easy"},
	{"question": "Estrutura FIFO?", "options": ["Stack", "Queue", "Tree", "Graph", "Heap"], "correct": 1, "difficulty": "medium"},
	{"question": "2^10 = ?", "options": ["512", "1024", "2048", "4096", "256"], "correct": 1, "difficulty": "medium"},
	{"question": "Merge Sort worst case?", "options": ["O(n)", "O(n log n)", "O(n²)", "O(log n)", "O(1)"], "correct": 1, "difficulty": "hard"},
]

var _questions: Array[Question] = []
var _used_indices: Array[int] = []


func load_from_file(path: String) -> void:
	_questions.clear()
	_used_indices.clear()

	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			_append_from(JSON.parse_string(file.get_as_text()))

	if _questions.is_empty():
		push_warning("QuestionRepository: nenhuma pergunta válida em '%s'. Usando fallback." % path)
		_append_from({"questions": FALLBACK_QUESTIONS})


func size() -> int:
	return _questions.size()


func reset_history() -> void:
	_used_indices.clear()


func next_question() -> Question:
	var available: Array[int] = []
	for i in _questions.size():
		if not _used_indices.has(i):
			available.append(i)
	if available.is_empty():
		_used_indices.clear()
		for i in _questions.size():
			available.append(i)

	var index: int = available.pick_random()
	_used_indices.append(index)
	return _questions[index]


func _append_from(data: Variant) -> void:
	if not (data is Dictionary) or not (data.get("questions") is Array):
		return
	var entries: Array = data["questions"]
	for i in entries.size():
		var question: Question = null
		if entries[i] is Dictionary:
			question = Question.from_dict(entries[i])
		if question:
			_questions.append(question)
		else:
			push_warning("QuestionRepository: pergunta #%d inválida, ignorada." % i)
