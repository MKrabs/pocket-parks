extends SceneTree
# Animals: needs scoring, comfort from habitat contents, appeal following comfort, the picker's categories, buying.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	# Picker: only the fence's category.
	ok(Animals.ALL.size() == 9, "9 animals")
	ok(Animals.picker("glass") == ["otter", "capybara", "platypus"], "glass: water animals")
	ok(Animals.picker("net") == ["shoebill", "puffin", "hornbill"], "net: birds")
	ok(Animals.picker("wall") == ["red_panda", "takin", "klipspringer"], "wall: highlands")
	ok(Animals.picker("fence") == ["capybara", "red_panda", "klipspringer"], "fence: the starter set, one per open-ground category")
	for f: String in ["glass", "net", "wall"]:
		for a: String in Animals.picker(f):
			ok(Animals.ALL[a]["category"] == Animals.FENCE_CATEGORY[f], "%s offers only its category (%s)" % [f, a])

	# Needs: a bare 3×3 meets the otter's size (6) but nothing else.
	var h := {"cells": ParkMap.rect_cells(Rect2i(0, 0, 3, 3)), "fence": "glass", "animal": "", "count": 0, "items": []}
	var ns := Animals.needs("otter", h)
	ok(ns[0]["need"] == "cells" and ns[0]["ok"], "otter has room in 9 cells")
	ok(ns.map(func(e: Dictionary) -> String: return e["need"]) == ["cells", "water", "rocks", "shelter"], "otter needs: %s" % [ns])
	ok(not ns[1]["ok"] and ns[1]["text"] == "needs 40% more water", "missing water in words: %s" % ns[1]["text"])
	var bare := Animals.comfort("otter", h)
	ok(bare == 25, "bare habitat: only the size counts (%d)" % bare)
	ok(not Animals.needs("capybara", {"cells": ParkMap.rect_cells(Rect2i(0, 0, 2, 2)), "items": []})[0]["ok"], "capybara needs 9 cells")

	# Comfort changes with contents: 2 of 9 water cells = 22% (needs 18% more), then a full set.
	h["items"].append({"id": "pool", "cells": [Vector2i(0, 0), Vector2i(1, 0)]})
	var some := Animals.comfort("otter", h)
	ok(some > bare, "a pool raises comfort (%d > %d)" % [some, bare])
	ok(Animals.needs("otter", h)[1]["text"] == "needs 18% more water", "partly met water: %s" % Animals.needs("otter", h)[1]["text"])
	h["items"].append({"id": "pool", "cells": [Vector2i(2, 0), Vector2i(0, 1)]})
	h["items"].append({"id": "rocks", "cells": [Vector2i(2, 2)]})
	h["items"].append({"id": "shelter", "cells": [Vector2i(1, 2)]})
	ok(Animals.comfort("otter", h) == 100, "every need met: 100 (%d)" % Animals.comfort("otter", h))
	ok(Animals.needs("otter", h).all(func(e: Dictionary) -> bool: return e["ok"]), "all ticked")
	var wf := {"cells": h["cells"], "items": [{"id": "waterfall", "cells": [Vector2i(0, 0)]}]}
	ok(Animals.terrain(wf)["water"] > 0.0 and Animals.terrain(wf)["rocks"] > 0.0, "a waterfall counts as water and rocks")

	# Appeal follows comfort.
	ok(Animals.appeal_factor(h) == 0.5, "no animals: half appeal")
	h["animal"] = "otter"
	h["count"] = 2
	var happy := Animals.appeal_factor(h)
	h["items"] = []
	var sad := Animals.appeal_factor(h)
	ok(happy > sad and happy == 2.0, "comfortable animals draw more guests (%s > %s)" % [happy, sad])

	# Buying: price, one species, up to MAX, only the fence's category; appeal reaches the sim.
	var m := ParkMap.new()
	m.money = 1 << 20
	m.xp = ParkLevel.THRESHOLDS[-1]  # everything unlocked (test_unlocks covers the gates)
	m.place("zoo_gate", Vector2i(4, 11))
	for x in range(5, 12):
		m.place("path", Vector2i(x, 11))
	var o := m.paint("habitat_glass", Rect2i(6, 8, 3, 3))
	ok(o.x >= 0, "painted a glass habitat")
	var before := m.money
	ok(not m.buy_animal(o, "puffin"), "a puffin can't live behind glass")
	ok(m.buy_animal(o, "otter") and m.money == before - Animals.ALL["otter"]["price"], "bought an otter for its price")
	ok(not m.buy_animal(o, "capybara"), "one species per habitat")
	for i in 3:
		m.buy_animal(o, "otter")
	ok(m.habitats[o]["count"] == Animals.MAX and not m.buy_animal(o, "otter"), "at most %d" % Animals.MAX)
	m.money = 0
	m.habitats[o]["count"] = 1
	ok(m.animal_block(o, "otter").begins_with("Need $"), "can't afford: says how much")
	var sim := ParkSim.new(m, 1)
	var a0 := _appeal(sim, o)
	m.habitats[o]["items"] = [{"id": "pool", "cells": ParkMap.rect_cells(Rect2i(6, 8, 3, 2))}, {"id": "shelter", "cells": [Vector2i(6, 10)]},
		{"id": "rocks", "cells": [Vector2i(7, 10)]}]
	sim.load_map(m)
	ok(_appeal(sim, o) > a0, "sim appeal rises with comfort (%d > %d)" % [_appeal(sim, o), a0])
	done()

func _appeal(sim: ParkSim, o: Vector2i) -> int:
	for a: Dictionary in sim._targets:
		if a["origin"] == o:
			return a["appeal"]
	return -1
