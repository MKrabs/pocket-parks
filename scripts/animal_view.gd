class_name AnimalView
extends Node2D
# One animal in its habitat, moving on its own (client-side only: the map says which animals live where, each
# copy of the game animates them itself). Happy: wanders, rests, swims in water cells. Unhappy: one paces at the
# back, the next hides (curled up, in the shelter if there is one).

const SPEED := 0.6  # tiles per second
const PACE_SPEED := 0.9
const SCALE := 1.25  # × Animals' drawing size, in the park
const JITTER := 0.25  # how far from a cell's centre a spot may be, tiles

var id := ""
var cells: Array = []
var water: Array = []
var shelter: Array = []
var happy := true
var index := 0  # which animal of the habitat: unhappy even ones pace, odd ones hide
var pos := Vector2.ZERO  # grid coords
var pose := "walk"
var _target := Vector2.ZERO
var _rest := 0.0
var _face := 1.0
var _phase := 0.0
var _pace: Array = []  # unhappy: the two spots it walks between
var _rng := RandomNumberGenerator.new()

static func of(a: String, h: Dictionary, i: int) -> AnimalView:
	var v := AnimalView.new()
	v.id = a
	v.cells = h["cells"]
	v.water = Animals.cells_of(h, "water")
	v.shelter = Animals.cells_of(h, "shelter")
	v.happy = Animals.comfort(a, h) >= Animals.HAPPY
	v.index = i
	v._rng.seed = hash([h["cells"][0], i])
	var back: Vector2i = v.cells[0]
	for c: Vector2i in v.cells:
		if c.x + c.y < back.x + back.y:
			back = c
	if not v.happy and i % 2 == 1:
		v.pose = "hide"
		v.pos = Vector2(v.shelter[0] if not v.shelter.is_empty() else back)
	elif not v.happy:
		var next := back
		for c: Vector2i in v.cells:
			if c != back and (c - back).length_squared() == 1:
				next = c
		v._pace = [Vector2(back) + Vector2(-0.2, 0.2), Vector2(next) + Vector2(0.2, -0.2)]
		v.pos = v._pace[0]
	else:
		v.pos = v._spot(v.cells[v._rng.randi() % v.cells.size()])
		v._rest = v._rng.randf_range(0.0, 3.0)
	v._target = v.pos
	v._place()
	return v

func _spot(c: Vector2i) -> Vector2:
	return Vector2(c) + Vector2(_rng.randf_range(-JITTER, JITTER), _rng.randf_range(-JITTER, JITTER))

func _in_water() -> bool:
	return Vector2i(pos.round()) in water

func _process(delta: float) -> void:
	if pose == "hide":
		return
	if _rest > 0.0:
		_rest -= delta
		pose = "swim" if _in_water() else "rest"
		queue_redraw()
		return
	var speed := SPEED if happy else PACE_SPEED
	var step := _target - pos
	if step.length() <= speed * delta:
		pos = _target
		if not happy:
			_target = _pace[1] if _target.is_equal_approx(_pace[0]) else _pace[0]
		else:
			if _rng.randf() < 0.5:
				_rest = _rng.randf_range(1.5, 4.0)
			var pool := water if not water.is_empty() and _rng.randf() < 0.4 else cells
			_target = _spot(pool[_rng.randi() % pool.size()])
	else:
		pos += step.normalized() * speed * delta
		var dx := IsoGrid.project(step).x
		if absf(dx) > 0.01:
			_face = signf(dx)
	pose = "swim" if _in_water() else "walk"
	_phase += delta * (3.0 if happy else 4.0)
	_place()
	queue_redraw()

func _place() -> void:
	position = IsoGrid.project(pos)
	z_index = 2 * roundi(pos.x + pos.y) + 1  # like WalkerView rows: in front of this cell's fence, behind the next

func _draw() -> void:
	Animals.draw(self, id, Vector2.ZERO, _face, pose, _phase, SCALE)
