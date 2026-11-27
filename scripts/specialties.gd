class_name Specialties
# Builder specialties (docs/design/game.md → Building). All are available; each one a builder has levels up from XP.
# A building def may carry "specialty" (an id below) and "mode": "only" (specialist-only) or "faster" (anyone at 1×).
# The specialist builds its specialty's buildings at LEVEL_SPEED of its level in it.

const XP_JOB := 1   # each specialty a builder has, per finished job outside it
const XP_SPEC := 3  # the job's own specialty, per finished job
const LEVEL_XP := [0, 10, 30]  # XP a specialty needs for Lv 1, 2, 3
const LEVEL_SPEED := [1.5, 2.0, 3.0]  # work per tick on its buildings at Lv 1, 2, 3

## Specialty level (1–3) at `xp`.
static func level(xp: int) -> int:
	return LEVEL_XP.filter(func(t: int) -> bool: return xp >= t).size()

## Fraction of the way from this level to the next (1.0 at max).
static func progress(xp: int) -> float:
	var lv := level(xp)
	return 1.0 if lv >= LEVEL_XP.size() else float(xp - LEVEL_XP[lv - 1]) / (LEVEL_XP[lv] - LEVEL_XP[lv - 1])

## A finished job on building `id` adds XP to each of `specs` in `xp` (spec -> int). Returns the ones that levelled up.
static func award(xp: Dictionary, specs: Array, id: String) -> Array:
	var own: String = Buildings.get_def(id).get("specialty", "")
	var up: Array = []
	for s: String in specs:
		var before := level(xp.get(s, 0))
		xp[s] = xp.get(s, 0) + (XP_SPEC if s == own else XP_JOB)
		if level(xp[s]) > before:
			up.append(s)
	return up

const ALL := {
	"landscaper": {"name": "Landscaper", "glyph": "L", "color": Palette.MOSS},
	"water": {"name": "Water", "glyph": "W", "color": Palette.WATER},
	"aviary": {"name": "Aviary", "glyph": "A", "color": Palette.SKY, "theme": "zoo"},
	"heavy": {"name": "Heavy", "glyph": "H", "color": Palette.STONE, "theme": "zoo"},
	"carpenter": {"name": "Carpenter", "glyph": "C", "color": Palette.WOOD},
	"projection": {"name": "Projection", "glyph": "P", "color": Palette.BUTTER, "theme": "cinema"},
	"tech": {"name": "Tech", "glyph": "T", "color": Palette.CLAY, "theme": "conference"},
}

## Specialties offered in theme `t`: its own plus the shared ones (no "theme" key).
static func for_theme(t: String) -> Array:
	return ALL.keys().filter(func(s: String) -> bool: return ALL[s].get("theme", t) == t)

## Work per tick a builder with `specs` (and `xp`: spec -> int) puts into building `id`: 0 = can't (specialist-only),
## 1, or its specialist's LEVEL_SPEED.
static func speed(specs: Array, id: String, xp := {}) -> float:
	var d := Buildings.get_def(id)
	var s: String = d.get("specialty", "")
	if s == "":
		return 1.0
	if s in specs:
		return LEVEL_SPEED[level(xp.get(s, 0)) - 1]
	return 0.0 if d["mode"] == "only" else 1.0

## The specialty a building can't be built without, or "".
static func required(id: String) -> String:
	var d := Buildings.get_def(id)
	return d["specialty"] if d.get("mode", "") == "only" else ""

## A small squircle badge in the specialty's colour with its letter.
static func glyph(ci: CanvasItem, at: Vector2, spec: String, r := 9.0) -> void:
	var c: Color = ALL[spec]["color"]
	ci.draw_colored_polygon(Squircle.points(at, Vector2(r, r) + Vector2.ONE, 4.0, 32), Palette.shade(c, 0.22))
	ci.draw_colored_polygon(Squircle.points(at, Vector2(r, r), 4.0, 32), c)
	var f := Palette.FONT
	var size := roundi(r * 1.3)
	var w := f.get_string_size(ALL[spec]["glyph"], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(f, at + Vector2(-w * 0.5, size * 0.36), ALL[spec]["glyph"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Palette.INK)
