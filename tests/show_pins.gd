extends SceneTree
# Showcase: one pin per status over snack stands; the mouse sits on one so it widens into its pill.
# ./gd shot shots/X2.png 1 res://tests/show_pins.gd

const STATUS := {Vector2i(2, 2): ["wrecked"], Vector2i(5, 2): ["littered"], Vector2i(2, 5): ["robbed"],
	Vector2i(5, 5): ["spied"], Vector2i(8, 2): ["wrecked", "littered", "robbed"]}

class StubSim extends ParkSim:
	func building_status(origin: Vector2i) -> Array[String]:
		var out: Array[String] = []
		out.assign(STATUS.get(origin, []))
		return out

var pins := PinView.new()
var _frames := 0

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	stage.scale = Vector2(2, 2)  # enlarged so the glyphs are easy to judge
	stage.position = Vector2(560, 60)
	var zoo := ZooView.new()
	for o: Vector2i in STATUS:
		zoo.map.place("snack_stand", o)
	stage.add_child(zoo)
	pins.map = zoo.map
	pins.sim = StubSim.new(zoo.map, 1)
	stage.add_child(pins)
	root.add_child.call_deferred(stage)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 2:  # hover the littered pin
		var head := pins.get_global_transform() * (PinView.top("snack_stand", Vector2i(5, 2)) + Vector2(0, -PinView.RISE))
		root.warp_mouse(head)
	return false
