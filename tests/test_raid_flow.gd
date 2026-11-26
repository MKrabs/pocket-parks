extends SceneTree
# End-to-end raid flow through main.gd (no mouse): Go -> raid runs out -> Back home -> loot + blueprint in the bar.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)

var main: Node
var frame := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _process(_delta: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	var before: int = main.sim.money
	main.raid_panel.go.emit({"theme": "festival", "size": "small", "seed": 7, "guards": 0},
		{"thief": 1, "spy": 1})
	ok(main.raid_sim != null, "raid started")
	ok(main.sim.money == before - 110, "squad cost deducted: %d" % main.sim.money)
	for i in 60 * ParkSim.TPS + 10:
		main.raid_sim.step()
	var r: Dictionary = main.raid_sim.raid_result()
	ok(r["blueprints"].size() == 1, "unguarded spy brings a blueprint: %s" % [r])
	ok(r["stolen_money"] > 0, "unguarded thief steals: %s" % [r])
	var mid: int = main.sim.money
	main._end_raid(r)
	ok(main.raid_sim == null, "back home")
	ok(main.sim.money == mid + r["stolen_money"], "loot added")
	for id: String in r["blueprints"]:
		ok(id in main.bar.stolen, "blueprint %s offered in the build bar" % id)
		ok(not Buildings.get_def(id).is_empty(), "blueprint resolves")
	quit(1 if failed else 0)
	return true
