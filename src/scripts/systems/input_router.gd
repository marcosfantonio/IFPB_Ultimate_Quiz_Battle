class_name InputRouter
extends Node
## Traduz teclas em eventos do jogo. Não decide se o input é válido:
## quem escuta (Battle / RoundController) filtra pelo estado atual.

signal start_requested
signal answer_requested(player: int, option_index: int)
signal menu_move_requested(direction: int)
signal debug_win_requested
signal debug_fatality_requested

const DEBUG_COMMANDS = ["VENCEU", "TRIGGER"]
const DEBUG_INPUT_TIMEOUT_MS = 1800

var _debug_buffer: String = ""
var _last_debug_key_time: int = 0


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _capture_debug_command(event.keycode):
		return

	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		start_requested.emit()
		return
	if event.keycode == KEY_UP:
		menu_move_requested.emit(-1)
		return
	if event.keycode == KEY_DOWN:
		menu_move_requested.emit(1)
		return

	for player in GameConfig.PLAYERS:
		var keys: Array = GameConfig.PLAYERS[player]["keys"]
		var option_index := keys.find(event.keycode)
		if option_index != -1:
			answer_requested.emit(player, option_index)
			return


func _capture_debug_command(keycode: int) -> bool:
	if keycode < KEY_A or keycode > KEY_Z:
		_debug_buffer = ""
		return false

	var now: int = Time.get_ticks_msec()
	if now - _last_debug_key_time > DEBUG_INPUT_TIMEOUT_MS:
		_debug_buffer = ""
	_last_debug_key_time = now

	var character := String.chr(keycode).to_upper()
	var candidate := _debug_buffer + character
	var matching_command: String = ""
	for command in DEBUG_COMMANDS:
		if command.begins_with(candidate):
			matching_command = command
			break
	if not matching_command.is_empty():
		_debug_buffer = candidate
		if _debug_buffer == matching_command:
			if matching_command == "VENCEU":
				debug_win_requested.emit()
			else:
				debug_fatality_requested.emit()
			_debug_buffer = ""
		return true

	_debug_buffer = ""
	for command in DEBUG_COMMANDS:
		if command.begins_with(character):
			_debug_buffer = character
			break
	return not _debug_buffer.is_empty()
