# GameConfig - Centralizada as constantes configuráveis do jogo
# Para ajustar valores: editar aqui OU via Godot Editor (usando @export_group)

class_name Settings

## ==================== BALANCEAMENTO DE COMBATE ==================== ##

@export_group("⚔️ Battle")
var hp_max: float = 10.0          # Vida máxima por jogador
var damage_per_hit: float = 1.0   # Dano por acerto (exige ~10 hits para eliminar)
var time_limit_seconds: int = 35  # Tempo total da partida (estimado para ~45 questões)

## ==================== PROJÉTIL / FÍSICA ==================== ##

@export_group("🚀 Projectile")
var projectile_speed: float = 600.0    # Velocidade do projétil (px/frame)
var trail_width: int = 4               # Largura da estilhaça na renderização
const GRAVITY_UP: float = -350.0       # Aceleração vertical para cima (simula arco parabólico)

## ==================== DURAÇÃO DE PERGUNTA ==================== ##

@export_group("⏱️ Question Timer")
var wait_between_questions: float = 1.0    # Tempo antes de próxima pergunta (segundos)
const QUESTION_TIMEOUT_SEC: float = 35.0   # Limite absoluto para evitar trava

## ==================== ANIMAÇÃO / VISUAL ==================== ##

@export_group("✨ Animation")
var player_idle_duration_base: float = 1.5       # Duração base da animação idle
const IDLE_MIN_DURATION: float = 0.5             # Limite mínimo de duração
const IDLE_MAX_DURATION: float = 8.0             # Limite máximo de duração
