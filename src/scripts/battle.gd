extends Node2D
## Orquestrador da partida. Só cria os módulos, liga os sinais entre eles
## e decide a fase do jogo. A lógica de cada parte vive no seu módulo:
##   core/     config, assets, estado da partida
##   data/     perguntas
##   systems/  áudio, input, rodada, projétil, animação idle
##   ui/       componentes visuais

var _phase: GamePhase.State = GamePhase.State.START_SCREEN

var _match := MatchState.new()
var _repository := QuestionRepository.new()

var _audio: AudioManager
var _round: RoundController
var _projectile: Projectile
var _hud: BattleHud
var _game_over_panel: GameOverPanel
var _start_screen: StartScreen


func _ready() -> void:
	z_index = 10
	_repository.load_from_file(GameConfig.QUESTIONS_PATH)

	_create_systems()
	_create_ui()
	_connect_signals()

	_audio.play_bgm()


# ==================== SETUP ====================

func _create_systems() -> void:
	_audio = AudioManager.new()
	add_child(_audio)

	_round = RoundController.new()
	_round.setup(_repository)
	add_child(_round)

	var input_router := InputRouter.new()
	input_router.start_requested.connect(_on_start_requested)
	input_router.answer_requested.connect(_on_answer_requested)
	add_child(input_router)

	var idle_animator := IdleAnimator.new()
	idle_animator.pose_changed.connect(_on_pose_changed)
	add_child(idle_animator)

	# Primeiro filho: desenha atrás da UI, como no jogo original.
	_projectile = Projectile.new()
	add_child(_projectile)
	move_child(_projectile, 0)


func _create_ui() -> void:
	_hud = BattleHud.new()
	_hud.visible = false  # só aparece depois do Enter
	add_child(_hud)

	_game_over_panel = GameOverPanel.new()
	add_child(_game_over_panel)

	_start_screen = StartScreen.new()
	add_child(_start_screen)


func _connect_signals() -> void:
	_match.hp_changed.connect(_hud.set_hp)

	_round.question_started.connect(_on_question_started)
	_round.answer_resolved.connect(_on_answer_resolved)
	_round.retry_unlocked.connect(_hud.question_panel.reset_highlights)

	_projectile.hit.connect(_on_projectile_hit)
	_game_over_panel.restart_requested.connect(_on_restart_requested)
	_start_screen.options_pressed.connect(_on_options_pressed)


# ==================== INPUT / MENU ====================

func _on_start_requested() -> void:
	if _phase != GamePhase.State.START_SCREEN:
		return
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.queue_free()
	_start_screen = null
	_hud.visible = true
	_phase = GamePhase.State.WAITING
	_round.start_round()


func _on_options_pressed() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	print("Opções clicadas!")


func _on_answer_requested(player: int, option_index: int) -> void:
	if _phase == GamePhase.State.QUESTION:
		_round.submit_answer(player, option_index)


func _on_pose_changed(alt_pose: bool) -> void:
	_hud.set_alt_pose(alt_pose)


# ==================== RODADA ====================

func _on_question_started(question: Question) -> void:
	_phase = GamePhase.State.QUESTION
	_audio.play_sfx(GameAssets.Sfx.NEW_QUESTION)
	_hud.question_panel.show_question(question)


func _on_answer_resolved(player: int, option_index: int, correct: bool) -> void:
	_hud.question_panel.highlight_answer(_round.current_question.correct_index, option_index)
	var origin := _hud.get_panel(player).get_floating_text_origin()

	if correct:
		_audio.play_sfx(GameAssets.Sfx.CORRECT)
		FloatingText.spawn(self, origin, "ACERTOU!", Color(0.2, 1, 0.3))
		_launch_projectile(player)
	else:
		_audio.play_sfx(GameAssets.Sfx.WRONG)
		FloatingText.spawn(self, origin, "ERROU!", Color(1, 0.2, 0.2))


# ==================== COMBATE ====================

func _launch_projectile(attacker: int) -> void:
	_phase = GamePhase.State.PROJECTILE
	var attacker_faces_right: bool = GameConfig.PLAYERS[attacker]["faces_right"]
	var victim := GameConfig.opponent_of(attacker)

	var from := _hud.get_panel(attacker).get_edge_point(attacker_faces_right)
	var to := _hud.get_panel(victim).get_edge_point(not attacker_faces_right)
	_projectile.launch(attacker, from, to)


func _on_projectile_hit(attacker: int) -> void:
	_audio.play_sfx(GameAssets.Sfx.HIT)
	var victim := GameConfig.opponent_of(attacker)
	_match.apply_damage(victim, GameConfig.DAMAGE)
	_hud.get_panel(victim).flash()

	if _match.is_over():
		_phase = GamePhase.State.GAME_OVER
		_round.stop()
		_game_over_panel.show_result(_match.get_winner())
		return

	await get_tree().create_timer(GameConfig.NEXT_QUESTION_DELAY).timeout
	_round.start_round()


func _on_restart_requested() -> void:
	_game_over_panel.visible = false
	_match.reset()
	_repository.reset_history()
	_round.start_round()
