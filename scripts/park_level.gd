class_name ParkLevel
# Park level (docs/design/game.md → Park level): XP from guests fills a ring; each level unlocks things.

const XP_SERVED := 1  # a guest finished their first visit
const XP_HAPPY := 1   # bonus when a guest leaves happy
const HAPPY := 60.0   # mood at or above this on the way out counts as happy (same as the HUD's happy face)
# Total XP needed to reach level i + 1 (index 0 = level 1).
const THRESHOLDS := [0, 30, 80, 150, 250, 380, 550, 760, 1000, 1300]
const MAX := 10
# Park level -> what it raises or opens. `plots` = land plots you may buy beyond the start area. `variants` = the
# biggest size variant you may build (index in Buildings.family: 1 = the 2×1, 2 = the 2×2). `fences` (habitat
# styles) and `animals` (Animals ids) list what opens there; anything not listed is open from the start.
const UNLOCKS := {
	2: {"building_level": 2, "plots": 1, "variants": 1, "fences": ["glass"], "animals": ["capybara"]},
	3: {"sheds": 2, "fences": ["wall"], "animals": ["klipspringer"]},
	4: {"building_level": 3, "plots": 2, "variants": 2, "fences": ["net"], "animals": ["hornbill"]},
	5: {"sheds": 3, "animals": ["platypus"]},
	6: {"specialties": 2, "plots": 3, "animals": ["takin"]},
	7: {"sheds": 4},
	8: {"plots": 4, "animals": ["shoebill"]},
	10: {"plots": 5},
}
const BASE := {"building_level": 1, "sheds": 1, "specialties": 1, "plots": 0, "variants": 0}

static func of(xp: int) -> int:
	var lv := 1
	while lv < MAX and xp >= THRESHOLDS[lv]:
		lv += 1
	return lv

## 0..1 of the way from this level to the next (1 at the max level).
static func progress(xp: int) -> float:
	var lv := of(xp)
	if lv >= MAX:
		return 1.0
	return float(xp - THRESHOLDS[lv - 1]) / (THRESHOLDS[lv] - THRESHOLDS[lv - 1])

## The value of `key` (building_level, sheds, specialties, plots) at park level `lv`.
static func cap(key: String, lv: int) -> int:
	var v: int = BASE[key]
	for l: int in UNLOCKS:
		if l <= lv and UNLOCKS[l].has(key):
			v = UNLOCKS[l][key]
	return v

## Lowest park level where `key` reaches `value`, or -1 if never.
static func needed(key: String, value: int) -> int:
	for l: int in UNLOCKS:
		if UNLOCKS[l].get(key, 0) >= value:
			return l
	return -1

## Park level where `name` in list `key` (fences, animals) opens: 1 if it isn't listed.
static func opens(key: String, name: String) -> int:
	for l: int in UNLOCKS:
		if name in UNLOCKS[l].get(key, []):
			return l
	return 1

## Park level building `id` opens at: its fence style for a habitat, else its size variant.
static func building_opens(id: String) -> int:
	var d := Buildings.get_def(id)
	if d.has("habitat"):
		return opens("fences", d["habitat"])
	var i := Buildings.family(id).find(id)
	return 1 if i <= 0 else needed("variants", i)

## Card lines for what level `lv` unlocks.
static func describe(lv: int) -> Array[String]:
	var out: Array[String] = []
	for k: String in UNLOCKS.get(lv, {}):
		var v: Variant = UNLOCKS[lv][k]
		match k:
			"variants": out.append("Bigger buildings: the %s size" % ["2×1", "2×2"][v - 1])
			"fences": out.append("%s habitats" % ", ".join(v.map(func(f: String) -> String: return f.capitalize())))
			"animals": out.append("New animal: %s" % ", ".join(v.map(func(a: String) -> String: return Animals.ALL[a]["name"])))
			"building_level": out.append("Buildings up to Lv %d" % v)
			"sheds": out.append("%d builder sheds" % v)
			"specialties": out.append("A second builder specialty")
			"plots": out.append("Buy up to %d land plot%s" % [v, "" if v == 1 else "s"])
	return out
