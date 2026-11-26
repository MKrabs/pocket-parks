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
var raid_panel := RaidPanel.new()
var raid_sim: ParkSim  # the target's day while a raid runs; your park's sim pauses
var raid_zoo: ZooView
var raid_walkers: WalkerView
var _rng := RandomNumberGenerator.new()
var debug_raid := ""  # tests/show_raid*.gd: "raid" starts inside a raid with a fixed squad, "picker" opens the picker
var _acc := 0.0  # sim ticks owed

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
		if not raid_sim:
			zoo.on_click(c, b))

	walkers.sim = sim
	add_child(walkers)

	bar.picked.connect(zoo.select)
	add_child(bar)
	hud.sim = sim
	hud.raid_pressed.connect(func() -> void: raid_panel.open(_rng, sim.money))
	add_child(hud)
	raid_panel.go.connect(_start_raid)
	raid_panel.home.connect(_end_raid)
	add_child(raid_panel)

	var cam := IsoCamera.new()
	# centre of the board top, nudged down by half the slab depth, sized to sit between the two bars
	cam.position = IsoGrid.project(Vector2(IsoGrid.SIZE) / 2.0 - Vector2(0.5, 0.5)) + Vector2(0, GridView.SLAB / 2)
	cam.zoom = Vector2.ONE * 0.92
	add_child(cam)

	if debug_raid == "picker":
		_rng.seed = 7
		hud.raid_pressed.emit()
	elif debug_raid == "raid":
		raid_panel.go.emit({"theme": "festival", "size": "small", "seed": 7, "guards": 0},
			{"hooligan": 1, "litterbug": 3, "thief": 1, "spy": 1})

func _process(delta: float) -> void:
	var active := raid_sim if raid_sim else sim
	_acc += delta * ParkSim.TPS * (1 if raid_sim else hud.speed)
	while _acc >= 1.0:
		active.step()
		_acc -= 1.0
	if raid_sim:
		raid_zoo.show_wrecked(raid_sim.closed)
	zoo.map.money = sim.money  # the sim owns money while the day runs; building spends from the map

## Go: pay for the squad and swap the world to the target park.
func _start_raid(offer: Dictionary, counts: Dictionary) -> void:
	sim.money -= Raid.cost(counts)
	var map := Raid.target(offer)
	raid_sim = Raid.start(map, offer, counts)
	raid_zoo = ZooView.new()
	raid_zoo.map = map
	raid_walkers = WalkerView.new()
	raid_walkers.sim = raid_sim
	for n in [zoo, walkers, bar, hud]:
		n.hide()
	add_child(raid_zoo)
	add_child(raid_walkers)
	raid_panel.watch(raid_sim)

## Back home: keep the loot, add stolen blueprints to the build bar.
func _end_raid(result: Dictionary) -> void:
	sim.money += result["stolen_money"]
	for id: String in result["blueprints"]:
		if not id in bar.stolen:
			bar.stolen.append(id)
	bar.fill()
	raid_zoo.queue_free()
	raid_walkers.queue_free()
	raid_sim = null
	for n in [zoo, walkers, bar, hud]:
		n.show()

## ZooView rebuilt after a place/remove: the map paid for it, hand money and layout back to the sim.
func _on_map_changed(money: int) -> void:
	sim.money = money
	sim.load_map(zoo.map)
