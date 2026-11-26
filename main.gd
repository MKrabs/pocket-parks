extends Node2D
# Entry point. Build child nodes in code here; keep main.tscn as the only scene file.

# Every attraction and shop touches the path along y=7 that runs from the gate.
const SEED := [
	["zoo_gate", Vector2i(0, 7)], ["enclosure", Vector2i(2, 4)], ["pond", Vector2i(12, 5)], ["snack_stand", Vector2i(8, 8)],
	["snack_stand", Vector2i(5, 8)], ["tree", Vector2i(12, 2)], ["tree", Vector2i(13, 10)], ["tree", Vector2i(3, 11)],
	["tree", Vector2i(11, 12)], ["tree", Vector2i(6, 1)],
]

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
var _acc := 0.0  # world ticks owed

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
	zoo.money_changed.connect(_on_map_changed)
	add_child(zoo)
	grid.cell_hovered.connect(zoo.on_hover)
	grid.cell_clicked.connect(func(c: Vector2i, b: MouseButton) -> void:
		if not visiting:
			zoo.on_click(c, b))

	walkers.sim = sim
	add_child(walkers)

	bar.picked.connect(zoo.select)
	add_child(bar)
	hud.sim = sim
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	offers = Visit.offers(rng)
	hud.visit_pressed.connect(func() -> void: visit_panel.open(offers))
	add_child(hud)
	visit_panel.picked.connect(visit)
	visit_panel.sent.connect(send)
	visit_panel.home.connect(go_home)
	add_child(visit_panel)

	var cam := IsoCamera.new()
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
	zoo.map.money = sim.money  # the sim owns money while the day runs; building spends from the map
	if visiting:
		_visit_zoo.show_wrecked(visits[0]["sim"].closed)
		visit_panel.show_ledger(visits[0]["sim"].sent_by(Visit.ME), sim.money)

## One world tick: your park (at the HUD speed at home, 1× while away) and every visited park at 1×.
## Money the visited parks owe us (or we owe them) moves into our sim; stolen blueprints join the build bar.
func step_world() -> void:
	for i in (1 if visiting else hud.speed):
		sim.step()
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
	for n in [zoo, walkers, bar, hud]:
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
	for n in [zoo, walkers, bar, hud]:
		n.show()

## ZooView rebuilt after a place/remove: the map paid for it, hand money and layout back to the sim.
func _on_map_changed(money: int) -> void:
	sim.money = money
	sim.load_map(zoo.map)
