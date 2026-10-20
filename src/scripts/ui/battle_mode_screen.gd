class_name BattleModeScreen
extends Control
## Navegação e eventos da cena de escolha do tipo de batalha.

signal local_requested
signal host_requested
signal join_requested
signal back_requested

var _all_buttons: Array[Button] = []
var _selected_index := 0
var _focus_pending := true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 650
	_all_buttons = [
		$Cards/LocalButton as Button,
		$Cards/HostButton as Button,
		$Cards/JoinButton as Button,
		$BackButton as Button,
	]
	_all_buttons[0].pressed.connect(func() -> void: local_requested.emit())
	_all_buttons[1].pressed.connect(func() -> void: host_requested.emit())
	_all_buttons[2].pressed.connect(func() -> void: join_requested.emit())
	_all_buttons[3].pressed.connect(func() -> void: back_requested.emit())
	_update_focus()
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if visible and _focus_pending:
		_focus_pending = false
		_selected_index = 0
		_update_focus()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var direction := 0
	if event.keycode == KEY_LEFT or event.keycode == KEY_UP:
		direction = -1
	elif event.keycode == KEY_RIGHT or event.keycode == KEY_DOWN:
		direction = 1
	if direction != 0:
		_selected_index = posmod(_selected_index + direction, _all_buttons.size())
		_update_focus()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
		_all_buttons[_selected_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		back_requested.emit()
		get_viewport().set_input_as_handled()


func _update_focus() -> void:
	for index in _all_buttons.size():
		if index == _selected_index:
			_all_buttons[index].grab_focus()
		else:
			_all_buttons[index].release_focus()
