class_name Specialties
# Builder specialties (docs/design/game.md → Building). All are available, no XP or training.
# A building def may carry "specialty" (an id below) and "mode": "only" (specialist-only) or "faster" (2× for the specialist).

const ALL := {
	"landscaper": {"name": "Landscaper", "glyph": "L", "color": Palette.MOSS},
	"water": {"name": "Water", "glyph": "W", "color": Palette.WATER},
	"aviary": {"name": "Aviary", "glyph": "A", "color": Palette.SKY},
	"heavy": {"name": "Heavy", "glyph": "H", "color": Palette.STONE},
	"carpenter": {"name": "Carpenter", "glyph": "C", "color": Palette.WOOD},
}

## Work per tick a builder with `specs` puts into building `id`: 0 = can't (specialist-only), 1, or 2 (faster).
static func speed(specs: Array, id: String) -> int:
	var d := Buildings.get_def(id)
	var s: String = d.get("specialty", "")
	if s == "":
		return 1
	if d["mode"] == "only":
		return 1 if s in specs else 0
	return 2 if s in specs else 1

## The specialty a building can't be built without, or "".
static func required(id: String) -> String:
	var d := Buildings.get_def(id)
	return d["specialty"] if d.get("mode", "") == "only" else ""

## A small squircle badge in the specialty's colour with its letter.
static func glyph(ci: CanvasItem, at: Vector2, spec: String, r := 9.0) -> void:
	var c: Color = ALL[spec]["color"]
	ci.draw_colored_polygon(Squircle.points(at, Vector2(r, r) + Vector2.ONE, 4.0, 32), Palette.shade(c, 0.22))
	ci.draw_colored_polygon(Squircle.points(at, Vector2(r, r), 4.0, 32), c)
	var f := ThemeDB.fallback_font
	var size := roundi(r * 1.3)
	var w := f.get_string_size(ALL[spec]["glyph"], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(f, at + Vector2(-w * 0.5, size * 0.36), ALL[spec]["glyph"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Palette.INK)
