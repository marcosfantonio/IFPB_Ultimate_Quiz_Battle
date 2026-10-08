# UIController - Encapsula toda lógica de interface
# Node separado para facilitar testes e reutilização em outros painéis
class_name ControlHelper
extends Control

## ==================== ELEMENTOS DA UI ==================== ##

@export_group("⚡ Elementos de Pergunta")
var question_label: Label
@onready var difficulty_label: Label
@onready var category_label: Label
@onready var option_labels: Array = []

@export_group("💚 Player 1 - Vida")
var p1_hp_bar: ProgressBar
var p1_rect: ColorRect
var p1_sprite: TextureRect

@export_group("🔵 Player 2 - Vida")
var p2_hp_bar: ProgressBar
var p2_rect: ColorRect
var p2_sprite: TextureRect

@onready var gameover_panel: PanelContainer = $../gameover_panel

## ==================== CONFIGURAÇÃO EXTERNA ==================== ##

# Mapeamento de teclas por jogador (editável no Godot!)
@export_group("⌨️ Key Bindings")
var p1_keys: PackedStringArray = ["1", "2", "3", "4", "5"]
var p2_keys: PackedStringArray = ["Q", "W", "E", "R", "T"]

# Textos das opções (útil quando mapeamento muda)
@export_group("📝 Option Texts") 
var option_texts: Array = ["A", "B", "C", "D", "E"]

func _ready() -> void:
	# Inicializa arrays e conexões (implementação mínima)
	p1_keys.shuffle()
p2_keys.shuffle()
option_labels.resize(5)
