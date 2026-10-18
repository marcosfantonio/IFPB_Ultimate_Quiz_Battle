@tool
class_name GameAssets
extends RefCounted
## Todos os caminhos de assets em um lugar só.

enum Sfx { SELECT, CORRECT, WRONG, NEW_QUESTION, HIT }

const FONT = preload("res://assets/fontes/upheavtt.ttf")

const TEX_STUDENT_IDLE = preload("res://assets/player/idle_1.png")
const TEX_STUDENT_ALT = preload("res://assets/player/looking_right.png")
const TEX_STUDENT_HURT = preload("res://assets/player/hurt.png")
const TEX_STUDENT_DIZZY_1 = preload("res://assets/player/dizzy_1.png")
const TEX_STUDENT_DIZZY_2 = preload("res://assets/player/dizzy_2.png")
const TEX_STUDENT_PREPARING_1 = preload("res://assets/player/preparing_1.png")
const TEX_STUDENT_PREPARING_2 = preload("res://assets/player/preparing_2.png")
const TEX_STUDENT_PREPARING_3 = preload("res://assets/player/preparing_3.png")
const TEX_STUDENT_THROW = preload("res://assets/player/throw.png")
const TEX_PAPER_BALL = preload("res://assets/objects/bola_papel.png")
const TEX_LOGO = preload("res://assets/interface/logo.png")
const TEX_OPTIONS_ICON = preload("res://assets/interface/opcoes.png")
const TEX_MENU_BACKGROUND = preload("res://assets/background/menu.png")
const TEX_CREATOR_BACKGROUND = TEX_MENU_BACKGROUND
const TEX_BATTLE_BACKGROUND = preload("res://assets/background/cenario.png")

const BGM_MENU = preload("res://assets/musics/menu_theme.mp3")
const BGM_QUESTION_MAKER = preload("res://assets/musics/question_maker.mp3")
const BGM_BATTLE_START = preload("res://assets/musics/battle_start.mp3")
const BGM_BATTLE = preload("res://assets/musics/battle_theme.mp3")
const BGM_BATTLE_LOSE = preload("res://assets/musics/battle_ending.mp3")

const SFX_STREAMS = {
	Sfx.SELECT: preload("res://assets/sounds/select.wav"),
	Sfx.CORRECT: preload("res://assets/sounds/acerto.wav"),
	Sfx.WRONG: preload("res://assets/sounds/erro.wav"),
	Sfx.NEW_QUESTION: preload("res://assets/sounds/novaquestao.wav"),
	Sfx.HIT: preload("res://assets/sounds/HIT.wav"),
}
