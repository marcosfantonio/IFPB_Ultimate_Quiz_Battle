class_name AudioManager
extends Node
## Música de fundo e efeitos sonoros com controle independente de volume.

var _bgm_player: AudioStreamPlayer
var _music_volume_db: float = 0.0
var _sfx_volume_db: float = 0.0


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = GameAssets.BGM_MAIN
	add_child(_bgm_player)


# ==================== CONTROLE DE VOLUME ====================

## Converte valor linear [0..1] para dB. 0 → -80dB (silêncio).
static func _linear_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return log(value) * 20.0


## Aplica o volume linear ao player de BGM e atualiza referência interna.
func set_music_volume(linear_value: float) -> void:
	_music_volume_db = _linear_to_db(linear_value)
	if _bgm_player != null and is_inside_tree():
		_bgm_player.volume_db = _music_volume_db


## Aplica o volume linear a todos os efeitos sonoros futuros.
func set_sfx_volume(linear_value: float) -> void:
	_sfx_volume_db = _linear_to_db(linear_value)


# ==================== PLAYBACK ====================

func play_bgm() -> void:
	if _bgm_player != null and is_inside_tree():
		_bgm_player.volume_db = _music_volume_db
		_bgm_player.play()



func play_sfx(sfx: GameAssets.Sfx) -> void:
	var stream: AudioStream = GameAssets.SFX_STREAMS.get(sfx)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _sfx_volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
