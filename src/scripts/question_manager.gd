# QuestionManager - Gerencia pool de questões e estado da rodada
# Extende Node para ser child do battle principal (isolamento espacial)

class_name GameManager
extends Node2D

enum QuestionState { LOADING, ACTIVE, ANSWERING, LOCKED }

## ==================== CONFIGURAÇÃO EXTERNA ==================== ##

# Tempo de espera entre questões (segundos) - ajusta no Godot Editor!
@export_group("⏱️ Timing")
const WAIT_BETWEEN_QUESTIONS: float = 1.0

# Duração para desbloquear após erro (segundos)
@export_group("🔒 Unlock")
const ERROR_UNLOCK_TIME: float = 2.5

## ==================== ESTADO DO JOGO ==================== ##

var state: QuestionState = QuestionState.LOADING
var current_question: Dictionary = {}
var questions_pool: Array = []
var used_indices: Array = []

## Setup inicial (chamar no _ready) ou criar via Godot Editor
func setup(wait_time: float, unlock_time: float):
	WAIT_BETWEEN_QUESTIONS = wait_time
	ERROR_UNLOCK_TIME = unlock_time

# ==================== OPERAÇÕES DE PERGUNTA ==================== #

func load_questions_from_json(file_path: String) -> void:
	"""
    Carrega questões de arquivo JSON.
    
    Arquivo esperado:
        {"questions": [
            {
                "question": "String da pergunta",
                "options": ["Opção A", "Opção B", ...],
                "correct": 0,         # Índice zero-based
                "difficulty": "easy|medium|hard",
                "category": "Matemática"
            }
        ]}
    
    Retorna: true se carregou com sucesso.
    """
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		# Parsear JSON manualmente para maior segurança e compatibilidade
		var result = parse_question_json(json_text)
		if result.status == OK and result.data.has("questions") and result.data["questions"].is_array():
			questions_pool = result.data["questions"]
		else:
			printerr("QuestionManager: JSON inválido ou sem 'questions'")

	if questions_pool.is_empty():
		printwarn("QuestionManager: Nenhum dado carregado - usando fallback")
		_ensure_fallback_questions()

func _ensure_fallback_questions() -> void:
    """Carrega perguntas de fallback caso o JSON esteja vazio."""
	var fallback = [
		# Perguntas ENEM reais (2017-2023)
		{
			"question": "A respeito do poema 'O Leão', que trata da morte e da eternidade, \\na qual é interpretado como uma espécie de 'poema de consolação' para quem vive com medo da morte:",
			"options": ["...não há mais um único homem na Terra.", "...a vida termina apenas quando o sol se põe.", "...há algo que a própria morte não pode destruir.", "...só importa o amor e nada mais.", "...todos somos iguais perante à lei."],
			"correct": 2,
			"difficulty": "medium",
			"category": "Português"
		},
		{
			"question": "No poema 'A Riqueza', do poeta argentino Jorge Luis Borges, o narrador afirma:",
			"options": ["...a riqueza é posse material de bens.", "...o ouro e a prata são vaidades humanas.", "...não há mais um único homem na Terra.", "...a vida termina apenas quando o sol se põe.", "...há algo que a própria morte não pode destruir."],
			"correct": 1,
			"difficulty": "medium",
			"category": "Português"
		},
		{
			"question": "Sobre 'O Mágico', de Guimarães Rosa, analise o fragmento:",
			"options": ["...a riqueza é posse material de bens.", "...o ouro e a prata são vaidades humanas.", "...não há mais um único homem na Terra.", "...a vida termina apenas quando o sol se põe.", "...há algo que a própria morte não pode destruir."],
			"correct": 1,
			"difficulty": "hard",
			"category": "Português"
		},
		# Matemática/Computação
		{
			"question": "Em análise de algoritmos, o tempo worst-case de Merge Sort é:",
			"options": ["O(n)", "O(n log n)", "O(n²)", "O(log n)", "O(1)"],
			"correct": 1,
			"difficulty": "medium",
			"category": "Matemática"
		},
		{
			"question": "Dada a equação diferencial dy/dx = y, com condição inicial y(0) = 1:",
			"options": ["y(x) = x + 1", "y(x) = e^x", "y(x) = x²", "y(x) = ln(x)", "y(x) = sin(x)"],
			"correct": 1,
			"difficulty": "medium",
			"category": "Física"
		},
	]

	for item in fallback:
		if questions_pool.size() < 50: # Limitar tamanho para performance
			questions_pool.append(item)

# ==================== GET PRÓXIMA PERGUNTA ==================== #

func get_next_question() -> Dictionary:
    """
    Retorna a próxima pergunta não utilizada.
    
    Garante que TODAS as perguntas sejam utilizadas pelo menos uma vez,
    mesmo se alguns jogadores errarem antes do fim do pool.
    
    Retorna: Dicionário da questão + índice utilizado.
    """
	# Se acabou o pool, resetar - garante jogo infinito sem repetição
	if questions_pool.is_empty():
		print("QuestionManager: Pool esgotado - reiniciando questões")
		used_indices.clear()
		_ensure_fallback_questions() # Garante sempre tem dados mínimos

	# Filtrar índices disponíveis (não usados ainda)
	var available: Array = []
	for i in range(questions_pool.size()):
		if not used_indices.has(i):
			available.append(i)

	if available.is_empty():
		print("QuestionManager: Nenhuma questão disponível - resetando tudo")
		used_indices.clear()
		for i in range(questions_pool.size()):
			available.append(i)

	# Escolher aleatoriamente entre disponíveis
	var idx = available.pick_random()
	used_indices.append(idx)
	return questions_pool[idx]

# ==================== RESET DE RODADA ==================== #

func reset_round() -> void:
    """
    Reseta o estado da rodada atual (apenas se necessário).
    """
	failed_players.clear()
	_ensure_fallback_questions() # Garante sempre tem dados mínimos
