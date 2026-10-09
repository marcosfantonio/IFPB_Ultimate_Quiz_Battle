class_name InputRouter
extends Node
## Traduz teclas em eventos do jogo. Não decide se o input é válido:
## quem escuta (Battle / RoundController) filtra pelo estado atual.

signal start_requested
signal answer_requested(player: int, option_index: int)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		start_requested.emit()
		return

	for player in GameConfig.PLAYERS:
		var keys: Array = GameConfig.PLAYERS[player]["keys"]
		var option_index := keys.find(event.keycode)
		if option_index != -1:
			answer_requested.emit(player, option_index)
			return
