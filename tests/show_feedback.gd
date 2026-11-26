extends SceneTree
# Showcase: gameplay feedback mid-motion: a bot group's crimes land a quarter second before the shot,
# with the money floats over the gate and shops. ./gd shot shots/A2.png 40 res://tests/show_feedback.gd

var main: Node2D
var _t := 0.0

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	root.add_child.call_deferred(main)

func _process(delta: float) -> bool:
	_t += delta
	if _t >= 39.75 and main.hud.speed != 0:
		main.hud.speed = 0
		var sim: ParkSim = main.sim
		main.send_group("Theo", ["hooligan", "litterbug", "thief", "spy", "guest", "guest"])
		var from := sim.events.size()
		var has := func(k: String) -> bool: return sim.events.slice(from).any(func(e: Dictionary) -> bool: return e["kind"] == k)
		while sim.tick < ParkSim.DAY_TICKS - 1 and not (has.call("wrecked") and has.call("robbed")):
			main.advance(1)
	return false
