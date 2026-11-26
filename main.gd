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
	grid.cell_clicked.connect(zoo.on_click)

	walkers.sim = sim
	add_child(walkers)

	bar.picked.connect(zoo.select)
	add_child(bar)
	hud.sim = sim
	add_child(hud)

	var cam := IsoCamera.new()
	# centre of the board top, nudged down by half the slab depth, sized to sit between the two bars
	cam.position = IsoGrid.project(Vector2(IsoGrid.SIZE) / 2.0 - Vector2(0.5, 0.5)) + Vector2(0, GridView.SLAB / 2)
	cam.zoom = Vector2.ONE * 0.92
	add_child(cam)

func _process(delta: float) -> void:
	_acc += delta * ParkSim.TPS * hud.speed
	while _acc >= 1.0:
		sim.step()
		_acc -= 1.0
	zoo.show_wrecked(sim.closed)
	zoo.map.money = sim.money  # the sim owns money while the day runs; building spends from the map

## ZooView rebuilt after a place/remove: the map paid for it, hand money and layout back to the sim.
func _on_map_changed(money: int) -> void:
	sim.money = money
	sim.load_map(zoo.map)
