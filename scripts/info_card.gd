class_name InfoCard
extends CanvasLayer
# Select mode UI: the right-side card for the clicked building or person (slides in, updates every
# frame) and the small hover tooltip. Buttons emit `action`; main does the work.

signal action(name: String)  # "upgrade", "repair", "demolish", "accuse"

const WIDTH := 270.0
const BOTTOM := Hud.MARGIN * 2 + Hud.VISIT_SIZE  # card bottom sits above the Visit button; toasts above it stop at top()

var sim: ParkSim
var map: ParkMap
var origin := GridView.NONE  # building on the card
var person := -1  # guest id on the card
var staff := -1  # staff index on the card
var title := Hud._label(22)
var body := Hud._label(16)
var upgrade := _action("upgrade")
var repair := _action("repair")
var demolish := _action("demolish")
var accuse := _action("accuse")
var specs := HFlowContainer.new()  # a builder's specialty toggles; only the choosable or chosen ones show
var warning := Hud._label(13)
var tip := Hud._label(14)
var _panel := PanelContainer.new()
var _tip := PanelContainer.new()
var _slide: Tween

func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", BuildBar.box(Palette.CREAM, 22))
	_panel.custom_minimum_size = Vector2(WIDTH, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_color_override("font_color", Palette.shade(Palette.CORAL, 0.35))
	warning.text = "If they're innocent you pay $%d" % ParkSim.WRONGFUL_FINE
	specs.add_theme_constant_override("h_separation", 6)
	specs.add_theme_constant_override("v_separation", 6)
	for s: String in Specialties.ALL:
		var b := _action("spec_" + s)
		b.text = Specialties.ALL[s]["name"]
		b.toggle_mode = true
		b.set_meta("spec", s)
		b.add_theme_font_size_override("font_size", 13)
		for k in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(k, BuildBar.box(Specialties.ALL[s]["color"]))
		for k in ["normal", "hover", "pressed", "hover_pressed"]:
			(b.get_theme_stylebox(k) as StyleBoxFlat).set_content_margin_all(5)
		specs.add_child(b)
	for c in [title, body, specs, upgrade, repair, demolish, accuse, warning]:
		col.add_child(c)
	_panel.add_child(col)
	_panel.visible = false
	add_child(_panel)
	_tip.add_theme_stylebox_override("panel", BuildBar.box(Palette.CREAM, 12))
	(_tip.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(6)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(tip)
	_tip.visible = false
	add_child(_tip)

func _action(name: String) -> Button:
	var b := Hud._button("", func() -> void: action.emit(name))
	b.add_theme_stylebox_override("disabled", BuildBar.box(Palette.STONE))
	b.add_theme_color_override("font_disabled_color", Color(Palette.INK, 0.55))
	return b

func is_open() -> bool:
	return _panel.visible

## Screen y of the card's top edge.
func top() -> float:
	return _panel.position.y

func show_building(o: Vector2i) -> void:
	origin = o
	person = -1
	staff = -1
	_open()

func show_person(guest_id: int) -> void:
	origin = GridView.NONE
	person = guest_id
	staff = -1
	_open()

func show_staff(i: int) -> void:
	origin = GridView.NONE
	person = -1
	staff = i
	_open()

func close() -> void:
	origin = GridView.NONE
	person = -1
	staff = -1
	_panel.visible = false

func _open() -> void:
	_process(0.0)
	var to := _panel.get_viewport_rect().size.x - WIDTH - 16
	if not _panel.visible:
		_panel.visible = true
		_panel.position.x = to + WIDTH + 32
		if _slide:
			_slide.kill()
		_slide = Motion.slide(_panel, to)

## Tooltip near the mouse; "" hides it.
func hover(text: String, at: Vector2) -> void:
	_tip.visible = text != ""
	tip.text = text
	_tip.reset_size()
	_tip.position = at + Vector2(16, -_tip.size.y - 6)

## "Snack Stand · Lv 2" (no level for paths, gates and other buildings that never upgrade).
static func building_name(m: ParkMap, o: Vector2i) -> String:
	var id: String = m.buildings[o]
	var n: String = Buildings.get_def(id)["name"]
	return "%s · Lv %d" % [n, m.level(o)] if Buildings.upgradable(id) else n

static func guest_title(g: Dictionary) -> String:
	return "Wanted guest" if g["wanted"] else "Guest"  # hidden actors look like everyone else

func _process(_delta: float) -> void:
	if origin != GridView.NONE:
		if not map.buildings.has(origin):
			close()
			return
		_building()
	elif person >= 0:
		var g := _guest()
		if g.is_empty():
			close()
			return
		title.text = guest_title(g)
		body.text = "Mood: %d / 100\nSpent: $%d" % [roundi(g["mood"]), g["spent"]]
		accuse.text = "Accuse"
		for b in [upgrade, repair, demolish]:
			b.visible = false
		accuse.visible = true
		warning.visible = true
		specs.visible = false
	elif staff >= 0 and staff < sim.staff.size():
		title.text = (sim.staff[staff]["kind"] as String).capitalize()
		body.text = "Your staff"
		for b in [upgrade, repair, demolish, accuse, warning, specs]:
			b.visible = false
	_panel.reset_size()
	_panel.position.y = _panel.get_viewport_rect().size.y - _panel.size.y - BOTTOM

func _guest() -> Dictionary:
	for g in sim.guests:
		if g["id"] == person:
			return g
	return {}

func _building() -> void:
	var id: String = map.buildings[origin]
	var d := Buildings.leveled(id, map.level(origin))
	title.text = building_name(map, origin)
	var lines: Array[String] = []
	match d["role"]:
		"shop": lines.append("Shop · sells at $%d" % d["price"])
		"attraction": lines.append("Attraction · appeal %d, holds %d" % [d["appeal"], d["capacity"]])
		"decor": lines.append("Decor · cheers up guests nearby")
		"entrance": lines.append("Entrance · $%d a guest" % ParkSim.ENTRY_FEE)
		"staff": lines.append(_builder_line())
		_: lines.append("Path")
	var j := sim.job_at(origin)
	if not j.is_empty():
		lines.append(site_line(sim, j))
	elif d["role"] in ["shop", "attraction", "entrance"]:
		var t: Dictionary = sim.today.get(origin, {"guests": 0, "income": 0})
		lines.append("Today: %d guests · $%d" % [t["guests"], t["income"]])
	if j.is_empty():
		lines.append(_status())
	body.text = "\n".join(lines)
	var builder: bool = d["role"] == "staff" and not sim.builder_of(origin).is_empty()
	specs.visible = builder
	if builder:
		for b: Button in specs.get_children():
			b.visible = b.get_meta("spec") in map.spec_choices(origin)
			b.set_pressed_no_signal(b.get_meta("spec") in map.specs(origin))

	var cost := map.upgrade_cost(origin)
	upgrade.visible = Buildings.upgradable(id) and j.is_empty()
	upgrade.disabled = not map.can_upgrade(origin)
	if cost < 0:
		upgrade.text = "Upgrade · max level"
	elif map.upgrade_needs(origin) > 0:
		upgrade.text = "Lv %d unlocks at park level %d" % [map.level(origin) + 1, map.upgrade_needs(origin)]
	elif map.money < cost:
		upgrade.text = "Upgrade $%d · need $%d more" % [cost, cost - map.money]
	else:
		upgrade.text = "Upgrade to Lv %d · $%d" % [map.level(origin) + 1, cost]
	repair.visible = sim.closed.has(origin)
	repair.disabled = sim.money < sim.repair_cost(origin)
	repair.text = "Repair now · $%d" % sim.repair_cost(origin)
	demolish.visible = true
	demolish.text = "Demolish · +$%d back" % sim.demolish_refund(origin)
	accuse.visible = false
	warning.visible = false

## "Building · 40% · Bo is working on it" / "Upgrading to Lv 2 · 0% · Waiting for a builder".
static func site_line(s: ParkSim, j: Dictionary) -> String:
	var what := "Building" if j["level"] == 1 else "Upgrading to Lv %d" % j["level"]
	var pct := roundi(100.0 * (1.0 - float(j["left"]) / j["total"]))
	var need := Specialties.required(j["id"])
	var who := "Waiting for a %s specialist" % Specialties.ALL[need]["name"] if need != "" else "Waiting for a builder"
	for b in s.builders:
		if b["name"] == j["builder"]:
			who = "%s is %s" % [b["name"], "working on it" if b["state"] == "work" else "on the way"]
	return "%s · %d%%\n%s" % [what, pct, who]

func _builder_line() -> String:
	var b := sim.builder_of(origin)
	if b.is_empty():
		return "Builder shed · houses one builder"
	var j := sim.job_of(b)
	var doing := "resting at home" if j.is_empty() else "building the %s" % Buildings.get_def(j["id"])["name"]
	var have: Array = map.specs(origin).map(func(s: String) -> String: return Specialties.ALL[s]["name"])
	var free := ParkLevel.cap("specialties", map.park_level()) - have.size()
	var spec := "Specialty: pick one below" if have.is_empty() else ("Specialties: " if have.size() > 1 else "Specialty: ") + " + ".join(have)
	if free > 0 and not have.is_empty():
		spec += " · pick a second"
	return "Builder shed · home of %s\n%s is %s\n%s" % [b["name"], b["name"], doing, spec]

## The building's state in words: wrecked (with the reopen countdown), littered, robbed, spied, or open.
func _status() -> String:
	var out: Array[String] = []
	if sim.closed.has(origin):
		out.append("Wrecked. Reopens in %d s" % ceili(float(sim.closed[origin] - sim.tick) / ParkSim.TPS))
	var st := sim.building_status(origin)
	if "littered" in st:
		out.append("Littered. A janitor will clean it")
	if "robbed" in st:
		out.append("Robbed not long ago")
	for e: Dictionary in sim.events:
		if e["kind"] == "spied" and e["origin"] == origin and sim.tick - e["tick"] < ParkSim.ROBBED_TICKS:
			out.append("Someone studied it")
			break
	return "\n".join(out) if not out.is_empty() else "Open, all fine"
