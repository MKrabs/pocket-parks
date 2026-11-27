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
	ok(Buildings.themes().keys() == ["zoo", "festival", "cinema"], "three themes, in T order")
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
	# the festival in full: every role, the new buildings, two more stall families, the Grill specialty
	Buildings.use("festival")
	for id: String in ["fest_band", "fest_lights", "fest_lawn", "fest_grill"]:
		ok(Buildings.ids().has(id), "festival has " + id)
	ok(Buildings.get_def("fest_lawn").get("habitat", "") == "hedge", "picnic lawn is painted, with a hedge")
	var fams := {}
	for id: String in Buildings.ids_with_role("shop"):
		fams[Buildings.family(id)[0]] = Buildings.family(id)
	ok(fams.size() == 3, "festival: three stall families")
	for f: Array in fams.values():
		ok(f.size() == 3 and Buildings.get_def(f[0])["price"] < Buildings.get_def(f[2])["price"], "three sizes, dearer when bigger: " + f[0])
	ok("grill" in Specialties.for_theme("festival") and not "grill" in Specialties.for_theme("zoo"), "Grill is the festival's own")
	ok(Specialties.required("fest_grill") == "grill", "only Grill specialists build the Big Grill")
	ok(Specialties.speed(["grill"], "fest_grill") == 1.5 and Specialties.speed([], "fest_grill") == 0.0, "grill speed")
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
