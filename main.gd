extends Node2D
# Entry point. Build child nodes in code here; keep main.tscn as the only scene file.

# Inside the owned 12×12 start area (cells 4..15). Every attraction and shop touches the path along y=11 from the gate.
const SEED := [
	["zoo_gate", Vector2i(4, 11)], ["enclosure", Vector2i(6, 8)], ["pond", Vector2i(14, 9)], ["snack_stand", Vector2i(12, 12)],
	["snack_stand", Vector2i(9, 12)], ["tree", Vector2i(14, 6)], ["tree", Vector2i(15, 14)], ["tree", Vector2i(7, 15)],
	["tree", Vector2i(11, 15)], ["tree", Vector2i(10, 5)], ["builder_shed", Vector2i(6, 12)],
]
# Bot "friends" stand in for real ones: every SEND_EVERY ticks one sends a mixed group into your park.
const BOTS := ["Mia", "Theo"]
const SEND_EVERY := 30 * ParkSim.TPS
const PICK_RADIUS := 12.0  # screen px around a person for hover and click in Select mode
const PAINT_ROLES := ["path", "decor"]  # stay in place mode after placing (paths, trees); others go back to Select
const AUTOSAVE := 30 * ParkSim.TPS  # sim ticks between saves

var grid := GridView.new()
var bar := BuildBar.new()
var zoo := ZooView.new()
var hud := Hud.new()
var sim: ParkSim
var walkers := WalkerView.new()
var visit_panel := VisitPanel.new()
var offers: Array[Dictionary] = []
var visits: Array[Dictionary] = []  # parks we sent people into: {offer, map, sim, paid}; first = the one on screen
var visiting := false
var _visit_zoo: ZooView
var _visit_walkers: WalkerView
var debug_visit := false  # tests/show_visit.gd: start inside a visit with a few people sent
var pins := PinView.new()
var fx := Feedback.new()
var toasts := CrimeToasts.new()
var cam := IsoCamera.new()
var transition := CloudTransition.new()
var card := InfoCard.new()
var net := Net.new()
var chat := ChatLog.new()
var live := false  # the park on screen is a real one over the network (net.visit_sim), not a bot park
var _joining := {}  # a typed-address offer waiting for its park to answer (we stay home meanwhile)
var bots := true  # bot friends send groups into your park (tests switch them off)
var _acc := 0.0  # sim ticks owed
var _reported := 0  # sim.events already toasted
var _rng := RandomNumberGenerator.new()
var save_path := ""  # set in _ready when this is the real game (not a test, not a ./gd shot)
var _unsaved := 0  # sim ticks since the last save
var follow := true  # F: the camera follows your character while it walks
const FOLLOW_RATE := 3.0  # camera catch-up per second
var _chasing := false

## T cycles the active theme (zoo → festival → cinema); the build bar follows, placed buildings stay.
## Esc leaves place mode, or closes the card in Select mode.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if k.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		chat.open()
	elif k.physical_keycode == KEY_T:
		var ts: Array = Buildings.themes().keys()
		Buildings.use(ts[(ts.find(Buildings.active) + 1) % ts.size()])
		net.theme = Buildings.active
		bar.fill()
	elif k.physical_keycode == KEY_R:
		zoo.rotate_ghost(-1 if k.shift_pressed else 1)
	elif k.physical_keycode == KEY_ESCAPE:
		escape()
	elif k.physical_keycode == KEY_F:
		follow = not follow
	elif k.physical_keycode == KEY_F9:
		hud.confirm_new_park()

## Say a line through our character: a real park's host relays it, a bot park just shows it, at home our net does both.
func say(text: String) -> bool:
	if visiting and not live:
		_hear(net.player, net.color, text.strip_edges().left(Net.SAY_MAX))
		return true
	return net.say(text)

## A line said in the park on screen: a bubble over the speaker and a row in the log.
func _hear(name: String, color: Color, text: String) -> void:
	chat.add(name, color, text)
	(_visit_walkers if visiting else walkers).say(name, text)

func escape() -> void:
	if zoo.selected != "":
		bar.clear()
	else:
		card.close()

## Right-click anywhere on the world cancels place mode.
func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		bar.clear()

func _ready() -> void:
	zoo.map.start_small()
	grid.map = zoo.map
	add_child(grid)
	if get_tree().current_scene == self and not OS.has_feature("movie"):
		save_path = OS.get_environment("PARK_SAVE") if OS.has_environment("PARK_SAVE") else SaveGame.PATH  # a second window on one machine
	var saved := SaveGame.read(save_path) if save_path != "" else {}
	if saved.is_empty():
		_seed()
	else:
		Buildings.use(saved["theme"])
		sim = SaveGame.restore(saved, zoo.map)
		hud.day = saved["day"]
		bar.stolen.assign(saved["stolen"].filter(func(id: Variant) -> bool: return id is String and not Buildings.get_def(id).is_empty()))
		net.load_state(saved.get("net", {}))
	zoo.sim = sim
	_rng.seed = 1
	zoo.money_changed.connect(_on_map_changed)
	add_child(zoo)
	grid.cell_hovered.connect(zoo.on_hover)
	grid.cell_clicked.connect(_on_cell_clicked)

	walkers.sim = sim
	add_child(walkers)
	pins.sim = sim
	pins.map = zoo.map
	pins.cam = cam
	pins.clicked.connect(_on_pin_clicked)
	add_child(pins)
	fx.sim = sim
	fx.zoo = zoo
	fx.walkers = walkers
	fx.hud = hud
	zoo.fx = fx
	add_child(fx)

	bar.picked.connect(func(id: String) -> void:
		zoo.select(id)
		grid.tile_hover = id != ""
		if id != "":
			card.close())
	bar.hire.connect(func(kind: String) -> void: sim.hire(kind))
	bar.map = zoo.map
	add_child(bar)
	card.sim = sim
	card.map = zoo.map
	card.action.connect(_on_card_action)
	add_child(card)
	hud.sim = sim
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	offers = Visit.offers(rng)
	hud.visit_pressed.connect(open_picker)
	hud.new_park.connect(new_park)
	add_child(hud)
	net.sim = sim
	net.map = zoo.map
	net.park_name = hud.park_name.text
	net.theme = Buildings.active
	net.map_changed.connect(func() -> void:
		if live:
			_visit_zoo.rebuild())
	net.lost.connect(func() -> void:
		if live:
			toasts.add("wrecked", "Lost the connection: back home")
			travel_home()
		elif not _joining.is_empty():
			toasts.add("wrecked", "Couldn't reach %s" % _joining["name"])
			_joining = {})
	net.joined.connect(func() -> void:
		if not _joining.is_empty():
			travel_to(_joining)
			_joining = {})
	visit_panel.join_address.connect(join_address)
	net.stolen.connect(_learn)
	net.said.connect(func(name: String, color: Color, text: String, home: bool) -> void:
		if home != visiting:  # lines from our own park while we're away elsewhere aren't for this screen
			_hear(name, color, text))
	chat.typed.connect(say)
	add_child(net)  # net.player is set from here on
	sim.join_avatar(net.player, net.color)
	visit_panel.picked.connect(travel_to)
	visit_panel.sent.connect(send)
	visit_panel.home.connect(travel_home)
	add_child(visit_panel)
	add_child(transition)
	toasts.clicked.connect(func(o: Vector2i) -> void: cam.position = IsoGrid.to_screen(o))
	add_child(toasts)
	add_child(chat)

	# centre of the board top, nudged down by half the slab depth, sized to sit between the two bars
	cam.position = IsoGrid.project(Vector2(IsoGrid.SIZE) / 2.0 - Vector2(0.5, 0.5)) + Vector2(0, GridView.SLAB / 2)
	cam.zoom = Vector2.ONE * 0.74  # the whole 20×20 world, for-sale land included, between the bars
	add_child(cam)

	if debug_visit:
		visit({"name": "Clover Fields", "theme": "festival", "seed": 7, "size": "small", "guards": 1})
		for k: String in ["guest", "guest", "thief", "spy", "litterbug", "guest", "hooligan", "guest", "guest", "guest"]:
			send(k)

## The start park: seeded buildings, free.
func _seed() -> void:
	zoo.map.money = 1 << 30  # seed without running out
	for s in SEED:
		zoo.map.place(s[0], s[1])
	for x in range(5, 16):
		zoo.map.place("path", Vector2i(x, 11))
	zoo.map.money = ParkMap.START_MONEY  # the seeded zoo is free
	sim = ParkSim.new(zoo.map, 1)

## Your park to disk (no-op in tests and shots).
func save() -> void:
	if save_path != "":
		SaveGame.write(save_path, SaveGame.pack(zoo.map, sim, hud.day, bar.stolen, net.state()))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()

## F9, confirmed: forget the saved park and start over from the seeded one in the default theme.
func new_park() -> void:
	if save_path != "":
		DirAccess.remove_absolute(save_path)
	save_path = ""  # this instance must not save the old park on its way out
	Buildings.use("zoo")
	get_tree().reload_current_scene()

func _process(delta: float) -> void:
	_acc += delta * ParkSim.TPS
	while _acc >= 1.0:
		step_world()
		_acc -= 1.0
	zoo.show_wrecked(sim.closed)
	toasts.floor_y = card.top() if card.is_open() else INF
	zoo.map.money = sim.money  # the sim owns money while the day runs; building spends from the map
	zoo.map.xp = sim.xp
	net.level = ParkLevel.of(sim.xp)
	if visiting:
		_visit_zoo.show_wrecked((net.visit_sim.closed if net.visit_sim else {}) if live else visits[0]["sim"].closed)
		visit_panel.show_ledger(_inside(), sim.money)
	else:
		_hover(get_global_mouse_position(), get_viewport().get_mouse_position())
	var me := my_avatar()
	if me.is_empty() or not follow or transition.visible:
		_chasing = false
	elif not me["path"].is_empty() or _chasing:  # keeps easing in after the walk ends
		var at := IsoGrid.project(me["pos"])
		cam.position = cam.position.lerp(at, 1.0 - exp(-FOLLOW_RATE * delta))
		_chasing = not me["path"].is_empty() or cam.position.distance_to(at) > 2.0

## The park on screen: ours, the bot park we visit, or the live mirror (null while it connects).
func here() -> ParkSim:
	return net.visit_sim if live else visits[0]["sim"] if visiting else sim

## Our character in the park on screen, {} if it isn't there (yet).
func my_avatar() -> Dictionary:
	var s := here()
	for a in s.avatars if s else []:
		if a["name"] == net.player:
			return a
	return {}

## Walk our character to `cell` along paths. A real park's host does the walking.
func walk_to(cell: Vector2i) -> bool:
	return net.move_avatar(cell) if live else here().move_avatar(net.player, cell)

## Select mode: lift the person or building under the mouse and name it in the tooltip.
func _hover(world: Vector2, screen: Vector2) -> void:
	var g := person_at(world) if zoo.selected == "" else -1
	var s := staff_at(world) if zoo.selected == "" and g < 0 else -1
	var cell := IsoGrid.to_cell(world)
	var o: Vector2i = zoo.map.occupied.get(cell, GridView.NONE) if zoo.selected == "" and g < 0 and s < 0 else GridView.NONE
	walkers.hovered = g
	walkers.hovered_staff = s
	if o != zoo.lifted:
		zoo.highlight(o)
	var text := ""
	if g >= 0:
		text = InfoCard.guest_title(_guest(g))
	elif s >= 0:
		text = (sim.staff[s]["kind"] as String).capitalize()
	elif o != GridView.NONE:
		text = InfoCard.building_name(zoo.map, o)
	card.hover(text, screen)

func _guest(id: int) -> Dictionary:
	for g in sim.guests:
		if g["id"] == id:
			return g
	return {}

## One world tick: your park (at the HUD speed at home, 1× while away) and every visited park at 1×.
## Money the visited parks owe us (or we owe them) moves into our sim; stolen blueprints join the build bar.
func step_world() -> void:
	advance(1 if visiting else hud.speed)  # your park: bot senders + crime toasts
	sim.step_avatars()  # characters walk at 1×, paused or not
	for v in visits.duplicate():
		var vs: ParkSim = v["sim"]
		vs.step()
		vs.step_avatars()
		if vs.tick >= ParkSim.DAY_TICKS:
			vs.new_day()  # ponytail: bot parks loop their day; our people still inside are dropped
		_collect(v)
		_learn(vs.blueprints.get(Visit.ME, []))
		var t := vs.sent_by(Visit.ME)
		if not (visiting and not live and v == visits[0]) and t["guests"] + t["hidden"] + t["wanted"] == 0:
			visits.erase(v)  # left behind and nobody of ours is inside any more

## Stolen blueprints join the build bar (each id once).
func _learn(ids: Array) -> void:
	var fresh := ids.filter(func(id: Variant) -> bool: return id is String and not id in bar.stolen and not Buildings.get_def(id).is_empty())
	if not fresh.is_empty():
		bar.stolen.append_array(fresh)
		bar.fill()

## visit() behind the cloud transition (the swap happens at full cover).
func travel_to(offer: Dictionary) -> Tween:
	return transition.play(cam, offer["name"], visit.bind(offer), true)

## go_home() behind the cloud transition, clouds rolling the other way.
func travel_home() -> Tween:
	return transition.play(cam, "Home", go_home, false)

## Swap the view to the offer's park (reusing its sim if we were already there). A live offer connects to its game.
func visit(offer: Dictionary) -> void:
	if offer.get("live", false):
		_visit_live(offer)
		return
	var v: Dictionary = {}
	for w in visits:
		if w["offer"]["name"] == offer["name"]:
			v = w
	if v.is_empty():
		var opened := Visit.open(offer)
		v = {"offer": offer, "map": opened[0], "sim": opened[1], "paid": 0}
	visits.erase(v)
	visits.push_front(v)
	visits.resize(mini(visits.size(), Visit.KEEP + 1))  # the visited one + up to KEEP left behind
	_visit_zoo = ZooView.new()
	_visit_zoo.map = v["map"]
	_visit_walkers = WalkerView.new()
	_visit_walkers.sim = v["sim"]
	_visit_walkers.me = Visit.ME
	(v["sim"] as ParkSim).join_avatar(net.player, net.color)
	_enter_visit(offer["name"])

## The Visit picker, with our own address for a friend to type.
func open_picker() -> void:
	visit_panel.source = func() -> Dictionary:
		var ip := Net.local_address(IP.get_local_addresses())
		return {"nearby": net.offers(), "bots": offers, "listening": net.udp_port, "player": net.player,
			"own": "%s:%d" % [ip, net.port] if ip != "" and net.port > 0 else ""}
	visit_panel.open()

## A typed address: connect while staying home, travel once it answers (net.joined), toast if it never does.
func join_address(text: String) -> void:
	var a := Net.parse_address(text)
	if a.is_empty():
		toasts.add("wrecked", "Not an address: %s" % text)
		return
	var shown: String = a["ip"] if a["port"] == Net.GAME_PORT else "%s:%d" % [a["ip"], a["port"]]
	if not net.join(a["ip"], a["port"]):
		toasts.add("wrecked", "Couldn't reach %s" % shown)
		return
	_joining = {"name": shown, "player": "", "theme": "", "ip": a["ip"], "port": a["port"], "live": true, "joined": true}

## A real nearby park: an empty mirror now, the views fill as its map and live state arrive.
func _visit_live(offer: Dictionary) -> void:
	var ok_ := net.visit_map != null if offer.get("joined", false) else net.join(offer["ip"], offer["port"])
	if not ok_:  # a typed address is already connected (or dropped during the clouds)
		toasts.add("wrecked", "Couldn't reach %s" % offer["name"])
		return
	live = true
	_visit_zoo = ZooView.new()
	_visit_zoo.map = net.visit_map
	_visit_zoo.sim = net.visit_sim  # construction sites show their scaffold
	_visit_walkers = WalkerView.new()
	_visit_walkers.sim = net.visit_sim
	_enter_visit("%s · %s" % [offer["name"], offer["player"]] if offer["player"] != "" else offer["name"])

func _enter_visit(title: String) -> void:
	card.close()
	card.hover("", Vector2.ZERO)
	bar.clear()
	grid.map = null  # bot parks own all their land
	for n in [zoo, walkers, pins, fx, bar, hud]:
		n.hide()
	sim.leave_avatar(net.player)  # we're away: our character is in the other park
	add_child(_visit_zoo)
	add_child(_visit_walkers)
	visiting = true
	visit_panel.watch(title)

## Send one person of `kind` into the park on screen. False if not visiting, too poor, at the send limit, or a real
## park that hasn't answered yet. The park charges the price through its ledger (send_paid): a bot park's is paid
## here at once, a real host's arrives with its next ledger message, and a send the host refuses costs nothing.
func send(kind: String) -> bool:
	if not visiting or sim.money < Visit.PRICES[kind] or not VisitPanel.can_send(_inside()):
		return false
	if live:
		return net.send_person(kind)
	var v: Dictionary = visits[0]
	if not v["sim"].send_paid(kind, Visit.ME, ParkLevel.of(sim.xp)):
		return false
	_collect(v)
	return true

## What we have inside the park on screen, with our send limit there.
func _inside() -> Dictionary:
	return net.visit_ledger if live else visits[0]["sim"].sent_by(Visit.ME)

## Money a bot park's ledger moved since we last looked comes into (or out of) our sim.
func _collect(v: Dictionary) -> void:
	var owed: int = v["sim"].ledger.get(Visit.ME, 0)
	sim.money += owed - v["paid"]
	v["paid"] = owed

## Back to your park; the visited one keeps running while our people are inside.
func go_home() -> void:
	if not visiting:
		return
	visiting = false
	if not live:
		(visits[0]["sim"] as ParkSim).leave_avatar(net.player)
	sim.join_avatar(net.player, net.color)  # back at our gate
	grid.map = zoo.map
	live = false
	net.leave()
	_visit_zoo.queue_free()
	_visit_walkers.queue_free()
	visit_panel.close()
	for n in [zoo, walkers, pins, fx, bar, hud]:
		n.show()

## Run `ticks` sim steps: bots send their groups on schedule, new crimes become toasts.
func advance(ticks: int) -> void:
	for i in ticks:
		sim.step()
		if bots and sim.tick % SEND_EVERY == 0 and sim.tick < ParkSim.DAY_TICKS:
			var kinds: Array = []
			for k in _rng.randi_range(2, 4):
				kinds.append("guest")
			for k in _rng.randi_range(0, 2):
				kinds.append(ParkSim.KINDS[_rng.randi_range(1, ParkSim.KINDS.size() - 1)])
			send_group(BOTS[_rng.randi() % BOTS.size()], kinds)
	_unsaved += ticks
	if _unsaved >= AUTOSAVE:
		_unsaved = 0
		save()
	for e: Dictionary in sim.events.slice(_reported):
		toasts.add(e["kind"], _report(e), e["origin"], e)
	_reported = sim.events.size()

## A bot friend sends people in (shuffled, so actors hide among the guests).
func send_group(bot: String, kinds: Array) -> void:
	var order := kinds.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t: Variant = order[i]
		order[i] = order[j]
		order[j] = t
	for k: String in order:
		sim.send(k, bot)

func _report(e: Dictionary) -> String:
	var name := _name(e["origin"])
	match e["kind"]:
		"robbed": return "%s was robbed: −$%d" % [name, e["amount"]]
		"wrecked": return "%s was wrecked" % name
		"littered": return "Litter around %s" % name
		_: return "Someone studied the %s" % name

func _name(origin: Vector2i) -> String:
	return Buildings.get_def(zoo.map.buildings[origin])["name"] if zoo.map.buildings.has(origin) else "a building"

## Accuse a person by sim id; the outcome becomes a toast. {} if nobody has that id.
## Bots settle at once: the sim already moved the fine or the payment into your money.
func accuse(person_id: int) -> Dictionary:
	var r := sim.accuse(person_id)
	if r.is_empty():
		return r
	if r["wrongful"]:
		toasts.add("wrongful", "Wrongful arrest: you paid $%d" % r["fine"])
	else:
		var back := ", $%d back" % r["loot"] if r["loot"] > 0 else ""
		toasts.add("caught", "Caught a %s: +$%d fine%s" % [r["kind"], r["fine"], back])
	zoo.map.money = sim.money
	return r

## Id of the nearest guest drawn within PICK_RADIUS screen px of a world point, or -1.
func person_at(world: Vector2) -> int:
	var drawn := sim.guests.filter(func(g: Dictionary) -> bool: return g["state"] != "visit")  # inside = not drawn
	var i := _nearest(world, drawn.map(func(g: Dictionary) -> Vector2: return WalkerView.spot(g)))
	return drawn[i]["id"] if i >= 0 else -1

## Index of the nearest staff member within PICK_RADIUS screen px, or -1.
func staff_at(world: Vector2) -> int:
	return _nearest(world, sim.staff.map(func(s: Dictionary) -> Vector2: return s["pos"]))

func _nearest(world: Vector2, cells: Array) -> int:
	var best := -1
	var best_d := PICK_RADIUS / cam.zoom.x
	for i in cells.size():
		var d := world.distance_to(IsoGrid.project(cells[i]) - Vector2(0, WalkerView.LIFT + 5))
		if d < best_d:
			best = i
			best_d = d
	return best

## Left-click on the ground: place in place mode (back to Select unless painting or Shift), else select.
func _on_cell_clicked(cell: Vector2i, button: MouseButton, shift := false) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return
	if visiting:
		walk_to(cell)  # someone else's park: you walk and send people, you don't build or accuse
		return
	var id := zoo.selected
	if id == "" and (shift or Input.is_key_pressed(KEY_SHIFT)):
		walk_to(cell)  # Shift+click: plain clicks stay for selecting
	elif id == "":
		select_at(cell, get_global_mouse_position())
	elif zoo.on_click(cell) and not Buildings.get_def(id)["role"] in PAINT_ROLES and not (shift or Input.is_key_pressed(KEY_SHIFT)):
		bar.clear()

## Select mode click: a person near `world` gets the card, else the building on `cell`, else the card closes.
func select_at(cell: Vector2i, world: Vector2) -> void:
	var g := person_at(world)
	var s := staff_at(world)
	if g >= 0:
		card.show_person(g)
	elif s >= 0:
		card.show_staff(s)
	elif zoo.map.occupied.has(cell):
		card.show_building(zoo.map.occupied[cell])
	elif zoo.map.buyable(ParkMap.plot_of(cell)):
		card.show_plot(ParkMap.plot_of(cell))
	else:
		card.close()

func _on_pin_clicked(origin: Vector2i, _kind: String) -> void:
	card.show_building(origin)

func _on_card_action(what: String) -> void:
	var o := card.origin
	if what.begins_with("spec_"):
		zoo.map.toggle_specialty(o, what.trim_prefix("spec_"))
		return
	match what:
		"buy":
			zoo.map.money = sim.money
			if zoo.map.buy(card.plot):
				sim.money = zoo.map.money
				grid.queue_redraw()
				card.close()
		"upgrade":
			if card.staff >= 0:
				sim.upgrade_staff(card.staff)  # map money follows in _process
			else:
				zoo.upgrade(o)
		"demolish":
			if zoo.demolish(o):
				card.close()
		"repair":
			var before := sim.money
			if sim.repair(o):
				toasts.add("repaired", "Repaired %s: −$%d" % [_name(o), before - sim.money], o)
				zoo.map.money = sim.money
		"accuse":
			accuse(card.person)
			card.close()

## ZooView rebuilt after a place/remove: the map paid for it, hand money and layout back to the sim.
func _on_map_changed(money: int) -> void:
	sim.money = money
	sim.load_map(zoo.map)
