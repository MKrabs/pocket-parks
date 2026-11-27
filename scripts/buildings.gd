class_name Buildings
# Building lookup over the theme packs (scripts/themes/*.gd). Each entry: name, role, footprint (tiles),
# cost, parts, plus appeal (attraction, decor), capacity (attraction, shop), price (shop), variants (see family()).
# A part is one extruded squircle block: at/half in tiles (relative to the footprint centre),
# h = height px, z = lift px, color. Parts are drawn in list order (back to front).
# A part with a "kind" is a shaped silhouette (dome, wall, glass...), see shaped().
# Ids are unique across themes, so get_def finds a building from any theme.

const ROLES := ["entrance", "path", "attraction", "shop", "decor", "staff"]

static var active := "zoo"
static var _themes: Dictionary = {}  # theme id -> {building id -> def}, filled on first use

static func themes() -> Dictionary:
	if _themes.is_empty():
		_themes = {"zoo": ZooTheme.catalog(), "festival": FestivalTheme.catalog(), "cinema": CinemaTheme.catalog(),
			"amusement": AmusementTheme.catalog(), "conference": ConferenceTheme.catalog()}
	return _themes

static func use(theme_id: String) -> void:
	assert(themes().has(theme_id), "unknown theme " + theme_id)
	active = theme_id

## Definition for any building id, searching every theme. {} if unknown.
static func get_def(id: String) -> Dictionary:
	for t: Dictionary in themes().values():
		if t.has(id):
			return t[id]
	return {}

## Building ids of the active theme, in catalog order.
static func ids() -> Array:
	return themes()[active].keys()

static func ids_with_role(role: String) -> Array:
	return ids().filter(func(id: String) -> bool: return themes()[active][id]["role"] == role)

## Size variants of `id`, smallest first (the first one names them in "variants"); [id] if it has none.
static func family(id: String) -> Array:
	for t: Dictionary in themes().values():
		for d: Dictionary in t.values():
			if id in d.get("variants", []):
				return d["variants"]
	return [id]

const MAX_LEVEL := 3

static func upgradable(id: String) -> bool:
	return get_def(id)["role"] in ["attraction", "shop", "decor"] and not get_def(id).has("habitat")

## Def with the level effect applied: +50% appeal, capacity and price per level above 1.
## The sim and the UI both read this, so they agree.
static func leveled(id: String, level: int) -> Dictionary:
	var d: Dictionary = get_def(id).duplicate()
	var f := 1.0 + 0.5 * (level - 1)
	for k in ["appeal", "capacity", "price"]:
		if d.has(k):
			d[k] = roundi(d[k] * f)
	return d

static func part(at: Vector2, half: Vector2, h: float, color: Color, z := 0.0) -> Dictionary:
	return {"at": at, "half": half, "h": h, "z": z, "color": color}

## A part BuildingView draws as one silhouette instead of a block: kind "dome", "water", "wheel" (upright, in the plane of half's long axis), "balloons", or a ring
## ("wall", "fence", "glass") following the squircle outline of `half`.
static func shaped(kind: String, half: Vector2, h: float, color: Color, z := 0.0) -> Dictionary:
	var p := part(Vector2.ZERO, half, h, color, z)
	p["kind"] = kind
	return p

## Entrance arch on a 1x1 tile: two posts along y and a top beam, so a path along x runs through it.
static func arch(post: Color, top: Color) -> Array:
	return [
		part(Vector2(0, -0.32), Vector2(0.1, 0.1), 26, post),
		part(Vector2(0, 0.32), Vector2(0.1, 0.1), 26, post),
		part(Vector2.ZERO, Vector2(0.14, 0.46), 7, top, 26),
	]

## Builder shed on a 1x1 tile: wooden hut, roof, and a BUTTER hard-hat sign on the +x face.
static func shed(roof: Color) -> Array:
	return [
		part(Vector2.ZERO, Vector2(0.3, 0.3), 16, Palette.WOOD),
		part(Vector2.ZERO, Vector2(0.38, 0.38), 5, roof, 16),
		part(Vector2(0.33, 0), Vector2(0.04, 0.17), 9, Palette.STONE, 4),
		part(Vector2(0.37, 0), Vector2(0.03, 0.11), 4, Palette.BUTTER, 8),
		part(Vector2(0.37, 0), Vector2(0.03, 0.06), 3, Palette.BUTTER, 12),
	]

static func tree(at: Vector2) -> Array:
	return [
		part(at, Vector2(0.1, 0.1), 14, Palette.WOOD),
		part(at, Vector2(0.36, 0.36), 12, Palette.MOSS, 12),
		part(at, Vector2(0.24, 0.24), 10, Palette.MOSS, 24),
	]
