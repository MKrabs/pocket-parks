class_name Animals
# The 9 animals (docs/design/game.md → Habitats and animals): needs, comfort and appeal (pure logic), and their
# drawing (static, shared by the habitat's AnimalView and the card's portraits).
# A habitat (ParkMap.habitats[o]) holds one species: "animal" (id or "") and "count". Its "items" (HAB3 places them)
# are {id, cells}; ITEM_TERRAIN says what each item counts as.

const MAX := 4  # animals per habitat
const HAPPY := 50  # comfort at or above: out and active
const FENCE_CATEGORY := {"glass": "water", "wall": "highlands", "net": "birds", "fence": "highlands"}
const ITEM_TERRAIN := {"pool": ["water"], "rocks": ["rocks"], "tree": ["trees"], "shelter": ["shelter"],
	"waterfall": ["water", "rocks"]}
const SHARES := ["water", "rocks", "trees"]

# cells = minimum habitat size; water / rocks / trees = share of its cells; shelter = needs one.
const ALL := {
	"otter": {"name": "Otter", "category": "water", "price": 120, "cells": 6, "water": 0.4, "rocks": 0.1, "trees": 0.0,
		"shelter": true, "color": Palette.OTTER},
	"capybara": {"name": "Capybara", "category": "water", "price": 140, "cells": 9, "water": 0.3, "rocks": 0.0, "trees": 0.2,
		"shelter": false, "color": Palette.CAPYBARA},
	"platypus": {"name": "Platypus", "category": "water", "price": 180, "cells": 4, "water": 0.5, "rocks": 0.1, "trees": 0.0,
		"shelter": true, "color": Palette.PLATYPUS},
	"red_panda": {"name": "Red Panda", "category": "highlands", "price": 150, "cells": 6, "water": 0.0, "rocks": 0.1, "trees": 0.4,
		"shelter": true, "color": Palette.RED_PANDA},
	"takin": {"name": "Takin", "category": "highlands", "price": 200, "cells": 12, "water": 0.1, "rocks": 0.3, "trees": 0.1,
		"shelter": false, "color": Palette.TAKIN},
	"klipspringer": {"name": "Klipspringer", "category": "highlands", "price": 130, "cells": 6, "water": 0.0, "rocks": 0.5,
		"trees": 0.0, "shelter": false, "color": Palette.KLIPSPRINGER},
	"shoebill": {"name": "Shoebill", "category": "birds", "price": 220, "cells": 9, "water": 0.4, "rocks": 0.0, "trees": 0.1,
		"shelter": false, "color": Palette.SHOEBILL},
	"puffin": {"name": "Puffin", "category": "birds", "price": 120, "cells": 6, "water": 0.3, "rocks": 0.3, "trees": 0.0,
		"shelter": true, "color": Palette.PUFFIN},
	"hornbill": {"name": "Hornbill", "category": "birds", "price": 180, "cells": 9, "water": 0.0, "rocks": 0.0, "trees": 0.5,
		"shelter": true, "color": Palette.HORNBILL},
}

## Animals a habitat with fence style `fence` can hold.
static func picker(fence: String) -> Array:
	return ALL.keys().filter(func(a: String) -> bool: return ALL[a]["category"] == FENCE_CATEGORY.get(fence, ""))

## What habitat `h` offers: {cells, water, rocks, trees (shares 0–1), shelter (bool)}.
static func terrain(h: Dictionary) -> Dictionary:
	var n: int = h["cells"].size()
	var count := {"water": {}, "rocks": {}, "trees": {}, "shelter": {}}
	for it: Dictionary in h.get("items", []):
		for t: String in ITEM_TERRAIN.get(it["id"], []):
			for c: Vector2i in it["cells"]:
				count[t][c] = true
	var out := {"cells": n, "shelter": not count["shelter"].is_empty()}
	for t: String in SHARES:
		out[t] = count[t].size() / float(maxi(n, 1))
	return out

## How well `h` meets animal `a`'s needs: [{need, ok, score 0–1, text}], size first.
static func needs(a: String, h: Dictionary) -> Array:
	var d: Dictionary = ALL[a]
	var t := terrain(h)
	var out: Array = []
	var n: int = t["cells"]
	out.append({"need": "cells", "ok": n >= d["cells"], "score": minf(1.0, n / float(d["cells"])),
		"text": "Room: %d cells" % n if n >= d["cells"] else "Room: needs %d more cells" % (d["cells"] - n)})
	for s: String in SHARES:
		var want: float = d[s]
		if want <= 0.0:
			continue
		var have: float = t[s]
		var miss := ceili((want - have) * 100.0 - 0.001)
		out.append({"need": s, "ok": miss <= 0, "score": minf(1.0, have / want),
			"text": "%s: %d%%" % [s.capitalize(), roundi(want * 100.0)] if miss <= 0 else "needs %d%% more %s" % [miss, s]})
	if d["shelter"]:
		out.append({"need": "shelter", "ok": t["shelter"], "score": 1.0 if t["shelter"] else 0.0,
			"text": "Shelter" if t["shelter"] else "needs a shelter"})
	return out

## Comfort 0–100 of animal `a` in habitat `h`: the mean of its needs' scores.
static func comfort(a: String, h: Dictionary) -> int:
	var ns := needs(a, h)
	var sum := 0.0
	for n: Dictionary in ns:
		sum += n["score"]
	return roundi(100.0 * sum / ns.size())

## × the habitat's per-cell appeal: an empty habitat 0.5, with animals 0.5 (miserable) to 2 (fully comfortable).
static func appeal_factor(h: Dictionary) -> float:
	if h.get("animal", "") == "" or h.get("count", 0) <= 0:
		return 0.5
	return 0.5 + 1.5 * comfort(h["animal"], h) / 100.0

## Cells of `h` an item with terrain `t` covers.
static func cells_of(h: Dictionary, t: String) -> Array:
	var out: Array = []
	for it: Dictionary in h.get("items", []):
		if t in ITEM_TERRAIN.get(it["id"], []):
			out.append_array(it["cells"])
	return out

# --- Drawing ------------------------------------------------------------------------------------------------------
# Every animal is one or two soft silhouettes about 18 px long, facing right (`face` -1 mirrors it), feet at `at`.
# `pose`: "walk" (legs/body bob with `phase`), "rest" (lying low), "swim" (only head and back above the water line),
# "hide" (a curled lump).

static func draw(ci: CanvasItem, a: String, at: Vector2, face := 1.0, pose := "walk", phase := 0.0, scale := 1.0) -> void:
	var c: Color = ALL[a]["color"]
	var dk := Palette.shade(c, 0.22)
	var bob := absf(sin(phase * TAU)) * 1.5 if pose == "walk" else 0.0
	ci.draw_set_transform(at, 0.0, Vector2(face, 1.0) * scale)
	ci.draw_colored_polygon(Squircle.points(Vector2(0, -0.5), Vector2(9, 3), 2.0, 24), Color(Palette.INK, 0.12))  # shadow
	if pose == "hide":
		_blob(ci, Vector2(0, -4), Vector2(7, 4), dk)
		_blob(ci, Vector2(3, -6), Vector2(3, 2.5), c)
		ci.draw_set_transform(Vector2.ZERO)
		return
	var low := 4.0 if pose == "rest" else 0.0  # resting: body sinks, legs tuck in
	var swim := pose == "swim"
	var y := -bob + low + (9.0 if swim else 0.0)
	var legs := not swim and pose != "rest"
	var step := sin(phase * TAU) * 1.5 if pose == "walk" else 0.0
	match a:
		"otter":  # long low body, small round head, tapering tail
			if legs:
				_legs(ci, [-4.0, 4.0], 3.0, dk, step)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, -6 + y), Vector2(-14, -3 + y), Vector2(-6, -3 + y)]), dk)
			_blob(ci, Vector2(0, -6 + y), Vector2(7.5, 3.2), c)
			_blob(ci, Vector2(8, -8 + y), Vector2(3.2, 2.8), c)
			_blob(ci, Vector2(9, -7 + y), Vector2(1.8, 1.2), Palette.CREAM)
		"capybara":  # one big barrel with a blunt square head
			if legs:
				_legs(ci, [-5.0, 4.0], 3.0, dk, step)
			_blob(ci, Vector2(-1, -8 + y), Vector2(8, 5), c, 4.0)
			_blob(ci, Vector2(8, -10 + y), Vector2(3.5, 3.5), c, 4.0)
			_blob(ci, Vector2(7, -14 + y), Vector2(1.2, 1.2), dk)
		"platypus":  # flat body, broad paddle tail, duck bill
			if legs:
				_legs(ci, [-3.0, 3.0], 2.0, dk, step)
			_blob(ci, Vector2(-9, -4 + y), Vector2(4, 1.8), dk)
			_blob(ci, Vector2(0, -5 + y), Vector2(6.5, 3), c)
			_blob(ci, Vector2(10, -5 + y), Vector2(3.5, 1.4), Palette.INK)
		"red_panda":  # rust body, ringed bushy tail, pale face
			if legs:
				_legs(ci, [-4.0, 4.0], 4.0, Palette.INK, step)
			_blob(ci, Vector2(-10, -9 + y), Vector2(4, 3), c)
			_blob(ci, Vector2(-10, -9 + y), Vector2(1.2, 3), Palette.CREAM)
			_blob(ci, Vector2(0, -8 + y), Vector2(6.5, 3.5), c)
			_blob(ci, Vector2(7, -12 + y), Vector2(3.5, 3.2), c)
			_blob(ci, Vector2(8.5, -11 + y), Vector2(1.8, 1.4), Palette.CREAM)
			_blob(ci, Vector2(6, -15.5 + y), Vector2(1.2, 1.2), Palette.CREAM)
		"takin":  # bulky golden body on sturdy legs, big head with curled horns
			if legs:
				_legs(ci, [-5.0, 5.0], 6.0, dk, step, 2.0)
			_blob(ci, Vector2(0, -12 + y), Vector2(8.5, 5.5), c)
			_blob(ci, Vector2(9, -12 + y), Vector2(4, 4), dk)
			for s in [-1.0, 1.0]:  # horns sweep out, then curl up
				ci.draw_colored_polygon(PackedVector2Array([Vector2(9 + s, -16 + y), Vector2(9 + s * 5.5, -20 + y),
					Vector2(9 + s * 3.5, -14.5 + y)]), Palette.shade(Palette.STONE, 0.12))
		"klipspringer":  # small antelope on tiptoe: thin long legs, short spiky horns
			if legs:
				_legs(ci, [-3.0, 3.5], 8.0, dk, step, 1.0)
			_blob(ci, Vector2(0, -12 + y), Vector2(5.5, 3), c)
			_blob(ci, Vector2(6.5, -16 + y), Vector2(2.4, 2.2), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(5.2, -17.5 + y), Vector2(6.5, -21.5 + y), Vector2(7.2, -17.5 + y)]), Palette.INK)
			_blob(ci, Vector2(8.5, -15.5 + y), Vector2(1, 1), Palette.INK)
		"shoebill":  # tall grey bird on long legs, a huge clog bill
			if legs:
				_legs(ci, [-1.5, 1.5], 9.0, dk, step * 0.6, 0.8)
			_blob(ci, Vector2(-1, -14 + y), Vector2(5, 5.5), c)
			_blob(ci, Vector2(2, -22 + y), Vector2(3, 3), c)
			_blob(ci, Vector2(6.5, -21 + y), Vector2(3.5, 1.8), Palette.WOOD)
		"puffin":  # small and upright: dark back, white front, bright bill
			if legs:
				_legs(ci, [-1.5, 1.5], 2.0, Palette.CLAY, step * 0.6, 1.2)
			_blob(ci, Vector2(0, -7 + y), Vector2(4, 5), c)
			_blob(ci, Vector2(1.5, -6.5 + y), Vector2(2.4, 3.8), Palette.CLOUD)
			_blob(ci, Vector2(1, -13 + y), Vector2(2.8, 2.6), c)
			_blob(ci, Vector2(1.8, -13 + y), Vector2(1.5, 1.3), Palette.CLOUD)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(3.3, -14.5 + y), Vector2(6.5, -12.8 + y), Vector2(3.3, -11.5 + y)]), Palette.CLAY)
		"hornbill":  # dark body and long tail, a big curved yellow bill with a casque
			if legs:
				_legs(ci, [-1.5, 1.5], 3.0, dk, step * 0.6, 1.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, -8 + y), Vector2(-13, -4 + y), Vector2(-12, -2 + y), Vector2(-3, -5 + y)]), dk)
			_blob(ci, Vector2(0, -9 + y), Vector2(5, 4), c)
			_blob(ci, Vector2(3, -15 + y), Vector2(2.8, 2.6), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(5, -16.5 + y), Vector2(9, -16 + y), Vector2(12, -12 + y),
				Vector2(5, -13.5 + y)]), Palette.BUTTER)
			_blob(ci, Vector2(7, -17.5 + y), Vector2(2.5, 1), Palette.CLAY)
	if swim:  # the water line hides the rest
		ci.draw_colored_polygon(Squircle.points(Vector2(0, -0.5), Vector2(12, 4.5), 2.0, 24), Palette.WATER)
		ci.draw_arc(Vector2(0, 0), 10.0, PI * 0.15, PI * 0.85, 12, Color(Palette.CLOUD, 0.6), 1.0, true)
	ci.draw_set_transform(Vector2.ZERO)

static func _blob(ci: CanvasItem, c: Vector2, half: Vector2, col: Color, n := 2.6) -> void:
	ci.draw_colored_polygon(Squircle.points(c, half, n, 24), col)

## Legs at x offsets `xs`, `h` px tall, stepping by `step` (front and back pairs in opposition).
static func _legs(ci: CanvasItem, xs: Array, h: float, col: Color, step: float, w := 1.6) -> void:
	for i in xs.size():
		var x: float = xs[i] + (step if i % 2 == 0 else -step) * 0.5
		_blob(ci, Vector2(x, -h * 0.5 - 1.0), Vector2(w * 0.7, h * 0.5 + 1.0), col, 4.0)
