extends Node2D
# Entry point. Build child nodes in code here; keep main.tscn as the only scene file.

# Every attraction and shop touches the path along y=7 that runs from the gate.
const SEED := [
	["zoo_gate", Vector2i(0, 7)], ["enclosure", Vector2i(2, 4)], ["pond", Vector2i(12, 5)], ["snack_stand", Vector2i(8, 8)],
	["snack_stand", Vector2i(5, 8)], ["tree", Vector2i(12, 2)], ["tree", Vector2i(13, 10)], ["tree", Vector2i(3, 11)],
	["tree", Vector2i(11, 12)], ["tree", Vector2i(6, 1)], ["builder_shed", Vector2i(2, 8)],
]
# Bot "friends" stand in for real ones: every SEND_EVERY ticks one sends a mixed group into your park.
const BOTS := ["Mia", "Theo"]
const SEND_EVERY := 30 * ParkSim.TPS
const PICK_RADIUS := 12.0  # screen px around a person for hover and click in Select mode
const PAINT_ROLES := ["path", "decor"]  # stay in place mode after placing (paths, trees); others go back to Select

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
var bots := true  # bot friends send groups into your park (tests switch them off)
var _acc := 0.0  # sim ticks owed
var _reported := 0  # sim.events already toasted
var _rng := RandomNumberGenerator.new()

## T cycles the active theme (zoo → festival → cinema); the build bar follows, placed buildings stay.
## Esc leaves place mode, or closes the card in Select mode.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if k.physical_keycode == KEY_T:
		var ts: Array = Buildings.themes().keys()
		Buildings.use(ts[(ts.find(Buildings.active) + 1) % ts.size()])
		bar.fill()
	elif k.physical_keycode == KEY_R:
		zoo.rotate_ghost(-1 if k.shift_pressed else 1)
	elif k.physical_keycode == KEY_ESCAPE:
		escape()

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
	var grid := GridView.new()
	add_child(grid)
	zoo.map.money = 1 << 30  # seed without running out
	for s in SEED:
		zoo.map.place(s[0], s[1])
	for x in range(1, 14):
		zoo.map.place("path", Vector2i(x, 7))
	zoo.map.money = ParkMap.START_MONEY  # the seeded zoo is free
	sim = ParkSim.new(zoo.map, 1)
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
	toasts.floor_y = card.top() if card.is_open() else INF
	zoo.map.money = sim.money  # the sim owns money while the day runs; building spends from the map
	zoo.map.xp = sim.xp
	if visiting:
		_visit_zoo.show_wrecked(visits[0]["sim"].closed)
		visit_panel.show_ledger(visits[0]["sim"].sent_by(Visit.ME), sim.money)
	else:
		_hover(get_global_mouse_position(), get_viewport().get_mouse_position())

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
	card.close()
	card.hover("", Vector2.ZERO)
	bar.clear()
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
	if visiting or button != MOUSE_BUTTON_LEFT:
		return  # someone else's park: you send people, you don't build or accuse
	var id := zoo.selected
	if id == "":
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
		"upgrade":
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
