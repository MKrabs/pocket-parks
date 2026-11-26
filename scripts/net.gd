class_name Net
extends Node
# Local network (docs/design/game.md → Decided: networking). Hosts our park over ENet, finds nearby parks by UDP
# broadcast, and mirrors one visited park live. Host and visit are two separate ENet peers polled by hand, so neither
# touches the tree's MultiplayerAPI. Wire: plain Dictionaries through var_to_bytes, reliable.
#   map  {t, map: {buildings, levels, rotations}}   once on connect, again whenever the layout changes
#   live {t, tick, guests, staff, builders, jobs, litter, closed, events}   about 10×/s

signal map_changed  # the visited park's layout arrived or changed: rebuild its ZooView
signal lost         # the visited park went away (host closed, or never answered)

const GAME_PORT := 24610   # ENet: first free of GAME_PORT .. +19
const DISCO_PORT := 24600  # UDP: listen on the first free of DISCO_PORT .. +9, announce to all ten
const DISCO_PORTS := 10
const ANNOUNCE_EVERY := 2.0
const FORGET_AFTER := 6.0
const LIVE_EVERY := 0.1

var park_name := "Pocket Zoo"
var player := ""
var theme := "zoo"
var sim: ParkSim  # our park, as visitors see it
var map: ParkMap
var port := 0       # our ENet server port (0 = not hosting)
var udp_port := 0   # our discovery port (0 = not listening)
var nearby: Dictionary = {}  # announcer id -> {name, player, port, theme, ip, seen (s)}
var visit_map: ParkMap  # mirror of the park we are visiting (null when home)
var visit_sim: ParkSim  # only ever written from the wire, never stepped
var _id := ""
var _time := 0.0
var _announce_in := 0.0
var _live_in := 0.0
var _host := ENetMultiplayerPeer.new()
var _visitors := 0
var _sent_map := PackedByteArray()
var _udp := PacketPeerUDP.new()
var _client: ENetMultiplayerPeer

func _ready() -> void:
	start()

func _process(delta: float) -> void:
	poll(delta)

func _exit_tree() -> void:
	leave()
	_host.close()
	_udp.close()

## Host on the first free game port and listen on the first free discovery port.
func start() -> void:
	if player == "":
		var user := OS.get_environment("USER")
		player = "%s%02d" % [user if user != "" else OS.get_environment("USERNAME"), randi_range(10, 99)]
	_id = "%s-%d" % [player, randi()]
	for p in range(GAME_PORT, GAME_PORT + 20):
		var probe := PacketPeerUDP.new()  # quiet test first: ENet logs an error for a taken port
		var free := probe.bind(p) == OK
		probe.close()
		if free and _host.create_server(p) == OK:
			port = p
			break
	_host.peer_connected.connect(func(peer: int) -> void:
		_visitors += 1
		_send(_host, peer, _map_msg()))
	_host.peer_disconnected.connect(func(_peer: int) -> void: _visitors -= 1)
	for p in range(DISCO_PORT, DISCO_PORT + DISCO_PORTS):
		if _udp.bind(p) == OK:
			udp_port = p
			break
	_udp.set_broadcast_enabled(true)

## One network step; `delta` in seconds.
func poll(delta: float) -> void:
	_time += delta
	if port > 0:
		_host.poll()
		while _host.get_available_packet_count() > 0:
			_host.get_packet()  # ponytail: visitors are read-only for now (NET1 sends people)
	_listen()
	_announce_in -= delta
	if _announce_in <= 0.0:
		_announce_in = ANNOUNCE_EVERY
		announce()
	for k: String in nearby.keys():
		if _time - nearby[k]["seen"] > FORGET_AFTER:
			nearby.erase(k)
	_live_in -= delta
	if _live_in <= 0.0 and _visitors > 0 and sim:
		_live_in = LIVE_EVERY
		var m := _map_msg()
		var bytes := var_to_bytes(m)
		if bytes != _sent_map:
			_send(_host, 0, m)
		_send(_host, 0, _live_msg())
	_poll_client()

## Tell every discovery port, on the LAN and on this machine, that our park is here.
func announce() -> void:
	if port == 0:
		return
	var msg := var_to_bytes({"id": _id, "name": park_name, "player": player, "port": port, "theme": theme})
	for ip in ["255.255.255.255", "127.0.0.1"]:
		for p in range(DISCO_PORT, DISCO_PORT + DISCO_PORTS):
			_udp.set_dest_address(ip, p)
			_udp.put_packet(msg)

func _listen() -> void:
	while _udp.get_available_packet_count() > 0:
		var d: Variant = bytes_to_var(_udp.get_packet())
		var ip := _udp.get_packet_ip()
		if not d is Dictionary or not d.has_all(["id", "name", "player", "port", "theme"]) or d["id"] == _id:
			continue
		nearby[d["id"]] = {"name": str(d["name"]), "player": str(d["player"]), "port": int(d["port"]),
			"theme": str(d["theme"]), "ip": ip, "seen": _time}

## Nearby parks as picker offers (by player name), each with live = true.
func offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k: String in nearby:
		var n: Dictionary = nearby[k]
		out.append({"name": n["name"], "player": n["player"], "theme": n["theme"], "ip": n["ip"], "port": n["port"], "live": true})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["player"] < b["player"])
	return out

## Connect to a park; visit_map / visit_sim fill in as its state arrives. False if the socket can't open.
func join(ip: String, game_port: int) -> bool:
	leave()
	_client = ENetMultiplayerPeer.new()
	if _client.create_client(ip, game_port) != OK:
		_client = null
		return false
	visit_map = ParkMap.new()
	visit_sim = ParkSim.new(visit_map, 0)
	return true

func leave() -> void:
	if _client:
		_client.close()
	_client = null
	visit_map = null
	visit_sim = null

func _poll_client() -> void:
	if not _client:
		return
	_client.poll()
	var status := _client.get_connection_status()
	if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		leave()
		lost.emit()
		return
	while _client and _client.get_available_packet_count() > 0:
		var m: Variant = bytes_to_var(_client.get_packet())
		if m is Dictionary:
			_apply(m)

func _send(peer: ENetMultiplayerPeer, to: int, msg: Dictionary) -> void:
	var bytes := var_to_bytes(msg)
	if msg["t"] == "map":
		_sent_map = bytes
	peer.set_target_peer(to)
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.put_packet(bytes)

func _map_msg() -> Dictionary:
	return {"t": "map", "map": {"buildings": map.buildings, "levels": map.levels, "rotations": map.rotations}}

## Only what the views draw: guests [id, kind, pos, state, mood, wanted], staff [kind, pos, walking].
func _live_msg() -> Dictionary:
	var robbed := sim.events.filter(func(e: Dictionary) -> bool:
		return e["kind"] == "robbed" and sim.tick - e["tick"] < ParkSim.ROBBED_TICKS)
	return {"t": "live", "tick": sim.tick,
		"guests": sim.guests.map(func(g: Dictionary) -> Array:
			return [g["id"], g["kind"], g["pos"], g["state"], snappedf(g["mood"], 1.0), g["wanted"]]),
		"staff": sim.staff.map(func(s: Dictionary) -> Array: return [s["kind"], s["pos"], not s["path"].is_empty()]),
		"builders": sim.builders, "jobs": sim.jobs, "litter": sim.litter, "closed": sim.closed, "events": robbed}

func _apply(m: Dictionary) -> void:
	if m.get("t") == "map":
		var d: Dictionary = m["map"]
		visit_map.buildings.clear()
		visit_map.occupied.clear()
		visit_map.levels = d["levels"]
		visit_map.rotations = d["rotations"]
		for o: Vector2i in d["buildings"]:
			if not Buildings.get_def(d["buildings"][o]).is_empty():  # a building this copy doesn't know is skipped
				visit_map.buildings[o] = d["buildings"][o]
				for c in visit_map.cells(o):
					visit_map.occupied[c] = o
		visit_sim.guests.clear()  # the next live message brings them back; load_map would re-route them
		visit_sim.staff.clear()
		visit_sim.load_map(visit_map)
		map_changed.emit()
	elif m.get("t") == "live":
		var s := visit_sim
		s.tick = m["tick"]
		s.guests.assign(m["guests"].map(func(a: Array) -> Dictionary:
			return {"id": a[0], "kind": a[1], "pos": a[2], "cell": Vector2i(a[2].round()), "state": a[3], "mood": a[4],
				"wanted": a[5], "sender": ""}))
		s.staff.assign(m["staff"].map(func(a: Array) -> Dictionary:
			return {"kind": a[0], "pos": a[1], "cell": Vector2i(a[1].round()), "path": [0] if a[2] else []}))
		s.builders.assign(m["builders"])
		s.jobs.assign(m["jobs"])
		s.litter = m["litter"]
		s.closed = m["closed"]
		s.events = m["events"]
