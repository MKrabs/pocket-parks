extends SceneTree
# README hero shot: a fuller zoo mid-day, a bot group's crimes just landing, the Aviary's card open, zoomed in a little.
# ./gd shot docs/screenshots/park.png 40 res://tests/show_readme.gd

var main: Node2D
var _t := 0.0
var _built := false

const EXTRA := [
	["path", Vector2i(10, 10)], ["path", Vector2i(10, 9)], ["path", Vector2i(10, 8)], ["path", Vector2i(10, 7)],
	["path", Vector2i(10, 6)], ["water_tank", Vector2i(7, 4)], ["aviary", Vector2i(11, 7)], ["fountain", Vector2i(11, 10)],
	["fountain", Vector2i(8, 12)], ["snack_stand", Vector2i(13, 10)], ["tree", Vector2i(12, 13)], ["tree", Vector2i(5, 13)],
]

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	root.add_child.call_deferred(main)

func _process(delta: float) -> bool:
	_t += delta
	if not _built and main.sim:
		_built = true
		var map: ParkMap = main.zoo.map
		map.money = 1 << 30
		for e in EXTRA:
			map.place(e[0], e[1])
		main.sim.load_map(map)
		map.money = 1240
		main.sim.money = 1240
		main.sim.hire("janitor")
		main.sim.hire("guard")
		main.zoo.rebuild()
		main.cam.zoom = Vector2.ONE * 0.95
		main.cam.position += Vector2(0, -20)
	if _t >= 39.0:
		main.hud.level_card.hide()  # it levels up a few times in 40 s; keep the view clear
	if _t >= 39.75 and main.hud.speed != 0:
		main.hud.speed = 0
		var sim: ParkSim = main.sim
		main.send_group("Theo", ["hooligan", "litterbug", "thief", "guest", "guest"])
		var from := sim.events.size()
		var has := func(k: String) -> bool: return sim.events.slice(from).any(func(e: Dictionary) -> bool: return e["kind"] == k)
		while sim.tick < ParkSim.DAY_TICKS - 1 and not (has.call("wrecked") and has.call("robbed")):
			main.advance(1)
		main.card.show_building(Vector2i(11, 7))
	return false
