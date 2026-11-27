class_name Feedback
extends Node2D
# World-space gameplay feedback for your park: reads the sim's events, cash_events and arrests as they
# arrive and plays Motion effects (shakes, puffs, coins, floating "+$"). Tuning lives in motion.gd.

var sim: ParkSim
var zoo: ZooView
var walkers: WalkerView
var hud: Hud
var _ev := 0
var _cash := 0
var _arr := 0
var _str := 0
var _owed: Dictionary = {}  # building origin -> money paid there, not shown yet
var _last: Dictionary = {}  # building origin -> time of its last float
var _time := 0.0

func _ready() -> void:
	z_index = 1400  # above buildings and walkers, below pins

func _process(delta: float) -> void:
	_time += delta
	for e: Dictionary in sim.events.slice(_ev):
		_crime(e)
	_ev = sim.events.size()
	for c: Dictionary in sim.cash_events.slice(_cash):
		_owed[c["origin"]] = _owed.get(c["origin"], 0) + c["amount"]
	_cash = sim.cash_events.size()
	for o: Vector2i in _owed.keys():
		if _time - _last.get(o, -INF) >= Motion.MONEY_EVERY:
			_float(o, _owed[o])
			_owed.erase(o)
			_last[o] = _time
	for a: Dictionary in sim.arrests.slice(_arr):
		_arrest(a)
	_arr = sim.arrests.size()
	for s: Dictionary in sim.strolls.slice(_str):
		stroll_mark(s["pos"], s["stroll"] == "lovely")
	_str = sim.strolls.size()

## A small cloud puff over a guest's head: a CORAL ♥ after a lovely stroll, a STONE ~ after a dull one.
func stroll_mark(pos: Vector2, lovely: bool) -> void:
	var m := shape(func(ci: Node2D) -> void:
		ci.draw_colored_polygon(Squircle.points(Vector2(0, 1), Vector2(9, 8), Puff.ROUND, 32), Palette.CLOUD_SHADOW)
		ci.draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2(9, 8), Puff.ROUND, 32), Palette.CLOUD)
		if lovely:
			var c := Palette.CORAL
			for x: float in [-2.3, 2.3]:
				ci.draw_colored_polygon(Squircle.points(Vector2(x, -1.6), Vector2(2.9, 2.9), 2.0, 20), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-5.0, -0.6), Vector2(5.0, -0.6), Vector2(0, 5.2)]), c)
		else:
			var wave := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				wave.append(Vector2(lerpf(-5.0, 5.0, t), -sin(t * TAU) * 1.8))
			ci.draw_polyline(wave, Palette.shade(Palette.STONE, 0.22), 2.2, true))
	m.position = IsoGrid.project(pos) - Vector2(0, WalkerView.LIFT + 24)
	add_child(m)
	var t := Motion.pop(m)
	t.parallel().tween_property(m, "position:y", m.position.y - Motion.STROLL_RISE, Motion.STROLL_TIME).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: Motion.vanish(m))

func _crime(e: Dictionary) -> void:
	var o: Vector2i = e["origin"]
	var v := zoo.view_at(o)
	if v == null:
		return
	Motion.shake(v, Motion.CRIME_SHAKE)
	var base := base_of(v.id, o, v.turn)
	var top := PinView.top(v.id, o, v.turn)
	match e["kind"]:
		"wrecked":
			for i in Motion.DEBRIS:
				Motion.puff_at(self, base + Vector2(randf_range(-22, 22), randf_range(-6, 8)), Motion.DEBRIS_SIZE)
		"littered":
			Motion.puff_at(self, base + Vector2(0, 8), Motion.LITTER_PUFF)
		"robbed":
			var c := coin(Palette.BUTTER)
			c.position = top
			add_child(c)
			Motion.pop(c)
			Motion.fly_to(c, top + Motion.LOOT_FLY, func() -> void: Motion.vanish(c))
		"spied":
			var g := shape(func(ci: Node2D) -> void:
				for h: Vector2 in [Vector2(9, 2.2), Vector2(2.2, 9)]:
					ci.draw_colored_polygon(Squircle.points(Vector2.ZERO, h, 2.4, 24), Palette.SKY)
				ci.draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2(2.4, 2.4), 4.0, 12), Palette.CREAM))
			g.position = top
			add_child(g)
			var t := Motion.pop(g)
			t.tween_interval(Motion.GLINT_HOLD)
			t.tween_callback(func() -> void: Motion.vanish(g))

## A small rounded BUTTER "+$n" pill that rises and fades over the building.
func _float(o: Vector2i, amount: int) -> void:
	if not zoo.map.buildings.has(o):
		return
	var text := "+$%d" % amount
	var l := shape(func(ci: Node2D) -> void:
		var f := Palette.FONT
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		ci.draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2(w * 0.5 + 7, 9), 4.0, 32), Palette.BUTTER)
		ci.draw_string(f, Vector2(-w * 0.5, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.INK))
	l.position = PinView.top(zoo.map.buildings[o], o, zoo.map.rotation(o)) - Vector2(0, 6)
	l.z_index = 200  # over the pins: it is small and gone in a second
	add_child(l)
	var t := Motion.pop(l).set_parallel()
	t.tween_property(l, "position:y", l.position.y - Motion.MONEY_RISE, Motion.MONEY_TIME).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, Motion.MONEY_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(l.queue_free)

## Caught actors vanish in a puff (wrongly accused ones walk off); the guard hops; the money coin flies.
func _arrest(a: Dictionary) -> void:
	var at := IsoGrid.project(a["pos"]) - Vector2(0, WalkerView.LIFT + 5)
	if not a["wrongful"]:
		Motion.puff_at(self, at, Motion.ARREST_PUFF)
	if a["guard"] >= 0:
		walkers.hop(a["guard"])
	hud.coin_fly(get_viewport().get_canvas_transform() * at, a["amount"])

## Centre of a building's footprint on the ground.
static func base_of(id: String, o: Vector2i, rot := 0) -> Vector2:
	var fp := ParkMap.size(id, rot)
	return IsoGrid.project(Vector2(o) + Vector2(fp - Vector2i.ONE) * 0.5)

## A node that draws with `f(node)`.
static func shape(f: Callable) -> Node2D:
	var n := Node2D.new()
	n.draw.connect(func() -> void: f.call(n))
	return n

## A small coin: darker rim, lighter face.
static func coin(c: Color) -> Node2D:
	return shape(func(ci: Node2D) -> void:
		ci.draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2(7, 7), 3.0, 24), Palette.shade(c, 0.22))
		ci.draw_colored_polygon(Squircle.points(Vector2(0, -0.8), Vector2(5.4, 5.4), 3.0, 24), c))
