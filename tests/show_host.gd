extends SceneTree
# Showcase: your own park after a bot friend's group did its worst; fresh toasts and pins.
# ./gd shot shots/N3.png 40 res://tests/show_host.gd

var main: Node2D
var _t := 0.0

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	root.add_child.call_deferred(main)

## Close to the shot frame (toasts fade after 6 s), fast-forward until there is a wreck and litter.
func _process(delta: float) -> bool:
	_t += delta
	if _t >= 36.0 and main.hud.speed != 0:
		main.hud.speed = 0
		var sim: ParkSim = main.sim
		main.send_group("Theo", ["hooligan", "litterbug", "thief", "guest", "guest"])
		var from := sim.events.size()
		var has := func(k: String) -> bool: return sim.events.slice(from).any(func(e: Dictionary) -> bool: return e["kind"] == k)
		while sim.tick < ParkSim.DAY_TICKS - 1 and not (has.call("wrecked") and has.call("littered") and has.call("robbed")):
			main.advance(1)
	return false
