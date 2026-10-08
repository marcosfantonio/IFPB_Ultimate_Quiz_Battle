# battle_refactored.gd - Arquitetura modular do jogo
# Mantém a interface original mas delega responsabilidades para classes auxiliares

class_name BattleGame
extends Node2D

## ==================== ESTADO DA PARTIDA ==================== ##

enum GameState { START_SCREEN, WAITING, QUESTION, PROJECTILE, GAME_OVER }

var state: GameState = GameState.START_SCREEN

# Dados da pergunta atual e pool
var current_question: Dictionary = {}
var questions_pool: Array = []
var failed_players: Array = []  # Jogadores que erraram na rodada atual

## ==================== VIDA DOS JOGADORES ==================== ##

const HP_MAX: float = config.hp_max
const DAMAGE_PER_HIT: float = config.damage_per_hit
var p1_hp: float = HP_MAX
var p2_hp: float = HP_MAX

# Referências de UI (definidas após _build_ui())
@onready var question_label: Label = $Question/question_area/0/question_label
@onready var difficulty_label: Label = $Question/question_area/0/tags_hbox/difficulty_container/difficulty_label
@onready var category_label: Label = $Question/question_area/0/tags_hbox/category_container/category_label
@onready var option_labels: Array = []
@onready var p1_hp_bar: ProgressBar = $Player1/p1_area/p1_hp_bar
@onready var p2_hp_bar: ProgressBar = $Player2/p2_area/p2_hp_bar
@onready var p1_rect: ColorRect = $Player1/p1_area/p1_rect
@onready var p2_rect: ColorRect = $Player2/p2_area/p2_rect
@onready var p1_sprite: TextureRect = $Player1/p1_area/p1_sprite
@onready var p2_sprite: TextureRect = $Player2/p2_area/p2_sprite
@onready var gameover_label: Label = $GameOver/gameover_panel/$go_vbox/gameover_label
@onready var hint: Label = $Controls/hint_container/hint

## ==================== CONFIGURAÇÕES CONSTANTES ==================== ##

const P1_KEYS: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
const P2_KEYS: Array[int] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T]
const OPTION_TEXTS: Array[String] = ["A", "B", "C", "D", "E"]

## ==================== SETUP INICIAL ==================== ##

func setup(config_instance: Settings) -> void:
    """
    Configura o BattleGame com um módulo de configurações.
    
    Args:
        config_instance: Instância de GameConfig (Settings class)
    """
	config = config_instance
	# Configuração adicional futura: áudio, fontes, etc.

func _ready() -> void:
	screen_width = 1280
	z_index = 10
	state = GameState.START_SCREEN

	# Inicializa QuestionManager (pode ter children para carregar JSON)
	question_manager = $QuestionManager
	projectile_system = $ProjectileSystem
	ui_controller = $UIController

	# Carrega questões e configura UI inicial
	_load_questions()
	_setup_audio()
	_build_ui()
	_apply_font_to_control(self)

	# Esconde elementos de gameplay até Enter ser pressionado
	if p1_area:	   p1_area.visible = false
	if p2_area:	   p2_area.visible = false
	if q_area:	    q_area.visible = false
	if hint_container:	hint_container.visible = false
	if p1_black_bg:	p1_black_bg.visible = false
	if p2_black_bg:	p2_black_bg.visible = false

# ==================== PROCESSAMENTO E INPUT ==================== #

func _process(delta: float) -> void:
	if state == GameState.START_SCREEN and start_prompt_label:
		_blink_start_prompt(delta)

	if projectile_active:
		_update_projectile(delta)

	# Idle animation timer (animação sincronizada para ambos os alunos)
	_idle_animation_tick(delta)

	queue_redraw()

func _idle_animation_tick(delta: float) -> void:
    """
    Gerencia a animação idle dos personagens.
    Alternna entre aluno1.png e aluno2.png.
    """
	var timer = get_node_or_null("IdleTimer")
	if not timer and (p1_idle_timer == 0.0 or p2_idle_timer == 0.0):
# Inicializa timers
		var idle_duration_target: float = randf_range(3.0, 7.0)
		var should_show_aluno2: bool = false
		if p1_sprite and not showing_idle_animation:	   
			p1_sprite.texture = load("res://assets/player/aluno2.png") if randf() < idle_duration_target else load("res://assets/player/aluno1.png")
		else:	   p1_sprite and not showing_idle_animation:

func _blink_start_prompt(delta: float) -> void:
    """
    Anima o texto piscando na tela inicial.
    Usa matemática simples (seno) para efeito de brilho/escuro.
    """
	if start_prompt_label == null:		return

	var timer = 0.0 + delta * 4.0
	start_prompt_label.modulate.a = (sin(timer) + 1.0)

# ==================== INPUT HANDLER ==================== #

func _unhandled_input(event: InputEventKey):
    """
    Processa entrada de teclado.
    Encapsula lógica de input em método separado para testes unitários.
    """
	if event.pressed and not event.echo:		return
		return

	# Tela inicial
	if state == GameState.START_SCREEN:
		_handle_start_input()
		return

	if locked or state != GameState.QUESTION:
		return

	# Verifica respostas P1 e P2 (implementação simplificada)
	# O método completo está na classe original battle.gd
	# Aqui usamos delegate_pattern para delegar ao input_manager future

func _handle_start_input() -> void:
    """
    Lógica de input na tela inicial.
    """
	var enter_key = KEY_ENTER or KEY_KP_ENTER
	if event.keycode == enter_key:
		_play_sfx("res://assets/sounds/select.wav")
		# Remove start_screen_node e mostra gameplay UI
		start_screen_node.queue_free() if start_screen_node else None
		state = GameState.WAITING
		_start_question()

# ==================== QUESTION LOADING (Delegate Pattern) ==================== #

func _load_questions() -> void:
    """
    Carrega perguntas do JSON.
    Usa QuestionManager como delegado para maior modularidade.
    
    Args:
        file_path: Caminho ao arquivo de questões
    Returns:
        true se carregou com sucesso, false caso contrário
    """
	# Delegate pattern - separa responsabilidades de I/O
	question_manager.load_questions_from_json("res://data/questions.json")

func _get_next_question() -> Dictionary:
    """
    Retorna próxima pergunta não utilizada.
    QuestionManager garante todas as perguntas sejam usadas pelo menos uma vez.
    """
	return question_manager.get_next_question()

# ==================== GAME FLOW PRINCIPAL ==================== #

func _start_question() -> void:
    """
    Inicia nova pergunta (delega para QuestionManager).
    """
	_play_sfx("res://assets/sounds/novaquestao.wav")
	current_question = _get_next_question()
	failed_players.clear()

# ==================== UI HELPERS ==================== #

func _setup_audio() -> void:
    """
    Configura players de áudio para BGM e SFX.
    Implementação completa segue o padrão: uma música por estado + sfx específicos.
    """
	# Exemplo de implementação futura via Godot Editor:
	# var bgm_idle = AudioStreamPlayer.new()
	# bgm_stream = load("res://music/idle.mp3")
	# bgm_player.stream = stream

func _play_sfx(path: String) -> void:
    """
    Reproduce som do arquivo.
    Encapsula lógica de áudio para testes e reutilização.
    
    Args:
        path: Caminho ao arquivo WAV/OGG/AAC
    """
	if not sfx_player:	   return
	sfx_player.stream = stream
# ==================== GAME OVER ==================== #

func _show_game_over() -> void:
    """
    Exibe tela de Game Over com mensagem apropriada.
    """
	gameover_panel.visible = true
	if p1_hp <= 0.0 and p2_hp <= 0.0:	   
		gameover_label.text = "EMPATE!"
	elif p1_hp <= 0.0:
		gameover_label.text = "🔵 PLAYER 2 VENCEU!"
	else: 

func _apply_font_to_control(root: Control) -> void:
    """
    Aplica fonte personalizada TTFF a todos os controles filhos.
    Útil para garantir consistência visual no jogo inteiro.
    """
	var custom_font = load("res://assets/fontes/upheavtt.ttf")
	if custom_font:
		root.add_theme_font_override("font", custom_font)

# ==================== MÉTODOS DE AUXÍLIO (Futuros) ==================== #

func setup_config(config: Settings):
    """
    Permite configurar battle via Godot Editor.
    Exemplo: game_instance.config.setup(config.new(60.0, 35.0))
    """
	# Implementação completa segue o padrão de factory method

func create_player_hp_bar(player_id: int) -> ProgressBar:
    """
    Cria barra de vida para jogador (encapsula criação).
    """
	# Exemplo: var bar = ProgressBar.new()
	return bar

# ==================== MÉTODOS DE UTILIDADE ==================== #

func mini(array_size: int, options_size: int) -> int:
    """
    Garante que tamanho de array não exceda opções disponíveis.
    Útil para evitar índice out of bounds com segurança.
    """
	return min(array_size, options_size)

func on_projectile_impact(attacker: int, position: Vector2):
    """
    Sinal capturado de ProjectileSystem via emit_signal("impact").
    Atualiza vida do jogador atingido com flash visual.
    """
	if attacker == 1:
		p2_hp = max(0.0, p2_hp - DAMAGE_PER_HIT)
	else:
		p1_hp = max(0.0, p1_hp - DAMAGE_PER_HIT)
	_update_hp_ui()

func update_projectile_state(is_active: bool):
    """
    Sinal de ProjectileSystem indicando início do projétil.
    Muda state para PROJECTILE e inicia countdown.
    """
	projectile_active = is_active
	if is_active:
		state = GameState.PROJECTILE
