class_name AudioManager
extends Node
## Música de fundo e efeitos sonoros.

var _bgm_player: AudioStreamPlayer


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = GameAssets.BGM_MAIN
	add_child(_bgm_player)


func play_bgm() -> void:
	_bgm_player.play()


func play_sfx(sfx: GameAssets.Sfx) -> void:
	var stream: AudioStream = GameAssets.SFX_STREAMS.get(sfx)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
