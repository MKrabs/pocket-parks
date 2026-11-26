extends SceneTree
# Save and load: a packed park survives the round trip through text and a file; bad files give {} (= a new park).

var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var m := ParkMap.new()
	m.start_small()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(4, 11))
	for x in range(5, 16):
		m.place("path", Vector2i(x, 11))
	m.place("builder_shed", Vector2i(6, 12))
	m.specialties[Vector2i(6, 12)] = ["heavy"]
	m.owned[Vector2i(0, 2)] = true
	m.bought = 1
	m.money = 2000
	m.xp = 340
	var sim := ParkSim.new(m, 3)
	ok(sim.build("enclosure", Vector2i(6, 8)) and sim.build("snack_stand", Vector2i(9, 12), 1), "build a site and a turned shop")
	sim.hire("guard")
	sim.hire("janitor")
	sim.upgrade_staff(0)
	for i in 30:
		sim.step()
	ok(not sim.jobs.is_empty() and sim.builders[0]["state"] != "home", "a builder on its way to a site")
	var saved := SaveGame.pack(m, sim, 4, ["aviary"])

	var path := "user://test_save_%d.json" % OS.get_process_id()
	SaveGame.write(path, saved)
	var d := SaveGame.read(path)
	DirAccess.remove_absolute(path)
	ok(not d.is_empty(), "the file reads back")
	var m2 := ParkMap.new()
	var sim2 := SaveGame.restore(d, m2)
	var again := SaveGame.pack(m2, sim2, d["day"], d["stolen"])
	ok(again == saved, "save then load gives an equal park")
	ok(m2.occupied == m.occupied and m2.rotation(Vector2i(9, 12)) == 1 and sim2.staff[0]["level"] == 2, "footprints, turns and staff levels")
	ok(sim2.job_at(Vector2i(6, 8))["builder"] == sim.builders[0]["name"], "the site keeps its builder")
	for i in 10:
		sim2.step()  # the loaded park runs

	var old := saved.duplicate()
	old["version"] = SaveGame.VERSION + 1
	ok(SaveGame.from_text(SaveGame.to_text(old)).is_empty(), "unknown version: new park")
	var text := SaveGame.to_text(saved)
	for bad in ["", "{", "[1, 2]", "{\"a\": 1}", text.substr(0, text.length() / 2), text.replace("\"i:", "\"s:")]:
		ok(SaveGame.from_text(bad).is_empty(), "corrupt file: new park (%s...)" % bad.left(12))
	ok(SaveGame.read("user://no_such_park.json").is_empty(), "no file: new park")
	done()
