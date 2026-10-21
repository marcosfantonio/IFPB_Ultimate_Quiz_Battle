class_name LanServerPlaceholder
extends Control
## Lógica da tela de configuração e lobby placeholder; layout fica nos .tscn.

signal back_requested
signal start_requested
signal host_requested(player_name: String, team_name: String)
signal join_requested(address: String, player_name: String, team_name: String)
signal start_network_requested
signal role_claim_requested(role: int)
signal ready_changed(ready: bool)
signal discovery_requested
signal test_match_requested(player_one_name: String, player_one_team: String, player_two_name: String, player_two_team: String)
signal local_setup_continue_requested

const SLOT_COLORS = [Color(1, 0.28, 0.24), Color(0.35, 0.8, 1), Color(0.3, 0.55, 1)]

var _setup_page: Control
var _servers_page: Control
var _identity_page: Control
var _lobby_page: Control
var _server_name: LineEdit
var _player_name: LineEdit
var _team_name: LineEdit
var _server_address: OptionButton
var _bank_option: OptionButton
var _timer_toggle: Button
var _fatality_toggle: Button
var _professor_toggle: Button
var _timer_enabled := false
var _fatality_enabled := true
var _slots: Array[Dictionary] = []
var _status_label: Label
var _ready_label: Label
var _start_warning: Label
var _start_button: Button
var _blink_time: float = 0.0
var _claimed_slot: int = -1
var _start_attempted := false
var _focus_controls: Array[Control] = []
var _focus_index := 0
var _focus_pending := true
var _identity_flow := "host"
var _lobby_flow := "host"
var _participant_name := "Jogador local"
var _participant_team := "Equipe local"
var _local_setup_mode := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 670
	_setup_page = $SetupPage as Control
	_servers_page = $ServersPage as Control
	_identity_page = $IdentityPage as Control
	_lobby_page = $LobbyPage as Control
	_server_name = $SetupPage/SetupPanel/Layout/ServerNameEdit as LineEdit
	_player_name = $IdentityPage/IdentityPanel/Content/PlayerNameEdit as LineEdit
	_team_name = $IdentityPage/IdentityPanel/Content/TeamNameEdit as LineEdit
	_server_address = $ServersPage/ServerAddressEdit as OptionButton
	_bank_option = $SetupPage/SetupPanel/Layout/BankOption as OptionButton
	_timer_toggle = $SetupPage/SetupPanel/Layout/TimerToggle as Button
	_fatality_toggle = $SetupPage/SetupPanel/Layout/FatalityToggle as Button
	_professor_toggle = $SetupPage/SetupPanel/Layout/ProfessorToggle as Button
	_status_label = $SetupPage/SetupPanel/Layout/StatusLabel as Label
	_ready_label = $LobbyPage/ReadyCount as Label
	_start_warning = $LobbyPage/StartWarning as Label
	_start_button = $LobbyPage/StartButton as Button

	_style_input(_server_name)
	_style_input(_player_name)
	_style_input(_team_name)
	_style_input(_bank_option)
	_style_button(_timer_toggle, Color(0.025, 0.07, 0.09), Color(0.25, 0.5, 0.58))
	_style_button(_fatality_toggle, Color(0.025, 0.07, 0.09), Color(0.25, 0.5, 0.58))
	_style_button(_professor_toggle, Color(0.025, 0.07, 0.09), Color(0.25, 0.5, 0.58))
	_timer_toggle.pressed.connect(_toggle_timer)
	_fatality_toggle.pressed.connect(_toggle_fatality)
	_professor_toggle.pressed.connect(_cycle_professor)
	_fill_question_banks()
	_update_timer_toggle()
	_update_fatality_toggle()

	$SetupPage/SetupPanel/Layout/Actions/BackButton.pressed.connect(func() -> void: back_requested.emit())
	$SetupPage/SetupPanel/Layout/Actions/CreateButton.pressed.connect(_on_create_pressed)
	$ServersPage/PreparingServer/Content/JoinPreparingButton.pressed.connect(_begin_join_identity)
	$ServersPage/RunningServer/Content/WatchButton.pressed.connect(_watch_running_server)
	$ServersPage/BackButton.pressed.connect(func() -> void: back_requested.emit())
	$ServersPage/RefreshServersButton.pressed.connect(func() -> void: discovery_requested.emit())
	$IdentityPage/IdentityPanel/Content/Actions/BackButton.pressed.connect(_back_from_identity)
	$IdentityPage/IdentityPanel/Content/Actions/ContinueButton.pressed.connect(_continue_from_identity)
	$LobbyPage/BackToSetupButton.pressed.connect(_back_to_setup)
	_start_button.pressed.connect(_on_start_pressed)
	_init_role_slot(0, $LobbyPage/PlayerOneSlot as Control, "PLAYER ONE")
	_init_role_slot(1, $LobbyPage/SpectatorSlot as Control, "ESPECTADOR")
	_init_role_slot(2, $LobbyPage/PlayerTwoSlot as Control, "PLAYER TWO")
	UITheme.apply_font(self)
	_focus_pending = true


func _process(delta: float) -> void:
	if not visible:
		return
	if _focus_pending:
		_focus_pending = false
		_refresh_focus_controls()
	_blink_time += delta * 1.8
	var alpha := 0.62 + (sin(_blink_time) + 1.0) * 0.19
	for slot in _slots:
		if not slot["occupied"]:
			slot["join_button"].modulate.a = alpha


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if _lobby_page.visible:
			_back_to_setup()
		elif _identity_page.visible:
			_back_from_identity()
		elif _servers_page.visible:
			back_requested.emit()
		else:
			back_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_UP or event.keycode == KEY_DOWN or event.keycode == KEY_TAB or event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
		if _focus_controls.is_empty():
			_refresh_focus_controls()
		if not _focus_controls.is_empty():
			var focused := get_viewport().gui_get_focus_owner()
			if focused is LineEdit and event.keycode in [KEY_LEFT, KEY_RIGHT]:
				return
			if focused == _timer_toggle and event.keycode in [KEY_LEFT, KEY_RIGHT]:
				_toggle_timer()
				get_viewport().set_input_as_handled()
				return
			if focused == _fatality_toggle and event.keycode in [KEY_LEFT, KEY_RIGHT]:
				_toggle_fatality()
				get_viewport().set_input_as_handled()
				return
			if focused == _professor_toggle and event.keycode in [KEY_LEFT, KEY_RIGHT]:
				_cycle_professor()
				get_viewport().set_input_as_handled()
				return
			var direction := -1 if event.keycode in [KEY_UP, KEY_LEFT] or (event.keycode == KEY_TAB and event.shift_pressed) else 1
			_focus_index = posmod(_focus_index + direction, _focus_controls.size())
			_focus_controls[_focus_index].grab_focus()
			get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button:
			(focused as Button).emit_signal("pressed")
			get_viewport().set_input_as_handled()


func _init_role_slot(index: int, slot_node: Control, title: String) -> void:
	var role_label := slot_node.get_node("RoleLabel") as Label
	var player_name := slot_node.get_node("PlayerName") as Label
	var team_name := slot_node.get_node("TeamName") as Label
	var square := slot_node.get_node("Square") as Panel
	var avatar := slot_node.get_node("Square/Avatar") as TextureRect
	var join_button := slot_node.get_node("JoinButton") as Button
	var ready_button := slot_node.get_node("ReadyButton") as Button
	var leave_button := slot_node.get_node("LeaveButton") as Button
	role_label.text = title
	role_label.add_theme_color_override("font_color", SLOT_COLORS[index])
	var square_style := _button_style(Color(0.015, 0.04, 0.055, 0.94), SLOT_COLORS[index])
	square_style.set_border_width_all(3)
	square.add_theme_stylebox_override("panel", square_style)
	avatar.flip_h = index == 2
	_style_button(join_button, Color(0.08, 0.28, 0.34), Color(0.35, 0.8, 1))
	_style_button(ready_button, Color(0.42, 0.12, 0.12), Color(1, 0.3, 0.28))
	_style_button(leave_button, Color(0.3, 0.12, 0.12), Color(1, 0.4, 0.35))
	join_button.pressed.connect(_claim_slot.bind(index))
	ready_button.pressed.connect(_toggle_ready.bind(index))
	leave_button.pressed.connect(_leave_slot.bind(index))
	_slots.append({
		"index": index,
		"title": title,
		"occupied": false,
		"ready": false,
		"join_button": join_button,
		"ready_button": ready_button,
		"leave_button": leave_button,
		"name_label": player_name,
		"team_label": team_name,
	})


func _claim_slot(index: int) -> void:
	var slot: Dictionary = _slot(index)
	if _claimed_slot == index:
		return
	if _claimed_slot >= 0:
		_release_slot(_claimed_slot)
	if slot["occupied"]:
		return
	_claimed_slot = index
	if _lobby_flow == "network":
		role_claim_requested.emit(index)
	slot["occupied"] = true
	slot["name_label"].text = _participant_name
	slot["team_label"].text = _participant_team
	slot["join_button"].visible = false
	slot["ready_button"].visible = true
	slot["leave_button"].visible = true
	_focus_pending = true
	_update_ready_count()


func _release_slot(index: int) -> void:
	var slot := _slot(index)
	slot["occupied"] = false
	slot["ready"] = false
	slot["name_label"].text = "Aguardando jogador"
	slot["team_label"].text = "Equipe —"
	slot["join_button"].visible = true
	slot["ready_button"].visible = false
	slot["leave_button"].visible = false
	slot["ready_button"].text = "PRONTO?"
	_style_button(slot["ready_button"], Color(0.42, 0.12, 0.12), Color(1, 0.3, 0.28))
	_claimed_slot = -1
	_focus_pending = true


func _leave_slot(index: int) -> void:
	_release_slot(index)
	_update_ready_count()


func _toggle_ready(index: int) -> void:
	var slot: Dictionary = _slot(index)
	slot["ready"] = not slot["ready"]
	if _lobby_flow == "network":
		ready_changed.emit(bool(slot["ready"]))
	var button: Button = slot["ready_button"]
	button.text = "PRONTO!" if slot["ready"] else "PRONTO?"
	var fill := Color(0.05, 0.38, 0.16) if slot["ready"] else Color(0.42, 0.12, 0.12)
	var border := Color(0.25, 1, 0.45) if slot["ready"] else Color(1, 0.3, 0.28)
	_style_button(button, fill, border)
	_update_ready_count()


func _update_ready_count() -> void:
	var count := 0
	for slot in _slots:
		if slot["ready"]:
			count += 1
	_ready_label.text = "Prontos %d de 3 jogadores" % count
	_start_button.disabled = not (_slot(0)["occupied"] and _slot(2)["occupied"])
	_start_warning.visible = _start_attempted and not (_slot(0)["ready"] and _slot(2)["ready"])


func _on_start_pressed() -> void:
	if _lobby_flow == "network":
		start_network_requested.emit()
		return
	_start_attempted = true
	_update_ready_count()
	if not (_slot(0)["ready"] and _slot(2)["ready"]):
		return
	test_match_requested.emit(
		str(_slot(0)["name_label"].text), str(_slot(0)["team_label"].text),
		str(_slot(2)["name_label"].text), str(_slot(2)["team_label"].text)
	)


func _slot(index: int) -> Dictionary:
	for slot in _slots:
		if slot["index"] == index:
			return slot
	return {}


func _open_lobby() -> void:
	var server_name := _server_name.text.strip_edges()
	if server_name.is_empty():
		server_name = "Servidor Local"
	($LobbyPage/Title as Label).text = "SALA: %s" % server_name
	_setup_page.visible = false
	_lobby_page.visible = true
	_focus_pending = true


func show_server_list() -> void:
	_setup_page.visible = false
	_servers_page.visible = true
	_identity_page.visible = false
	_lobby_page.visible = false
	_focus_pending = true
	discovery_requested.emit()


func show_host_setup() -> void:
	_local_setup_mode = false
	$SetupPage/SetupPanel/Layout/ServerNameLabel.visible = true
	_server_name.visible = true
	$SetupPage/SetupPanel/Layout/Title.text = "CRIAR SERVIDOR LOCAL"
	$SetupPage/SetupPanel/Layout/Actions/CreateButton.text = "CRIAR SERVIDOR"
	_lobby_flow = "host"
	_set_visible_page(_setup_page)


func show_local_setup() -> void:
	_local_setup_mode = true
	$SetupPage/SetupPanel/Layout/ServerNameLabel.visible = false
	_server_name.visible = false
	$SetupPage/SetupPanel/Layout/Title.text = "CONFIGURAR PARTIDA LOCAL"
	$SetupPage/SetupPanel/Layout/Actions/CreateButton.text = "CONTINUAR"
	_lobby_flow = "local_setup"
	_set_visible_page(_setup_page)


func _on_create_pressed() -> void:
	if _local_setup_mode:
		local_setup_continue_requested.emit()
	else:
		_begin_host_identity()


func _begin_host_identity() -> void:
	_identity_flow = "host"
	_lobby_flow = "host"
	_reset_lobby_slots()
	_player_name.text = ""
	_team_name.text = ""
	_set_visible_page(_identity_page)


func _begin_join_identity() -> void:
	_identity_flow = "join"
	_player_name.text = ""
	_team_name.text = ""
	_set_visible_page(_identity_page)


func _continue_from_identity() -> void:
	_participant_name = _player_name.text.strip_edges()
	_participant_team = _team_name.text.strip_edges()
	if _participant_name.is_empty():
		_participant_name = "Jogador local"
	if _participant_team.is_empty():
		_participant_team = "Equipe local"
	if _identity_flow == "host":
		var server_name := _server_name.text.strip_edges()
		if server_name.is_empty():
			server_name = "Servidor Local"
		($LobbyPage/Title as Label).text = "SALA: %s" % server_name
		_lobby_flow = "host"
		host_requested.emit(_participant_name, _participant_team)
		return
	if _server_address.item_count == 0 or _server_address.selected < 0:
		$IdentityPage/IdentityPanel/Content/Status.text = "Nenhum servidor encontrado. Atualize a lista e tente novamente."
		return
	join_requested.emit(str(_server_address.get_item_metadata(_server_address.selected)), _participant_name, _participant_team)
	_lobby_flow = "network_join_pending"
	_set_visible_page(_identity_page)
	$IdentityPage/IdentityPanel/Content/Status.text = "Conectando ao servidor…"
	return
	# A sala de preparação já tem ADM IF no espectador; o usuário escolhe uma
	# vaga de jogador, confirma presença e aguarda o início da partida.
	_reset_lobby_slots()
	_lobby_flow = "join"
	var spectator := _slot(1)
	spectator["occupied"] = true
	spectator["ready"] = true
	spectator["name_label"].text = "ADM IF"
	spectator["team_label"].text = "Espectador"
	spectator["join_button"].visible = false
	spectator["ready_button"].visible = true
	spectator["ready_button"].disabled = true
	spectator["ready_button"].text = "PRONTO!"
	_style_button(spectator["ready_button"], Color(0.05, 0.38, 0.16), Color(0.25, 1, 0.45))
	spectator["leave_button"].visible = false
	($LobbyPage/Title as Label).text = "SALA: Sala de Treino do IFPB"
	$LobbyPage/BackToSetupButton.text = "VOLTAR À LISTA"
	_update_ready_count()
	_set_visible_page(_lobby_page)


func _watch_running_server() -> void:
	# O botão ASSISTIR abre uma batalha local normal apenas para demonstrar o fluxo.
	test_match_requested.emit("Jogador 1", "Equipe azul", "Jogador 2", "Equipe vermelha")


func get_server_name() -> String:
	var value := _server_name.text.strip_edges()
	return value if not value.is_empty() else "Servidor Local"


func show_discovered_servers(servers: Array) -> void:
	var previous_address := ""
	if _server_address.selected >= 0:
		previous_address = str(_server_address.get_item_metadata(_server_address.selected))
	_server_address.clear()
	for server in servers:
		var label := "%s  •  %d jogador(es)" % [str(server.name), int(server.players)]
		_server_address.add_item(label)
		_server_address.set_item_metadata(_server_address.item_count - 1, str(server.address))
		if str(server.address) == previous_address:
			_server_address.select(_server_address.item_count - 1)
	if _server_address.item_count > 0 and _server_address.selected < 0:
		_server_address.select(0)


func set_network_status(connected: bool, message: String) -> void:
	_status_label.text = message
	if connected and _lobby_flow == "network_join_pending":
		_lobby_flow = "network"
		$LobbyPage/BackToSetupButton.text = "DESCONECTAR"
		_set_visible_page(_lobby_page)
	elif not connected and _lobby_flow == "network_join_pending":
		$IdentityPage/IdentityPanel/Content/Status.text = message


func show_network_lobby() -> void:
	_lobby_flow = "network"
	$LobbyPage/BackToSetupButton.text = "ENCERRAR SALA"
	_set_visible_page(_lobby_page)


func apply_network_lobby(players: Array) -> void:
	if _lobby_flow != "network":
		return
	_reset_lobby_slots()
	var local_id := multiplayer.get_unique_id()
	_claimed_slot = -1
	for item in players:
		var role := int(item.get("role", -1))
		if role < 0 or role >= 3:
			continue
		var slot := _slot(role)
		slot.occupied = true
		slot.ready = bool(item.ready)
		slot.name_label.text = str(item.name)
		slot.team_label.text = str(item.team)
		slot.join_button.visible = false
		slot.ready_button.visible = true
		slot.leave_button.visible = int(item.id) == local_id and int(item.id) != 1
		slot.ready_button.disabled = int(item.id) != local_id
		slot.ready_button.text = "PRONTO!" if slot.ready else "PRONTO?"
		if int(item.id) == local_id:
			_claimed_slot = role
	_start_button.disabled = not multiplayer.is_server() or not (_slot(0).occupied and _slot(2).occupied)
	_update_ready_count()


func _back_from_identity() -> void:
	if _identity_flow == "host":
		_set_visible_page(_setup_page)
	else:
		show_server_list()


func _set_visible_page(page: Control) -> void:
	_setup_page.visible = page == _setup_page
	_servers_page.visible = page == _servers_page
	_identity_page.visible = page == _identity_page
	_lobby_page.visible = page == _lobby_page
	_focus_pending = true


func _back_to_setup() -> void:
	if _lobby_flow == "join":
		$LobbyPage/BackToSetupButton.text = "VOLTAR ÀS CONFIGURAÇÕES"
		show_server_list()
	else:
		_set_visible_page(_setup_page)


func _reset_lobby_slots() -> void:
	_claimed_slot = -1
	_start_attempted = false
	_start_warning.visible = false
	for slot in _slots:
		slot["occupied"] = false
		slot["ready"] = false
		slot["name_label"].text = "Aguardando jogador"
		slot["team_label"].text = "Equipe —"
		slot["join_button"].visible = true
		slot["ready_button"].visible = false
		slot["ready_button"].disabled = false
		slot["ready_button"].text = "PRONTO?"
		_style_button(slot["ready_button"], Color(0.42, 0.12, 0.12), Color(1, 0.3, 0.28))
		slot["leave_button"].visible = false
	_update_ready_count()


func _fill_question_banks() -> void:
	_bank_option.clear()
	_bank_option.add_item("Banco padrão do jogo")
	_bank_option.set_item_metadata(0, "")
	var directory := DirAccess.open("user://question_banks")
	if directory == null:
		return
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.get_extension().to_lower() == "json":
			var file := FileAccess.open("user://question_banks/%s" % filename, FileAccess.READ)
			if file:
				var data: Variant = JSON.parse_string(file.get_as_text())
				if data is Dictionary and data.get("questions") is Array:
					_bank_option.add_item(str(data.get("name", filename.get_basename())))
					_bank_option.set_item_metadata(_bank_option.item_count - 1, filename)
		filename = directory.get_next()
	bank_option_select_active()
	directory.list_dir_end()


func bank_option_select_active() -> void:
	if not FileAccess.file_exists("user://question_banks/active_bank.cfg"):
		return
	var file := FileAccess.open("user://question_banks/active_bank.cfg", FileAccess.READ)
	if file == null:
		return
	var active := file.get_as_text().strip_edges()
	for index in _bank_option.item_count:
		if str(_bank_option.get_item_metadata(index)) == active and not active.is_empty():
			_bank_option.select(index)
			return


func _style_input(control: Control) -> void:
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_stylebox_override("normal", _button_style(Color(0.025, 0.07, 0.09), Color(0.25, 0.5, 0.58)))
	control.add_theme_stylebox_override("hover", _button_style(Color(0.04, 0.11, 0.14), Color(0.35, 0.75, 1)))


func _toggle_timer() -> void:
	_timer_enabled = not _timer_enabled
	_update_timer_toggle()


func _update_timer_toggle() -> void:
	_timer_toggle.text = "◀  1 MINUTO  ▶" if _timer_enabled else "◀  DESATIVADO  ▶"
	_style_button(_timer_toggle, Color(0.08, 0.3, 0.2) if _timer_enabled else Color(0.025, 0.07, 0.09), Color(0.3, 1, 0.6) if _timer_enabled else Color(0.25, 0.5, 0.58))


func _toggle_fatality() -> void:
	_fatality_enabled = not _fatality_enabled
	_update_fatality_toggle()


func _update_fatality_toggle() -> void:
	_fatality_toggle.text = "◀  ATIVADA  ▶" if _fatality_enabled else "◀  DESATIVADA  ▶"
	_style_button(_fatality_toggle, Color(0.08, 0.3, 0.2) if _fatality_enabled else Color(0.025, 0.07, 0.09), Color(0.3, 1, 0.6) if _fatality_enabled else Color(0.25, 0.5, 0.58))


func is_question_timer_enabled() -> bool:
	return _timer_enabled


func is_kick_fatality_enabled() -> bool:
	return _fatality_enabled


func _cycle_professor() -> void:
	# Damien é o único professor disponível neste momento.
	_professor_toggle.text = "◀  PROFESSOR DAMINÓ (MONTEIRO)  ▶"


func _style_button(button: Button, fill: Color, border: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(fill, border))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.12), border))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.08), border))
	button.add_theme_stylebox_override("disabled", _button_style(fill.darkened(0.2), border.darkened(0.2)))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	return style


func _refresh_focus_controls() -> void:
	_focus_controls.clear()
	var page: Control = _setup_page
	if _servers_page.visible:
		page = _servers_page
	elif _identity_page.visible:
		page = _identity_page
	elif _lobby_page.visible:
		page = _lobby_page
	_collect_focusable(page)
	_focus_index = clampi(_focus_index, 0, maxi(_focus_controls.size() - 1, 0))
	if not _focus_controls.is_empty():
		_focus_controls[_focus_index].grab_focus()


func _collect_focusable(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if control != self and control.focus_mode != Control.FOCUS_NONE and control.visible:
			_focus_controls.append(control)
	for child in node.get_children():
		_collect_focusable(child)
