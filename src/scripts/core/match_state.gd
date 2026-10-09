class_name MatchState
extends RefCounted
## Estado da partida: vida dos jogadores e condição de vitória.
## Não conhece UI, áudio nem projétil.

signal hp_changed(player: int, hp: float)

var _hp: Dictionary = {}


func _init() -> void:
	reset()


func reset() -> void:
	for player in GameConfig.PLAYERS:
		_hp[player] = GameConfig.HP_MAX
		hp_changed.emit(player, GameConfig.HP_MAX)


func get_hp(player: int) -> float:
	return _hp[player]


func apply_damage(player: int, amount: float) -> void:
	_hp[player] = maxf(0.0, _hp[player] - amount)
	hp_changed.emit(player, _hp[player])


func is_over() -> bool:
	for player in _hp:
		if _hp[player] <= 0.0:
			return true
	return false


## Retorna o id do vencedor, ou 0 em caso de empate.
func get_winner() -> int:
	var alive: Array[int] = []
	for player in _hp:
		if _hp[player] > 0.0:
			alive.append(player)
	return alive[0] if alive.size() == 1 else 0
