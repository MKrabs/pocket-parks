class_name Net
extends Node
# Local network (docs/design/game.md → Decided: networking). Hosts our park over ENet, finds nearby parks by UDP
# broadcast, and mirrors one visited park live. Host and visit are two separate ENet peers polled by hand, so neither
# touches the tree's MultiplayerAPI. Wire: plain Dictionaries through var_to_bytes, reliable.
#   map  {t, map: {buildings, levels, rotations}}   once on connect, again whenever the layout changes
#   live {t, tick, guests, staff, builders, jobs, litter, closed, events}   about 10×/s
#   ledger {t, from, seq, owed, blueprints, inside}   host → one visitor, whenever its entry in sim.ledger changes.
#        owed and blueprints are running totals; the visitor applies owed minus what it already got from `from`, and
#        only for a seq newer than the last one it applied, so a replay or a reconnect never pays twice.
#        live also carries avatars [name, color, pos, walking]: every character in the host's park, its own included.
# Announce: {id, name (park), player, nick, colour, port, theme}; nick and colour are optional (older copies).
# Visitor → host: hello {t, player, nick, colour, color, level} once connected (the host adds its avatar), send
# {t, kind, level} per person (the host runs sim.send_paid: refused at the send limit, otherwise the price comes off the
# ledger; `inside` carries the limit), move {t, cell} to walk its avatar there, crime {t, kind} to strike in person,
# say {t, text} to talk. A visitor's avatar leaves when it disconnects. A blacklisted visitor gets no avatar; `inside`
# carries banned (days left, 0 = not). Host → every visitor: say {t, name, color, text}, any line said in its park.
# Everything is keyed by `player` (the stable id: ledgers, avatars, bans); the chosen nick is only a label.

signal map_changed  # the visited park's layout arrived or changed: rebuild its ZooView
signal lost         # the visited park went away (host closed, or never answered)
signal joined       # the park we join() answered (we sent our hello)
signal stolen(ids: Array)  # blueprints our spies brought home from the visited park (running list, may repeat)
signal said(name: String, color: Color, text: String, home: bool)  # a chat line; home = said in our own park

const GAME_PORT := 24610   # ENet: first free of GAME_PORT .. +19
const DISCO_PORT := 24600  # UDP: listen on the first free of DISCO_PORT .. +9, announce to all ten
const DISCO_PORTS := 10
const ANNOUNCE_EVERY := 2.0
const FORGET_AFTER := 6.0
const LIVE_EVERY := 0.1
const SAY_MAX := 80  # chat line length
const CONNECT_TIMEOUT_MS := 4000  # join(): an address that never answers is dropped (lost) after about this long

var park_name := "Pocket Zoo"
var player := ""   # stable id: the key other parks' ledgers use; never shown once a nick is chosen
var nick := ""     # the name you chose (IdentityCard); "" until then
var colour := "SKY"  # an IdentityCard.COLOURS key
var color: Color:  # our character's colour, from `colour`
	get: return IdentityCard.colour_of(colour)
var level := 1      # our park level, told to hosts in hello and each send (send limit = 3 + level)
var theme := "zoo"
var sim: ParkSim  # our park, as visitors see it
var map: ParkMap
var port := 0       # our ENet server port (0 = not hosting)
var udp_port := 0   # our discovery port (0 = not listening)
var nearby: Dictionary = {}  # announcer id -> {name, player, colour, port, theme, ip, seen (s)}; player = their nick
var visit_map: ParkMap  # mirror of the park we are visiting (null when home)
var visit_sim: ParkSim  # only ever written from the wire, never stepped
var visit_ledger := {}  # sim.sent_by(us) in the park we visit, for the Send panel
var seq := 0            # host: ledger messages ever sent (saved, so a restart never reuses a number)
var got := {}           # visitor: host player -> {seq, owed} last applied (saved)
var _names := {}        # host: visitor peer -> its player id (from hello): the ledger key
var _shown := {}        # host: visitor peer -> the name its character and chat lines show (nick, else id)
var _told := {}         # host: visitor peer -> the [owed, blueprints, inside] last sent to it
var _hello := false
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
	_host.peer_disconnected.connect(func(peer: int) -> void:
		_visitors -= 1
		if sim and _shown.has(peer):
			sim.leave_avatar(_names[peer])
		_shown.erase(peer)
		_names.erase(peer)  # their people stay in the park; the ledger waits for the next visit
		_told.erase(peer))
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
			var from := _host.get_packet_peer()
			var m: Variant = bytes_to_var(_host.get_packet())
			if m is Dictionary:
				_hear(from, m)
		_tell()
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
	var msg := var_to_bytes({"id": _id, "name": park_name, "player": player, "nick": nick, "colour": colour, "port": port,
		"theme": theme})
	for ip in ["255.255.255.255", "127.0.0.1"] + Net.broadcasts(IP.get_local_addresses()):
		for p in range(DISCO_PORT, DISCO_PORT + DISCO_PORTS):
			_udp.set_dest_address(ip, p)
			_udp.put_packet(msg)

func _listen() -> void:
	while _udp.get_available_packet_count() > 0:
		var d: Variant = bytes_to_var(_udp.get_packet())
		var ip := _udp.get_packet_ip()
		if not d is Dictionary or not d.has_all(["id", "name", "player", "port", "theme"]) or d["id"] == _id:
			continue
		var who := str(d.get("nick", ""))
		nearby[d["id"]] = {"name": str(d["name"]), "player": who if who != "" else str(d["player"]),
			"colour": str(d.get("colour", "SKY")), "port": int(d["port"]), "theme": str(d["theme"]), "ip": ip, "seen": _time}

## Nearby parks as picker offers (by player name), each with live = true.
func offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k: String in nearby:
		var n: Dictionary = nearby[k]
		out.append({"name": n["name"], "player": n["player"], "colour": n["colour"], "theme": n["theme"], "ip": n["ip"], "port": n["port"], "live": true})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["player"] < b["player"])
	return out

## Directed broadcast for each private IPv4 we have (a.b.c.255). Some systems don't send 255.255.255.255 out of the
## Wi-Fi when there are other interfaces (VPN, Docker bridges); the subnet address does reach it.
## ponytail: assumes /24 networks, which home Wi-Fi almost always is. Read real netmasks if a /16 LAN shows up.
static func broadcasts(addrs: PackedStringArray) -> Array[String]:
	var out: Array[String] = []
	for a in addrs:
		var q := a.split(".")
		if q.size() != 4 or not a.is_valid_ip_address():
			continue
		var private := q[0] == "192" and q[1] == "168" or q[0] == "10" or q[0] == "172" and int(q[1]) in range(16, 32)
		var b := "%s.%s.%s.255" % [q[0], q[1], q[2]]
		if private and not b in out:
			out.append(b)
	return out

## "192.168.1.23" or "192.168.1.23:24611" -> {ip, port} (default GAME_PORT); {} if it isn't an IPv4 address.
static func parse_address(text: String) -> Dictionary:
	var parts := text.strip_edges().split(":")
	var ip := parts[0]
	if parts.size() > 2 or not ip.is_valid_ip_address() or ip.count(".") != 3:
		return {}
	if parts.size() == 1:
		return {"ip": ip, "port": GAME_PORT}
	if not parts[1].is_valid_int() or int(parts[1]) < 1 or int(parts[1]) > 65535:
		return {}
	return {"ip": ip, "port": int(parts[1])}

## The address a friend types to reach us: first private IPv4 (192.168.*, then 10.*, then 172.16–31.*), "" if none.
static func local_address(addrs: PackedStringArray) -> String:
	for prefix: String in ["192.168.", "10.", "172."]:
		for a in addrs:
			if a.begins_with(prefix) and (prefix != "172." or int(a.split(".")[1]) in range(16, 32)):
				return a
	return ""

## Connect to a park; visit_map / visit_sim fill in as its state arrives. False if the socket can't open.
func join(ip: String, game_port: int) -> bool:
	leave()
	_client = ENetMultiplayerPeer.new()
	if _client.create_client(ip, game_port) != OK:
		_client = null
		return false
	_client.host.get_peers()[0].set_timeout(0, CONNECT_TIMEOUT_MS, CONNECT_TIMEOUT_MS)  # give up on a dead address fast
	visit_map = ParkMap.new()
	visit_sim = ParkSim.new(visit_map, 0)
	visit_ledger = {"guests": 0, "hidden": 0, "wanted": 0, "earned": 0, "fines": 0, "limit": ParkSim.SEND_BASE + level, "banned": 0}
	return true

## Send one person of `kind` into the park we visit; the host charges it through our ledger, or refuses it at our
## send limit (free). False until the host has heard our hello.
func send_person(kind: String) -> bool:
	if not _hello:
		return false
	_send(_client, 1, {"t": "send", "kind": kind, "level": level})
	return true

## Walk our character in the park we visit to `cell` (the host paths it). False until the host has heard our hello.
func move_avatar(cell: Vector2i) -> bool:
	if not _hello:
		return false
	_send(_client, 1, {"t": "move", "cell": cell})
	return true

## Say a line in the park we're in: the visited host relays it to everyone there (us included), at home it shows in
## our park and goes to our visitors. False for an empty line, or a visited park that hasn't heard our hello yet.
func say(text: String) -> bool:
	text = text.strip_edges().left(SAY_MAX)
	if text == "" or _client and not _hello:
		return false
	if _client:
		_send(_client, 1, {"t": "say", "text": text})
	else:
		_say(shown(), color, text)
	return true

## Host: a line said in our park, shown here and sent to every visitor.
func _say(name: String, c: Color, text: String) -> void:
	said.emit(name, c, text, true)
	if _visitors > 0:
		_send(_host, 0, {"t": "say", "name": name, "color": c, "text": text})

## Our character does `kind` (ParkSim.CRIMES) at the building beside it; the host checks it can. False until hello.
func strike(kind: String) -> bool:
	if not _hello:
		return false
	_send(_client, 1, {"t": "crime", "kind": kind})
	return true

## What the save keeps of us: our id (the sender id in other parks), who we chose to be, the host seq and what we
## were paid.
func state() -> Dictionary:
	return {"player": player, "nick": nick, "park": park_name, "colour": colour, "seq": seq, "got": got}

## The name others see: the chosen nick, else the id.
func shown() -> String:
	return nick if nick != "" else player

## Before start(): pick up a saved state().
func load_state(d: Dictionary) -> void:
	player = str(d.get("player", ""))
	nick = str(d.get("nick", ""))  # optional keys: saves from before SOC1 load without them
	park_name = str(d.get("park", park_name))
	colour = str(d.get("colour", colour))
	seq = int(d.get("seq", 0))
	got = d.get("got", {})

func leave() -> void:
	if _client:
		_client.close()
	_client = null
	_hello = false
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
	if status == MultiplayerPeer.CONNECTION_CONNECTED and not _hello:
		_hello = true
		_send(_client, 1, {"t": "hello", "player": player, "nick": nick, "colour": colour, "color": color, "level": level})
		_client.get_peer(1).set_timeout(0, 5000, 30000)  # ENet's defaults again, once connected
		joined.emit()
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

## Only what the views draw: guests [id, kind, pos, state, mood, wanted], staff [kind, pos, walking, level].
func _live_msg() -> Dictionary:
	var robbed := sim.events.filter(func(e: Dictionary) -> bool:
		return e["kind"] == "robbed" and sim.tick - e["tick"] < ParkSim.ROBBED_TICKS)
	return {"t": "live", "tick": sim.tick,
		"guests": sim.guests.map(func(g: Dictionary) -> Array:
			return [g["id"], g["kind"], g["pos"], g["state"], snappedf(g["mood"], 1.0), g["wanted"]]),
		"staff": sim.staff.map(func(s: Dictionary) -> Array: return [s["kind"], s["pos"], not s["path"].is_empty(), s["level"]]),
		"builders": sim.builders, "jobs": sim.jobs, "litter": sim.litter, "closed": sim.closed, "events": robbed,
		"avatars": sim.avatars.map(func(a: Dictionary) -> Array:
			return [a["name"], a["color"], a["pos"], not a["path"].is_empty(), a.get("strike", 0) > 0, a.get("label", a["name"])])}

## Host: a message from visitor `peer`.
func _hear(peer: int, m: Dictionary) -> void:
	if m.get("t") == "hello":
		_names[peer] = str(m.get("player", ""))
		var nk := str(m.get("nick", "")).strip_edges()
		_shown[peer] = nk if nk != "" else _names[peer]
		if sim:
			sim.join_avatar(_names[peer], m["color"] if m.get("color") is Color else IdentityCard.colour_of(str(m.get("colour", "SKY"))), _shown[peer])
			sim.sender_levels[_names[peer]] = clampi(int(m.get("level", 1)), 1, ParkLevel.MAX)
	elif m.get("t") == "send" and _names.has(peer) and sim and m.get("kind") in ParkSim.KINDS:
		sim.send_paid(m["kind"], _names[peer], clampi(int(m.get("level", 1)), 1, ParkLevel.MAX))
	elif m.get("t") == "move" and _names.has(peer) and sim and m.get("cell") is Vector2i:
		sim.move_avatar(_names[peer], m["cell"])
	elif m.get("t") == "crime" and _names.has(peer) and sim:
		sim.avatar_strike(_names[peer], str(m.get("kind", "")))
	elif m.get("t") == "say" and _names.has(peer) and m.get("text") is String:
		var c := Palette.SKY
		for a in sim.avatars if sim else []:
			if a["name"] == _names[peer]:
				c = a["color"]
		var text: String = m["text"].strip_edges().left(SAY_MAX)
		if text != "":
			_say(_shown[peer], c, text)

## Host: each visitor whose ledger entry (or people inside) changed gets its new totals.
func _tell() -> void:
	if not sim:
		return
	for peer: int in _names:
		var who: String = _names[peer]
		var now := [sim.ledger.get(who, 0), sim.blueprints.get(who, []), sim.sent_by(who)]
		if _told.get(peer) == now:
			continue
		_told[peer] = now
		seq += 1
		_send(_host, peer, {"t": "ledger", "from": player, "seq": seq, "owed": now[0], "blueprints": now[1], "inside": now[2]})

func _apply(m: Dictionary) -> void:
	if m.get("t") == "ledger":
		var last: Dictionary = got.get(m["from"], {"seq": 0, "owed": 0})
		if m["seq"] <= last["seq"]:
			return  # a replay, or older than what we applied
		if sim:
			sim.money += m["owed"] - last["owed"]
		got[m["from"]] = {"seq": m["seq"], "owed": m["owed"]}
		visit_ledger = m["inside"]
		stolen.emit(m["blueprints"])
	elif m.get("t") == "map":
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
	elif m.get("t") == "say":
		said.emit(str(m["name"]), m["color"] if m.get("color") is Color else Palette.SKY, str(m["text"]), false)
	elif m.get("t") == "live":
		var s := visit_sim
		s.tick = m["tick"]
		s.guests.assign(m["guests"].map(func(a: Array) -> Dictionary:
			return {"id": a[0], "kind": a[1], "pos": a[2], "cell": Vector2i(a[2].round()), "state": a[3], "mood": a[4],
				"wanted": a[5], "sender": ""}))
		s.staff.assign(m["staff"].map(func(a: Array) -> Dictionary:
			return {"kind": a[0], "pos": a[1], "cell": Vector2i(a[1].round()), "path": [0] if a[2] else [], "level": a[3]}))
		s.builders.assign(m["builders"])
		s.jobs.assign(m["jobs"])
		s.litter = m["litter"]
		s.closed = m["closed"]
		s.events = m["events"]
		s.avatars.assign(m.get("avatars", []).map(func(a: Array) -> Dictionary:
			return {"name": a[0], "label": a[5] if a.size() > 5 else a[0], "color": a[1], "pos": a[2],
				"cell": Vector2i(a[2].round()), "path": [0] if a[3] else [], "strike": 1 if a.size() > 4 and a[4] else 0}))
