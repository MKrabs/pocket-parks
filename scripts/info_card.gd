class_name InfoCard
extends CanvasLayer
# Select mode UI: the right-side card for the clicked building or person (slides in, updates every
# frame) and the small hover tooltip. Buttons emit `action`; main does the work.

signal action(name: String)  # "upgrade", "repair", "demolish", "accuse"

const WIDTH := 270.0
const BOTTOM := 24.0  # card bottom, px above the screen bottom (crime toasts stack from the top-right)

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
	for c in [title, body, upgrade, repair, demolish, accuse, warning]:
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
	elif staff >= 0 and staff < sim.staff.size():
		title.text = (sim.staff[staff]["kind"] as String).capitalize()
		body.text = "Your staff"
		for b in [upgrade, repair, demolish, accuse, warning]:
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
		_: lines.append("Path")
	if d["role"] in ["shop", "attraction", "entrance"]:
		var t: Dictionary = sim.today.get(origin, {"guests": 0, "income": 0})
		lines.append("Today: %d guests · $%d" % [t["guests"], t["income"]])
	lines.append(_status())
	body.text = "\n".join(lines)

	var cost := map.upgrade_cost(origin)
	upgrade.visible = Buildings.upgradable(id)
	upgrade.disabled = not map.can_upgrade(origin)
	if cost < 0:
		upgrade.text = "Upgrade · max level"
	elif map.money < cost:
		upgrade.text = "Upgrade $%d · need $%d more" % [cost, cost - map.money]
	else:
		upgrade.text = "Upgrade to Lv %d · $%d" % [map.level(origin) + 1, cost]
	repair.visible = sim.closed.has(origin)
	repair.disabled = sim.money < sim.repair_cost(origin)
	repair.text = "Repair now · $%d" % sim.repair_cost(origin)
	demolish.visible = true
	demolish.text = "Demolish · +$%d back" % map.refund(origin)
	accuse.visible = false
	warning.visible = false

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
