extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var seen := {}
	ok(Buildings.themes().keys() == ["zoo", "festival", "cinema", "conference"], "four themes, in T order")
	ok(Buildings.get_def("conf_stage")["footprint"] == Vector2i(3, 2), "Main Stage is 3x2")
	ok(Specialties.required("conf_stage") == "tech" and Specialties.for_theme("conference").has("tech")
		and not Specialties.for_theme("zoo").has("tech"), "Tech: conference only, needed for the Main Stage")
	ok(Buildings.family("conf_pavilion") == ["conf_booth", "conf_expo", "conf_pavilion"], "booth sizes are one family")
	for theme: String in Buildings.themes():
		Buildings.use(theme)
		ok(Buildings.ids_with_role("entrance").size() == 1, theme + ": exactly one entrance")
		for role: String in Buildings.ROLES:
			ok(Buildings.ids_with_role(role).size() >= 1, theme + ": has a " + role)
		for id: String in Buildings.ids():
			ok(not seen.has(id), "id unique across themes: " + id)
			seen[id] = true
			var b: Dictionary = Buildings.get_def(id)
			ok(b["role"] in Buildings.ROLES, "known role: " + id)
			if b["role"] in ["attraction", "decor"]:
				ok(b.get("appeal", 0) > 0, "appeal: " + id)
			if b["role"] == "attraction":
				ok(b.get("capacity", 0) > 0, "capacity: " + id)
			if b["role"] == "shop":
				ok(b.get("price", 0) > 0, "price: " + id)
	Buildings.use("zoo")
	ok(Buildings.get_def("fest_stage")["name"] == "Stage", "get_def finds other theme's id")
	ok(not Buildings.ids().has("fest_stage"), "ids() is the active theme only")
	ok(Buildings.get_def("nope").is_empty(), "unknown id -> {}")
	# placed buildings survive a theme swap
	var map := ParkMap.new()
	ok(map.place("zoo_gate", Vector2i(0, 0)), "place zoo gate")
	Buildings.use("festival")
	ok(map.place("fest_stage", Vector2i(4, 4)), "place stage after swap")
	ok(map.remove_at(Vector2i(0, 0)), "remove zoo gate while festival active")
	Buildings.use("zoo")
	done()
