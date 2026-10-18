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
var _correct_counts: Dictionary = {1: 0, 2: 0}
var _error_counts: Dictionary = {1: 0, 2: 0}
var _debug_lethal_pending: bool = false

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
var _menu_transitioning: bool = false
var _ui_layer: CanvasLayer
var _screen_transition_overlay: ColorRect

const CREATOR_TRANSITION_TIME = 1.5
const START_SCREEN_SCENE = preload("res://scenes/ui/start_screen.tscn")


func _ready() -> void:
	z_index = 10
	_repository.load_from_file(GameConfig.QUESTIONS_PATH)

	_create_systems()
	_create_ui()
	_connect_signals()

	_audio.play_menu_bgm()


# ==================== SETUP ====================

func _create_systems() -> void:
	_ui_layer = $UI as CanvasLayer
	_audio = $AudioManager as AudioManager

	_round = $RoundController as RoundController
	_round.setup(_repository)

	var input_router := $InputRouter as InputRouter
	input_router.start_requested.connect(_on_start_requested)
	input_router.menu_move_requested.connect(_on_menu_move_requested)
	input_router.debug_win_requested.connect(_on_debug_win_requested)
	input_router.answer_requested.connect(_on_answer_requested)
	var idle_animator_1 := $IdleAnimator1 as IdleAnimator
	idle_animator_1.setup(1)
	idle_animator_1.pose_changed.connect(_on_pose_changed)
	var idle_animator_2 := $IdleAnimator2 as IdleAnimator
	idle_animator_2.setup(2)
	idle_animator_2.pose_changed.connect(_on_pose_changed)

	_projectile = $UI/Projectile as Projectile
	_projectile.z_index = 20


func _create_ui() -> void:
	_hud = $UI/BattleHud as BattleHud
	_game_over_panel = $UI/GameOverPanel as GameOverPanel
	_start_screen = $UI/StartScreen as StartScreen
	_options_screen = $UI/OptionsScreen as OptionsScreen
	_options_screen.audio_manager = _audio
	_question_creator_screen = $UI/QuestionCreatorScreen as QuestionCreatorScreen
	_battle_setup_screen = $UI/BattleSetupScreen as BattleSetupScreen
	_battle_intro_screen = $UI/BattleIntroScreen as BattleIntroScreen
	_battle_results_screen = $UI/BattleResultsScreen as BattleResultsScreen
	_screen_transition_overlay = $UI/ScreenTransition as ColorRect


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
	_question_creator_screen.bank_selected.connect(_on_question_bank_selected)
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
	if _phase != GamePhase.State.START_SCREEN or _menu_transitioning:
		return
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.confirm_selection()


func _on_menu_move_requested(direction: int) -> void:
	if _phase != GamePhase.State.START_SCREEN or _menu_transitioning or not _start_screen.menu_open:
		return
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.move_selection(direction)


func _on_debug_win_requested() -> void:
	if _phase != GamePhase.State.QUESTION or _projectile.is_flying():
		return
	var correct_index: int = _round.current_question.correct_index
	_hud.question_panel.highlight_answer(correct_index, correct_index)
	_audio.play_sfx(GameAssets.Sfx.CORRECT)
	FloatingText.spawn(_ui_layer, _hud.get_panel(1).get_floating_text_origin(), "ACERTOU!", Color(0.2, 1, 0.3))
	_debug_lethal_pending = true
	_launch_projectile(1)


func _on_new_battle_requested() -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_start_screen.visible = false
	_battle_setup_screen.visible = true
	_phase = GamePhase.State.BATTLE_SETUP
	_battle_setup_screen.focus_first_field.call_deferred()


func _on_battle_setup_started(player_1_name: String, player_1_team: String, player_2_name: String, player_2_team: String) -> void:
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	_audio.play_battle_intro_bgm()
	for player in GameConfig.PLAYERS:
		_correct_counts[player] = 0
		_error_counts[player] = 0
	_debug_lethal_pending = false
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
	if _menu_transitioning:
		return
	_menu_transitioning = true
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	await _fade_entire_screen_to_black()
	_start_screen.visible = false
	_question_creator_screen.modulate.a = 1.0
	_question_creator_screen.visible = true
	_audio.play_question_maker_bgm()
	await _fade_entire_screen_from_black()
	_menu_transitioning = false


func _on_back_from_creator() -> void:
	await _return_from_creator()


func _on_question_bank_selected(bank_name: String, questions: Array) -> void:
	_repository.load_from_data({"name": bank_name, "questions": questions})
	_repository.reset_history()
	_audio.play_sfx(GameAssets.Sfx.SELECT)
	await _return_from_creator()


func _return_from_creator() -> void:
	if _menu_transitioning:
		return
	_menu_transitioning = true
	await _fade_entire_screen_to_black()
	_question_creator_screen.visible = false
	_question_creator_screen.modulate.a = 1.0
	_start_screen.modulate.a = 1.0
	_start_screen.visible = true
	_start_screen.open_menu()
	_audio.play_menu_bgm()
	await _fade_entire_screen_from_black()
	_menu_transitioning = false


func _fade_entire_screen_to_black() -> void:
	_screen_transition_overlay.color = Color(0, 0, 0, 0)
	_screen_transition_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(_screen_transition_overlay, "color", Color(0, 0, 0, 1), CREATOR_TRANSITION_TIME)
	await tween.finished


func _fade_entire_screen_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(_screen_transition_overlay, "color", Color(0, 0, 0, 0), CREATOR_TRANSITION_TIME)
	await tween.finished
	_screen_transition_overlay.visible = false


func _on_options_pressed() -> void:
	if _menu_transitioning:
		return
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
		_correct_counts[player] += 1
		_audio.play_sfx(GameAssets.Sfx.CORRECT)
		FloatingText.spawn(_ui_layer, origin, "ACERTOU!", Color(0.2, 1, 0.3))
		_launch_projectile(player)
	else:
		_error_counts[player] += 1
		_audio.play_sfx(GameAssets.Sfx.WRONG)
		FloatingText.spawn(_ui_layer, origin, "ERROU!", Color(1, 0.2, 0.2))


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
	var is_lethal_hit: bool = _debug_lethal_pending or _match.get_hp(victim) <= GameConfig.DAMAGE
	var damage: float = _match.get_hp(victim) if _debug_lethal_pending else GameConfig.DAMAGE
	_debug_lethal_pending = false
	_match.apply_damage(victim, damage)
	_hud.get_panel(victim).flash()
	_hud.get_panel(victim).play_hit_animation(is_lethal_hit)
	_hud.get_panel(attacker).finish_throw()

	if _match.is_over():
		_phase = GamePhase.State.GAME_OVER
		_round.stop()
		_game_over_panel.visible = false
		_audio.play_battle_lose_bgm()
		var winner := _match.get_winner()
		var winning_team: String = "EMPATE" if winner == 0 else _hud.get_panel(winner).get_team_name()
		var correct_count: int = _correct_counts[winner] if winner != 0 else _correct_counts[1] + _correct_counts[2]
		var error_count: int = _error_counts[winner] if winner != 0 else _error_counts[1] + _error_counts[2]
		_battle_results_screen.play(winning_team, correct_count, error_count)
		return

	await get_tree().create_timer(GameConfig.NEXT_QUESTION_DELAY).timeout
	_round.start_round()


func _on_restart_requested() -> void:
	_game_over_panel.visible = false
	_match.reset()
	_repository.reset_history()
	for player in GameConfig.PLAYERS:
		_hud.get_panel(player).finish_dizzy_animation()
	_round.start_round()


func _on_battle_results_finished() -> void:
	_hud.visible = false
	_game_over_panel.visible = false
	_match.reset()
	_repository.reset_history()
	_start_screen = START_SCREEN_SCENE.instantiate() as StartScreen
	_start_screen.modulate.a = 0.0
	_ui_layer.add_child(_start_screen)
	_connect_start_screen_signals()
	for player in GameConfig.PLAYERS:
		_hud.get_panel(player).finish_dizzy_animation()
	_audio.play_menu_bgm()
	var menu_fade := create_tween()
	menu_fade.tween_property(_start_screen, "modulate:a", 1.0, 1.0)
	_battle_results_screen.fade_to_menu(1.0)
	await menu_fade.finished
	_phase = GamePhase.State.START_SCREEN
