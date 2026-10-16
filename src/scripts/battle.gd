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
var _options_screen: OptionsScreen
var _question_creator_screen: QuestionCreatorScreen
var _battle_setup_screen: BattleSetupScreen
var _battle_intro_screen: BattleIntroScreen
var _battle_results_screen: BattleResultsScreen


func _ready() -> void:
	z_index = 10
	_repository.load_from_file(GameConfig.QUESTIONS_PATH)

	_create_systems()
	_create_ui()
	_connect_signals()

	_audio.play_menu_bgm()


# ==================== SETUP ====================

func _create_systems() -> void:
	_audio = AudioManager.new()
	add_child(_audio)

	_round = RoundController.new()
	_round.setup(_repository)
	add_child(_round)

	var input_router := InputRouter.new()
	input_router.start_requested.connect(_on_start_requested)
	input_router.menu_move_requested.connect(_on_menu_move_requested)
	input_router.answer_requested.connect(_on_answer_requested)
	add_child(input_router)

	for player in GameConfig.PLAYERS:
		var idle_animator := IdleAnimator.new()
		idle_animator.setup(player)
		idle_animator.pose_changed.connect(_on_pose_changed)
		add_child(idle_animator)

	# Primeiro filho: desenha atrás da UI, como no jogo original.
	_projectile = Projectile.new()
	_projectile.z_index = 20
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

	_options_screen = OptionsScreen.new()
	_options_screen.visible = false  # só aparece quando clicar em opções
	_options_screen.audio_manager = _audio
	add_child(_options_screen)

	_question_creator_screen = QuestionCreatorScreen.new()
	_question_creator_screen.visible = false
	add_child(_question_creator_screen)

	_battle_setup_screen = BattleSetupScreen.new()
	_battle_setup_screen.visible = false
	add_child(_battle_setup_screen)

	_battle_intro_screen = BattleIntroScreen.new()
	_battle_intro_screen.visible = false
	add_child(_battle_intro_screen)

	_battle_results_screen = BattleResultsScreen.new()
	_battle_results_screen.visible = false
	add_child(_battle_results_screen)


func _connect_signals() -> void:
	_match.hp_changed.connect(_hud.set_hp)

	_round.question_started.connect(_on_question_started)
	_round.answer_resolved.connect(_on_answer_resolved)
	_round.retry_unlocked.connect(_hud.question_panel.reset_highlights)

	_projectile.hit.connect(_on_projectile_hit)
	_game_over_panel.restart_requested.connect(_on_restart_requested)
	_connect_start_screen_signals()
	_options_screen.back_requested.connect(_on_back_from_options)
	_question_creator_screen.back_requested.connect(_on_back_from_creator)
	_battle_setup_screen.start_requested.connect(_on_battle_setup_started)
	_battle_setup_screen.back_requested.connect(_on_back_from_battle_setup)
	_battle_intro_screen.player_name_revealed.connect(_on_intro_player_name_revealed)
	_battle_intro_screen.battle_reveal_started.connect(_on_battle_reveal_started)
	_battle_intro_screen.finished.connect(_on_battle_intro_finished)
	_battle_results_screen.finished.connect(_on_battle_results_finished)


func _connect_start_screen_signals() -> void:
	_start_screen.options_pressed.connect(_on_options_pressed)
	_start_screen.battle_requested.connect(_on_new_battle_requested)
	_start_screen.creator_requested.connect(_on_creator_requested)


# ==================== INPUT / MENU ====================

func _on_start_requested() -> void:
	if _phase != GamePhase.State.START_SCREEN:
		return
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.confirm_selection()


func _on_menu_move_requested(direction: int) -> void:
	if _phase != GamePhase.State.START_SCREEN or not _start_screen.menu_open:
		return
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.move_selection(direction)


func _on_new_battle_requested() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.visible = false
	_battle_setup_screen.visible = true
	_phase = GamePhase.State.BATTLE_SETUP
	_battle_setup_screen.focus_first_field.call_deferred()


func _on_battle_setup_started(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String) -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_audio.play_battle_intro_bgm()
	_hud.get_panel(1).set_identity(player_1_name, player_1_team)
	_hud.get_panel(2).set_identity(player_2_name, player_2_team)
	_battle_setup_screen.visible = false
	_hud.visible = true
	_hud.set_intro_mode(true)
	_phase = GamePhase.State.BATTLE_INTRO
	_battle_intro_screen.play(player_1_name, player_1_team, player_2_name, player_2_team)


func _on_intro_player_name_revealed(_player: int) -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)


func _on_battle_reveal_started() -> void:
	_hud.set_intro_mode(false)


func _on_battle_intro_finished() -> void:
	_audio.play_battle_bgm()
	_phase = GamePhase.State.WAITING
	_round.start_round()
	_start_screen.queue_free()
	_start_screen = null


func _on_back_from_battle_setup() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_battle_setup_screen.visible = false
	_start_screen.visible = true
	_start_screen.open_menu()
	_phase = GamePhase.State.START_SCREEN


func _on_creator_requested() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.visible = false
	_question_creator_screen.visible = true


func _on_back_from_creator() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_question_creator_screen.visible = false
	_start_screen.visible = true
	_start_screen.open_menu()


func _on_options_pressed() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.visible = false
	_options_screen.visible = true


func _on_back_from_options() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_options_screen.visible = false
	_start_screen.visible = true


func _on_answer_requested(player: int, option_index: int) -> void:
	if _phase == GamePhase.State.QUESTION:
		_round.submit_answer(player, option_index)


func _on_pose_changed(player: int, alt_pose: bool) -> void:
	_hud.get_panel(player).set_alt_pose(alt_pose)


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
	var attacker_panel := _hud.get_panel(attacker)
	await attacker_panel.play_preparing()
	attacker_panel.play_throw()
	var attacker_faces_right: bool = GameConfig.PLAYERS[attacker]["faces_right"]
	var victim := GameConfig.opponent_of(attacker)

	var projectile_height: float = GameConfig.PROJECTILE_VERTICAL_RATIO + GameConfig.PROJECTILE_START_VERTICAL_OFFSET
	var from := _hud.get_panel(attacker).get_edge_point(attacker_faces_right, projectile_height)
	var to := _hud.get_panel(victim).get_edge_point(not attacker_faces_right, projectile_height)
	var extension_direction: float = 1.0 if attacker_faces_right else -1.0
	from.x -= extension_direction * GameConfig.PROJECTILE_HORIZONTAL_EXTENSION
	from.x += extension_direction * GameConfig.PROJECTILE_START_TOWARD_CENTER_OFFSET
	to.x += extension_direction * GameConfig.PROJECTILE_HORIZONTAL_EXTENSION
	var shadow_y: float = _hud.get_panel(attacker).get_sprite_y(GameConfig.PROJECTILE_SHADOW_START_RATIO)
	_projectile.launch(attacker, from, to, shadow_y)


func _on_projectile_hit(attacker: int) -> void:
	_audio.play_sfx(GameAssets.Sfx.HIT)
	var victim := GameConfig.opponent_of(attacker)
	_match.apply_damage(victim, GameConfig.DAMAGE)
	_hud.get_panel(victim).flash()
	_hud.get_panel(victim).play_hit_animation()
	_hud.get_panel(attacker).finish_throw()

	if _match.is_over():
		_phase = GamePhase.State.GAME_OVER
		_round.stop()
		_game_over_panel.visible = false
		_audio.play_battle_lose_bgm()
		var winner := _match.get_winner()
		var winning_team: String = "EMPATE" if winner == 0 else _hud.get_panel(winner).get_team_name()
		_battle_results_screen.play(winning_team)
		return

	await get_tree().create_timer(GameConfig.NEXT_QUESTION_DELAY).timeout
	_round.start_round()


func _on_restart_requested() -> void:
	_game_over_panel.visible = false
	_match.reset()
	_repository.reset_history()
	_round.start_round()


func _on_battle_results_finished() -> void:
	_hud.visible = false
	_game_over_panel.visible = false
	_match.reset()
	_repository.reset_history()
	_start_screen = StartScreen.new()
	_start_screen.modulate.a = 0.0
	add_child(_start_screen)
	_connect_start_screen_signals()
	_audio.play_menu_bgm()
	var menu_fade := create_tween()
	menu_fade.tween_property(_start_screen, "modulate:a", 1.0, 1.0)
	_battle_results_screen.fade_to_menu(1.0)
	await menu_fade.finished
	_phase = GamePhase.State.START_SCREEN
