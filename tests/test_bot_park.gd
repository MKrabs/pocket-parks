extends SceneTree
# Bot parks: one entrance, everything on a path, paths connected, deterministic.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	for theme: String in ["zoo", "festival", "cinema"]:
		for size: String in ["small", "large"]:
			for s in 20:
				check(theme, s, size)
	ok(BotPark.generate("zoo", 1).buildings != BotPark.generate("zoo", 2).buildings, "seeds differ")
	done()

func role(map: ParkMap, origin: Vector2i) -> String:
	return Buildings.get_def(map.buildings[origin])["role"]

func check(theme: String, s: int, size: String) -> void:
	var tag := "%s/%s/%d" % [theme, size, s]
	var map := BotPark.generate(theme, s, size)
	ok(map.buildings == BotPark.generate(theme, s, size).buildings, tag + " same seed, same park")
	var cat: Dictionary = Buildings.themes()[theme]
	var count := {}
	var entrance := Vector2i(-1, -1)
	for o: Vector2i in map.buildings:
		ok(cat.has(map.buildings[o]), tag + " only theme buildings")
		var r := role(map, o)
		count[r] = count.get(r, 0) + 1
		if r == "entrance":
			entrance = o
		if r == "attraction" or r == "shop":
			ok(BotPark.touches_path(map, map.cells(o)), tag + " %s touches a path" % map.buildings[o])
	ok(count.get("entrance", 0) == 1, tag + " exactly one entrance")
	ok(entrance.x == 0 or entrance.y == 0 or entrance.x == IsoGrid.SIZE.x - 1 or entrance.y == IsoGrid.SIZE.y - 1, tag + " entrance on edge")
	var cfg: Dictionary = BotPark.SIZES[size]
	var painted := map.habitats.size()
	ok(count.get("attraction", 0) - painted == cfg["attractions"], tag + " attraction count %d" % count.get("attraction", 0))
	ok((painted >= 1 and painted <= 2) == (theme == "zoo"), tag + " zoo parks paint a habitat or two (%d)" % painted)
	ok(count.get("shop", 0) == cfg["shops"], tag + " shop count")
	ok(count.get("decor", 0) > 0, tag + " has decor")
	# Flood from the entrance over path tiles; every path tile must be reached.
	var seen := {entrance: true}
	var todo: Array[Vector2i] = [entrance]
	while todo:
		var c: Vector2i = todo.pop_back()
		for d in BotPark.DIRS:
			var n: Vector2i = c + d
			if not seen.has(n) and map.buildings.has(n) and role(map, n) == "path":
				seen[n] = true
				todo.append(n)
	ok(seen.size() - 1 == count.get("path", 0), tag + " all paths connected to entrance")
