class_name RoundController
extends Node
## Regras de uma rodada de pergunta: sorteio, trava de input, quem já errou
## e quando passar para a próxima pergunta. Não conhece UI nem áudio.
##
## Fluxo:
##   start_round() -> question_started
##   submit_answer() -> answer_resolved
##     - acertou: a rodada termina (quem escuta lança o projétil)
##     - errou: espera WRONG_ANSWER_DELAY e então
##         * os dois erraram -> nova rodada automática
##         * senão           -> retry_unlocked (o outro jogador tenta)

signal question_started(question: Question)
signal answer_resolved(player: int, option_index: int, correct: bool)
signal retry_unlocked

var current_question: Question

var _repository: QuestionRepository
var _failed_players: Array[int] = []
var _active: bool = false
var _locked: bool = false
var _round_id: int = 0  # invalida awaits de rodadas antigas


func setup(repository: QuestionRepository) -> void:
	_repository = repository


func start_round() -> void:
	_round_id += 1
	current_question = _repository.next_question()
	_failed_players.clear()
	_active = true
	_locked = false
	question_started.emit(current_question)


func stop() -> void:
	_active = false
	_round_id += 1


func submit_answer(player: int, option_index: int) -> void:
	if not _active or _locked or _failed_players.has(player):
		return
	if option_index >= current_question.options.size():
		return

	_locked = true

	if current_question.is_correct(option_index):
		_active = false
		answer_resolved.emit(player, option_index, true)
		return

	_failed_players.append(player)
	answer_resolved.emit(player, option_index, false)

	var round_id := _round_id
	await get_tree().create_timer(GameConfig.WRONG_ANSWER_DELAY).timeout
	if round_id != _round_id or not _active:
		return

	if _failed_players.size() >= GameConfig.PLAYERS.size():
		start_round()
	else:
		_locked = false
		retry_unlocked.emit()
