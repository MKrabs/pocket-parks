extends Node2D
# Entry point. Build child nodes in code here; keep main.tscn as the only scene file.

const SEED := [
	["zoo_gate", Vector2i(0, 7)], ["enclosure", Vector2i(2, 2)], ["pond", Vector2i(9, 3)], ["snack_stand", Vector2i(8, 9)],
	["tree", Vector2i(12, 2)], ["tree", Vector2i(13, 10)], ["tree", Vector2i(3, 11)],
	["tree", Vector2i(11, 12)], ["tree", Vector2i(6, 1)],
]

var bar := BuildBar.new()

## T swaps the active theme; the build bar follows, placed buildings stay.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k.pressed and not k.echo and k.physical_keycode == KEY_T:
		Buildings.use("festival" if Buildings.active == "zoo" else "zoo")
		bar.fill()

func _ready() -> void:
	var grid := GridView.new()
	add_child(grid)
	var zoo := ZooView.new()
	zoo.map.money = 1 << 30  # seed without running out
	for s in SEED:
		zoo.map.place(s[0], s[1])
	for x in range(1, 14):
		zoo.map.place("path", Vector2i(x, 7))
	zoo.map.money = ZooMap.START_MONEY  # the seeded zoo is free
	add_child(zoo)
	grid.cell_hovered.connect(zoo.on_hover)
	grid.cell_clicked.connect(zoo.on_click)

	bar.picked.connect(zoo.select)
	zoo.money_changed.connect(bar.set_money)
	add_child(bar)
	bar.set_money(zoo.map.money)

	var cam := IsoCamera.new()
	# centre of the board top, nudged down by half the slab depth plus room for the build bar
	cam.position = IsoGrid.project(Vector2(IsoGrid.SIZE) / 2.0 - Vector2(0.5, 0.5)) + Vector2(0, GridView.SLAB / 2 + 30)
	add_child(cam)
