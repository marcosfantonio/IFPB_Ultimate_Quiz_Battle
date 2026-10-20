extends Node
## Transporte ENet e sincronização autoritativa do lobby LAN.

signal connection_changed(connected: bool, message: String)
signal lobby_changed(players: Array)
signal match_started(players: Array)
signal servers_discovered(servers: Array)

const DEFAULT_PORT := 28741
const MAX_CLIENTS := 8
const DISCOVERY_PORT := 28742
const DISCOVERY_INTERVAL := 2.5

var peer: ENetMultiplayerPeer
var is_host := false
var server_name := "Servidor Local"
var lobby_players: Dictionary = {}
var _local_player: Dictionary = {}
var _discovery_socket := PacketPeerUDP.new()
var _discovery_timer := 0.0
var _discovery_running := false
var _known_servers: Dictionary = {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if not _discovery_running:
		return
	_discovery_timer -= delta
	if _discovery_timer <= 0.0:
		_discovery_timer = DISCOVERY_INTERVAL
		_send_discovery_query()
	_poll_discovery()


func host(name: String, player_name: String, team_name: String, port := DEFAULT_PORT) -> Error:
	close()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		peer = null
		connection_changed.emit(false, "Não foi possível abrir a porta UDP %d (erro %d)." % [port, error])
		return error
	multiplayer.multiplayer_peer = peer
	is_host = true
	server_name = name
	_start_discovery_responder()
	_local_player = {"name": _clean(player_name), "team": _clean(team_name), "ready": false, "role": -1}
	lobby_players[1] = _local_player.duplicate(true)
	_publish_lobby()
	connection_changed.emit(true, "Servidor ativo na porta UDP %d. Compartilhe seu IP com os jogadores." % port)
	return OK


func join(address: String, player_name: String, team_name: String, port := DEFAULT_PORT) -> Error:
	close()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port)
	if error != OK:
		peer = null
		connection_changed.emit(false, "Não foi possível conectar ao servidor (erro %d)." % error)
		return error
	multiplayer.multiplayer_peer = peer
	stop_discovery()
	is_host = false
	_local_player = {"name": _clean(player_name), "team": _clean(team_name), "ready": false, "role": -1}
	return OK


func close() -> void:
	stop_discovery()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	is_host = false
	lobby_players.clear()


func start_discovery() -> void:
	stop_discovery()
	var error := _discovery_socket.bind(DISCOVERY_PORT, "0.0.0.0", true)
	if error != OK:
		servers_discovered.emit([])
		connection_changed.emit(false, "Não foi possível iniciar descoberta UDP (porta %d, erro %d)." % [DISCOVERY_PORT, error])
		return
	_discovery_socket.set_broadcast_enabled(true)
	_discovery_running = true
	_discovery_timer = 0.0
	_known_servers.clear()
	servers_discovered.emit([])


func stop_discovery() -> void:
	_discovery_running = false
	if _discovery_socket.is_bound():
		_discovery_socket.close()


func _start_discovery_responder() -> void:
	stop_discovery()
	var error := _discovery_socket.bind(DISCOVERY_PORT, "0.0.0.0", true)
	if error != OK:
		connection_changed.emit(false, "Sala criada, mas a descoberta automática não iniciou (erro %d)." % error)
		return
	_discovery_socket.set_broadcast_enabled(true)
	_discovery_running = true
	_discovery_timer = DISCOVERY_INTERVAL


func _send_discovery_query() -> void:
	if is_host:
		return
	_discovery_socket.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	_discovery_socket.put_packet("IFPB_QUIZ_DISCOVER_V1".to_utf8_buffer())


func _poll_discovery() -> void:
	while _discovery_socket.get_available_packet_count() > 0:
		var packet := _discovery_socket.get_packet().get_string_from_utf8()
		var sender := _discovery_socket.get_packet_ip()
		var sender_port := _discovery_socket.get_packet_port()
		if is_host and packet == "IFPB_QUIZ_DISCOVER_V1":
			var response := JSON.stringify({"protocol": 1, "name": server_name, "port": DEFAULT_PORT, "players": lobby_players.size()})
			_discovery_socket.set_dest_address(sender, sender_port)
			_discovery_socket.put_packet(response.to_utf8_buffer())
		elif not is_host:
			var parsed: Variant = JSON.parse_string(packet)
			if parsed is Dictionary and int(parsed.get("protocol", 0)) == 1:
				_known_servers[sender] = {"name": str(parsed.get("name", "Servidor LAN")), "address": sender, "port": int(parsed.get("port", DEFAULT_PORT)), "players": int(parsed.get("players", 0))}
				servers_discovered.emit(_known_servers.values())


func claim_role(role: int) -> void:
	if role < 0 or role > 2:
		return
	if is_host:
		_set_role(1, role)
	else:
		_request_role.rpc_id(1, role)


func set_ready(ready: bool) -> void:
	if is_host:
		_set_ready(1, ready)
	else:
		_request_ready.rpc_id(1, ready)


func request_start() -> void:
	if is_host:
		_start_if_ready()
	else:
		_request_start.rpc_id(1)


func _on_peer_connected(id: int) -> void:
	if is_host:
		# New peer receives a snapshot after identifying itself.
		pass


func _on_peer_disconnected(id: int) -> void:
	if not is_host:
		return
	lobby_players.erase(id)
	_publish_lobby()


func _on_connected() -> void:
	connection_changed.emit(true, "Conectado. Sincronizando sala…")
	_register_player.rpc_id(1, _local_player)


func _on_connection_failed() -> void:
	connection_changed.emit(false, "Conexão recusada ou servidor indisponível.")
	close()


func _on_server_disconnected() -> void:
	connection_changed.emit(false, "O servidor encerrou a conexão.")
	close()


@rpc("any_peer", "reliable")
func _register_player(data: Dictionary) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	if lobby_players.size() >= MAX_CLIENTS + 1:
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	var player := {"name": _clean(str(data.get("name", "Jogador"))), "team": _clean(str(data.get("team", "Equipe"))), "ready": false, "role": -1}
	lobby_players[id] = player
	_publish_lobby()


@rpc("any_peer", "reliable")
func _request_role(role: int) -> void:
	if is_host:
		_set_role(multiplayer.get_remote_sender_id(), role)


@rpc("any_peer", "reliable")
func _request_ready(ready: bool) -> void:
	if is_host:
		_set_ready(multiplayer.get_remote_sender_id(), ready)


@rpc("any_peer", "reliable")
func _request_start() -> void:
	if is_host and multiplayer.get_remote_sender_id() == 0:
		_start_if_ready()


func _set_role(id: int, role: int) -> void:
	if role < 0 or role > 2 or not lobby_players.has(id):
		return
	for player_id in lobby_players:
		if int(player_id) != id and int(lobby_players[player_id].role) == role:
			return
	lobby_players[id].role = role
	lobby_players[id].ready = false
	_publish_lobby()


func _set_ready(id: int, ready: bool) -> void:
	if not lobby_players.has(id) or int(lobby_players[id].role) < 0:
		return
	lobby_players[id].ready = ready
	_publish_lobby()


func _publish_lobby() -> void:
	var snapshot: Array = []
	for id in lobby_players:
		snapshot.append({"id": int(id), "name": lobby_players[id].name, "team": lobby_players[id].team, "ready": lobby_players[id].ready, "role": lobby_players[id].role})
	_receive_lobby(snapshot)
	if multiplayer.multiplayer_peer != null:
		_receive_lobby.rpc(snapshot)


@rpc("authority", "call_local", "reliable")
func _receive_lobby(players: Array) -> void:
	lobby_changed.emit(players)


func _start_if_ready() -> void:
	var roles := {}
	for player in lobby_players.values():
		if int(player.role) >= 0:
			roles[int(player.role)] = player
	if not roles.has(0) or not roles.has(2) or not roles[0].ready or not roles[2].ready:
		return
	var payload := [roles[0].name, roles[0].team, roles[2].name, roles[2].team]
	_receive_start(payload)
	_receive_start.rpc(payload)


@rpc("authority", "call_local", "reliable")
func _receive_start(players: Array) -> void:
	match_started.emit(players)


func _clean(value: String) -> String:
	var result := value.strip_edges().substr(0, 32)
	return result if not result.is_empty() else "Jogador"
