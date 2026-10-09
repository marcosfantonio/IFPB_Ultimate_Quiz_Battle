class_name GameConfig
extends RefCounted
## Constantes de balanceamento, layout e perfil dos jogadores.
## Para ajustar o jogo (vida, dano, teclas, cores) mexa só aqui.

const SCREEN_SIZE = Vector2(1152, 648)

# --- Combate ---
const HP_MAX = 10.0
const DAMAGE = 1.0

# --- Fluxo da rodada (segundos) ---
const WRONG_ANSWER_DELAY = 0.8
const NEXT_QUESTION_DELAY = 0.5

# --- Projétil ---
const PROJECTILE_SPEED = 600.0
const PROJECTILE_ARC_HEIGHT = 200.0
const TRAIL_WIDTH = 4.0
const TRAIL_MAX_POINTS = 80

# --- Animação idle dos alunos (segundos) ---
const IDLE_FIRST_DELAY = 4.0
const IDLE_POSE_RANGE = Vector2(1.5, 3.5)  # quanto tempo fica na pose alternativa
const IDLE_WAIT_RANGE = Vector2(3.0, 7.0)  # quanto tempo espera até trocar de pose

# --- Dados ---
const QUESTIONS_PATH = "res://data/questions.json"
const MAX_OPTIONS = 5

# --- Jogadores ---
const PLAYERS = {
	1: {
		"name": "PLAYER 1",
		"color": Color(1, 0.35, 0.35),
		"win_text": "🔴 PLAYER 1 VENCEU!",
		"win_color": Color(1, 0.3, 0.3),
		"keys": [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5],
		"key_labels": ["1", "2", "3", "4", "5"],
		"panel_position": Vector2(30, 200),
		"flip_h": true,
		"faces_right": true,
	},
	2: {
		"name": "PLAYER 2",
		"color": Color(0.35, 0.55, 1),
		"win_text": "🔵 PLAYER 2 VENCEU!",
		"win_color": Color(0.3, 0.6, 1),
		"keys": [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T],
		"key_labels": ["Q", "W", "E", "R", "T"],
		"panel_position": Vector2(880, 200),
		"flip_h": false,
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
