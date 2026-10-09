class_name GameAssets
extends RefCounted
## Todos os caminhos de assets em um lugar só.

enum Sfx { SELECT, CORRECT, WRONG, NEW_QUESTION, HIT }

const FONT = preload("res://assets/fontes/upheavtt.ttf")

const TEX_STUDENT_IDLE = preload("res://assets/player/aluno1.png")
const TEX_STUDENT_ALT = preload("res://assets/player/aluno2.png")
const TEX_LOGO = preload("res://assets/interface/logo.png")
const TEX_OPTIONS_ICON = preload("res://assets/interface/opcoes.png")

const BGM_MAIN = preload("res://assets/sounds/main_theme.mp3")

const SFX_STREAMS = {
	Sfx.SELECT: preload("res://assets/sounds/select.wav"),
	Sfx.CORRECT: preload("res://assets/sounds/acerto.wav"),
	Sfx.WRONG: preload("res://assets/sounds/erro.wav"),
	Sfx.NEW_QUESTION: preload("res://assets/sounds/novaquestao.wav"),
	Sfx.HIT: preload("res://assets/sounds/HIT.wav"),
}
