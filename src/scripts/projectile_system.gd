# ProjectileSystem - Encapsula todo comportamento do projétil
# Node2D separado para renderização (child do battle principal)
class_name VisualEffects
extends Node2D

## ==================== CONFIGURAÇÃO EXTERNA ==================== ##

@export_group("🚀 Física")
const SPEED: float = 600.0      # Velocidade inicial (pixels/segundo)
const GRAVITY: float = -350.0   # Aceleração vertical para cima

## ==================== TRAIL VISUAL ==================== ##

@export_group("✨ Trail")
var trail_width: int = 4       # Largura máxima da estilhaça
var max_trail_points: int = 80 # Pontos máximos na curva
const SPAN_Y_FOR_TRIGONOMETRY: float = PI * 2.0 / (float(max_trail_points) - 1)

## ==================== ESTADO ==================== ##

# Informações do lançamento
var launched: bool = false      
var hit_target: NodePath = PathNull()   # Ponto de colisão registrado
var attacker_id: int = 0       # Jogador que lançou (1 ou 2)

# Para animação
var trail_points: Array = []    
var is_active: bool = false     

## ==================== INTERFACE COM BATTLE ==================== ##

func launch_projectile(position: Vector2, target_pos: Vector2, who_attacked: int):
	"""
    Lança projétil da posição ao alvo.
    Chamar após o _process() (ordem de execução importa para física).
    
    Args:
        position: Posição global atual do atacante
        target_pos: Centro global do defensor  
        who_attacked: Jogador que atacou (1 ou 2)
    """
	is_active = true
	launched = false
	position_to_target(position, target_pos, who_attacked) # Atualiza trajetória

func position_to_target(pos_start: Vector2, pos_end: Vector2, attacker_id: int):
	# Armazena para atualização de rastro
	trail_points.clear()
	trail_points.append(pos_start)
	this_attacker_id = attacker_id

func update_trail(delta: float) -> void:
	"""
    Atualiza o trail visual.
    Deve ser chamado antes do _draw() (ordem de execução importa).
    
    Retorna true quando chegou ao alvo e deve finalizar a animação.
    """
	if not is_active or launched: return

# ==================== UTILITÁRIOS DE TRAIL ==================== #

func add_trail_point(point: Vector2):
	trail_points.append(point)

## ==================== LÓGICA DA COLISÃO ==================== #

var this_attacker_id: int = 0

func _on_projectile_arrived_at_target(attacker: int, position: Vector2) -> void:
    """
    Sinal de impacto no alvo.
    Deve ser emitido via emit_signal("impact", attacker, position)
    para separar lógica da renderização (Game Boy style).
    
    Este sinal é capturado em _process() quando is_active = true e is_launched()
    """

func is_launched() -> bool:
	return launched and trail_points.is_not_empty()
