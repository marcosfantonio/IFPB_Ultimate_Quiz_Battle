@tool
class_name GameConfig
extends RefCounted
## Constantes de balanceamento, layout e perfil dos jogadores.
## Para ajustar o jogo (vida, dano, teclas, cores) mexa só aqui.

const SCREEN_SIZE = Vector2(1152, 648)

# --- Combate ---
const HP_MAX = 10.0
const DAMAGE = 1.0
const PLAYER_HUD_INWARD_OFFSET = 15.0
const PLAYER_SPRITE_INWARD_OFFSET = 40.0

# --- Fluxo da rodada (segundos) ---
const WRONG_ANSWER_DELAY = 0.8
const NEXT_QUESTION_DELAY = 0.5

# --- Projétil ---
const PROJECTILE_SPEED = 600.0
const PROJECTILE_ARC_HEIGHT = 40.0
const PROJECTILE_VERTICAL_RATIO = 0.1
const PROJECTILE_START_VERTICAL_OFFSET = 0.05
const PROJECTILE_HORIZONTAL_EXTENSION = 70.0
const PROJECTILE_START_TOWARD_CENTER_OFFSET = 40.0
const PROJECTILE_SCALE = 0.3833333333
const PROJECTILE_ROTATION_SPEED = 720.0
const PROJECTILE_SHADOW_START_RATIO = 0.85
const PROJECTILE_SHADOW_HEIGHT_RATIO = 0.3
const PROJECTILE_SHADOW_OPACITY = 0.3
const TRAIL_WIDTH = 8.0
const TRAIL_MAX_POINTS = 80

# --- Animação idle dos alunos (segundos) ---
const IDLE_FIRST_DELAY_RANGE = Vector2(2.0, 6.0)
const IDLE_POSE_RANGE = Vector2(1.5, 3.5)  # quanto tempo fica na pose alternativa
const IDLE_WAIT_RANGE = Vector2(3.0, 7.0)  # quanto tempo espera até trocar de pose
const PROFESSOR_IDLE_FRAME_DURATION = 1.25
const PROFESSOR_MOVE_DISTANCE = 450.0
const PROFESSOR_MOVE_DURATION = 1.5
const PROFESSOR_MOVE_PAUSE = 6.0
const PROFESSOR_TURN_PREPARE_TIME = 1.0
const PROFESSOR_MOVE_INTERVAL_RANGE = Vector2(4.0, 8.0)
const FAST_ANSWER_TIME_LIMIT = 2.0
const FAST_ANSWER_QUESTION_STREAK = 3
const FAST_CORRECT_ANSWER_STREAK = 2
const PROFESSOR_FATALITY_DAMAGE_RATIO = 0.4
const PROFESSOR_RAGE_IDLE_DURATION = 1.5
const PROFESSOR_RAGE_DURATION = 3.0
const PROFESSOR_JUMP_DURATION = 2.5
const PROFESSOR_FATALITY_EXIT_DURATION = 0.55
const PROFESSOR_FATALITY_RETURN_JUMP_DURATION = 0.7
const PROFESSOR_FATALITY_RETURN_IDLE_DURATION = 0.8
const PROFESSOR_SPECIAL_DURATION = 4.0
const PROFESSOR_SPECIAL_FRAME_DURATION = 0.15
const PROFESSOR_FATALITY_EXIT_Y = -180.0
const PROFESSOR_FATALITY_Z_INDEX = 1201
const PROFESSOR_FATALITY_SCREEN_FADE = 0.8
const PROFESSOR_FATALITY_BGM_FADE = 0.8
const PROFESSOR_DOMINO_FLIGHT_DURATION = 1.5
const PROFESSOR_DOMINO_SPIN_TURNS = 3.0
const PROFESSOR_EXPLOSION_FADE_DURATION = 1.5

# --- Dados ---
const QUESTIONS_PATH = "res://data/questions.json"
const MAX_OPTIONS = 5
const OPTIONS_PER_QUESTION = 3

# --- Jogadores ---
const PLAYERS = {
	1: {
		"name": "PLAYER 1",
		"color": Color(1, 0.35, 0.35),
		"win_text": "🔴 PLAYER 1 VENCEU!",
		"win_color": Color(1, 0.3, 0.3),
		"keys": [KEY_1, KEY_2, KEY_3],
		"key_labels": ["1", "2", "3"],
		"panel_position": Vector2(-20, 90),
		"flip_h": false,
		"faces_right": true,
	},
	2: {
		"name": "PLAYER 2",
		"color": Color(0.35, 0.55, 1),
		"win_text": "🔵 PLAYER 2 VENCEU!",
		"win_color": Color(0.3, 0.6, 1),
		"keys": [KEY_Z, KEY_X, KEY_C],
		"key_labels": ["Z", "X", "C"],
		"panel_position": Vector2(812, 90),
		"flip_h": true,
		"faces_right": false,
	},
}


static func opponent_of(player: int) -> int:
	return 2 if player == 1 else 1


static func key_label(player: int, option_index: int) -> String:
	var labels: Array = PLAYERS[player]["key_labels"]
	if option_index < labels.size():
		return labels[option_index]
	return "?"
