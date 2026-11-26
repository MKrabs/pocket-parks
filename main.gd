extends Node2D
# Entry point. Build child nodes in code here; keep main.tscn as the only scene file.

# Every attraction and shop touches the path along y=7 that runs from the gate.
const SEED := [
	["zoo_gate", Vector2i(0, 7)], ["enclosure", Vector2i(2, 4)], ["pond", Vector2i(12, 5)], ["snack_stand", Vector2i(8, 8)],
	["snack_stand", Vector2i(5, 8)], ["tree", Vector2i(12, 2)], ["tree", Vector2i(13, 10)], ["tree", Vector2i(3, 11)],
	["tree", Vector2i(11, 12)], ["tree", Vector2i(6, 1)],
]
# Bot "friends" stand in for real ones: every SEND_EVERY ticks one sends a mixed group into your park.
const BOTS := ["Mia", "Theo"]
const SEND_EVERY := 30 * ParkSim.TPS
const PICK_RADIUS := 12.0  # screen px around a person for the accuse tool

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
var accusing := false
var bots := true  # bot friends send groups into your park (tests switch them off)
var _acc := 0.0  # sim ticks owed
var _reported := 0  # sim.events already toasted
var _rng := RandomNumberGenerator.new()

## T swaps the active theme; the build bar follows, placed buildings stay.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k.pressed and not k.echo and k.physical_keycode == KEY_T:
		Buildings.use("festival" if Buildings.active == "zoo" else "zoo")
		bar.fill()

func _ready() -> void:
	var grid := GridView.new()
	add_child(grid)
	zoo.map.money = 1 << 30  # seed without running out
	for s in SEED:
		zoo.map.place(s[0], s[1])
	for x in range(1, 14):
		zoo.map.place("path", Vector2i(x, 7))
	zoo.map.money = ParkMap.START_MONEY  # the seeded zoo is free
	sim = ParkSim.new(zoo.map, 1)
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
		accusing = id == "accuse"
		zoo.select("" if accusing else id))
	add_child(bar)
	hud.sim = sim
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	offers = Visit.offers(rng)
	hud.visit_pressed.connect(func() -> void: visit_panel.open(offers))
	add_child(hud)
	visit_panel.picked.connect(travel_to)
	visit_panel.sent.connect(send)
	visit_panel.home.connect(travel_home)
	add_child(visit_panel)
	add_child(transition)
	toasts.clicked.connect(func(o: Vector2i) -> void: cam.position = IsoGrid.to_screen(o))
	add_child(toasts)

	# centre of the board top, nudged down by half the slab depth, sized to sit between the two bars
	cam.position = IsoGrid.project(Vector2(IsoGrid.SIZE) / 2.0 - Vector2(0.5, 0.5)) + Vector2(0, GridView.SLAB / 2)
	cam.zoom = Vector2.ONE * 0.92
	add_child(cam)

	if debug_visit:
		visit({"name": "Clover Fields", "theme": "festival", "seed": 7, "size": "small", "guards": 1})
		for k: String in ["guest", "guest", "thief", "spy", "litterbug", "guest", "hooligan", "guest", "guest", "guest"]:
			send(k)

func _process(delta: float) -> void:
	_acc += delta * ParkSim.TPS
	while _acc >= 1.0:
		step_world()
		_acc -= 1.0
	zoo.show_wrecked(sim.closed)
	zoo.map.money = sim.money  # the sim owns money while the day runs; building spends from the map
	if visiting:
		_visit_zoo.show_wrecked(visits[0]["sim"].closed)
		visit_panel.show_ledger(visits[0]["sim"].sent_by(Visit.ME), sim.money)

## One world tick: your park (at the HUD speed at home, 1× while away) and every visited park at 1×.
## Money the visited parks owe us (or we owe them) moves into our sim; stolen blueprints join the build bar.
func step_world() -> void:
	advance(1 if visiting else hud.speed)  # your park: bot senders + crime toasts
	for v in visits.duplicate():
		var vs: ParkSim = v["sim"]
		vs.step()
		if vs.tick >= ParkSim.DAY_TICKS:
			vs.new_day()  # ponytail: bot parks loop their day; our people still inside are dropped
		var owed: int = vs.ledger.get(Visit.ME, 0)
		sim.money += owed - v["paid"]
		v["paid"] = owed
		var got := false
		for id: String in vs.blueprints.get(Visit.ME, []):
			if not id in bar.stolen:
				bar.stolen.append(id)
				got = true
		if got:
			bar.fill()
		var t := vs.sent_by(Visit.ME)
		if not (visiting and v == visits[0]) and t["guests"] + t["hidden"] + t["wanted"] == 0:
			visits.erase(v)  # left behind and nobody of ours is inside any more

## visit() behind the cloud transition (the swap happens at full cover).
func travel_to(offer: Dictionary) -> Tween:
	return transition.play(cam, offer["name"], visit.bind(offer), true)

## go_home() behind the cloud transition, clouds rolling the other way.
func travel_home() -> Tween:
	return transition.play(cam, "Home", go_home, false)

## Swap the view to the offer's park (reusing its sim if we were already there).
func visit(offer: Dictionary) -> void:
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
	for n in [zoo, walkers, pins, fx, bar, hud]:
		n.hide()
	add_child(_visit_zoo)
	add_child(_visit_walkers)
	visiting = true
	visit_panel.watch(offer["name"])

## Send one person of `kind` into the park on screen, paid now. False if not visiting or too poor.
func send(kind: String) -> bool:
	if not visiting or sim.money < Visit.PRICES[kind]:
		return false
	sim.money -= Visit.PRICES[kind]
	visits[0]["sim"].send(kind, Visit.ME)
	return true

## Back to your park; the visited one keeps running while our people are inside.
func go_home() -> void:
	if not visiting:
		return
	visiting = false
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

## Nearest person drawn within PICK_RADIUS screen px of a world point, or -1.
func person_at(world: Vector2) -> int:
	var best := -1
	var best_d := PICK_RADIUS / cam.zoom.x
	for g in sim.guests:
		if g["state"] == "visit":
			continue  # inside, not drawn
		var d := world.distance_to(IsoGrid.project(WalkerView.spot(g)) - Vector2(0, WalkerView.LIFT + 5))
		if d < best_d:
			best = g["id"]
			best_d = d
	return best

func _on_cell_clicked(cell: Vector2i, button: MouseButton) -> void:
	if visiting:
		return  # someone else's park: you send people, you don't build or accuse
	if accusing and button == MOUSE_BUTTON_LEFT:
		var id := person_at(get_global_mouse_position())
		if id >= 0:
			accuse(id)
	else:
		zoo.on_click(cell, button)

func _on_pin_clicked(origin: Vector2i, kind: String) -> void:
	var before := sim.money
	if kind == "wrecked" and sim.repair(origin):
		toasts.add("repaired", "Repaired %s: −$%d" % [_name(origin), before - sim.money], origin)
		zoo.map.money = sim.money

## ZooView rebuilt after a place/remove: the map paid for it, hand money and layout back to the sim.
func _on_map_changed(money: int) -> void:
	sim.money = money
	sim.load_map(zoo.map)
