class_name AudioManager
extends Node
## Música de fundo e efeitos sonoros com controle independente de volume.

var _bgm_player: AudioStreamPlayer
var _music_volume_db: float = 0.0
var _sfx_volume_db: float = 0.0
var _paused_bgm_stream: AudioStreamMP3
var _paused_bgm_position: float = 0.0
var _paused_bgm_loop: bool = false


func _ready() -> void:
	_bgm_player = $BGMPlayer as AudioStreamPlayer


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

func play_menu_bgm() -> void:
	_play_bgm(GameAssets.BGM_MENU, true)


func play_question_maker_bgm() -> void:
	_play_bgm(GameAssets.BGM_QUESTION_MAKER, true)


func play_battle_intro_bgm() -> void:
	_play_bgm(GameAssets.BGM_BATTLE_START, false)


func play_battle_bgm() -> void:
	_play_bgm(GameAssets.BGM_BATTLE, true)


func play_battle_lose_bgm() -> void:
	_play_bgm(GameAssets.BGM_BATTLE_LOSE, false)


func fade_to_fatality_bgm(fade_duration: float) -> void:
	if _bgm_player.stream is AudioStreamMP3 and _bgm_player.playing:
		_paused_bgm_stream = _bgm_player.stream as AudioStreamMP3
		_paused_bgm_position = _bgm_player.get_playback_position()
		_paused_bgm_loop = _paused_bgm_stream.loop
	else:
		_paused_bgm_stream = GameAssets.BGM_BATTLE
		_paused_bgm_position = 0.0
		_paused_bgm_loop = true

	if _bgm_player.playing:
		var fade := create_tween()
		fade.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		await fade.finished
	_bgm_player.stop()
	_play_bgm(GameAssets.BGM_FATALITY, false)


func resume_paused_bgm(fade_duration: float) -> void:
	if _paused_bgm_stream == null:
		play_battle_bgm()
		return
	_bgm_player.stop()
	_paused_bgm_stream.loop = _paused_bgm_loop
	_bgm_player.stream = _paused_bgm_stream
	_bgm_player.volume_db = -80.0
	_bgm_player.play(_paused_bgm_position)
	var fade := create_tween()
	fade.tween_property(_bgm_player, "volume_db", _music_volume_db, fade_duration)
	await fade.finished
	_paused_bgm_stream = null
	_paused_bgm_position = 0.0


func stop_bgm() -> void:
	if _bgm_player != null:
		_bgm_player.stop()


func _play_bgm(stream: AudioStreamMP3, loop: bool) -> void:
	if _bgm_player != null and is_inside_tree():
		_bgm_player.stop()
		stream.loop = loop
		_bgm_player.stream = stream
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


func play_looping_sfx(sfx: GameAssets.Sfx) -> AudioStreamPlayer:
	var source := GameAssets.SFX_STREAMS.get(sfx) as AudioStreamMP3
	if source == null:
		return null
	var stream := source.duplicate() as AudioStreamMP3
	stream.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _sfx_volume_db
	add_child(player)
	player.play()
	return player


func stop_looping_sfx(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.stop()
	player.queue_free()
