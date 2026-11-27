class_name InfoCard
extends CanvasLayer
# Select mode UI: the right-side card for the clicked building or person (slides in, updates every
# frame) and the small hover tooltip. Buttons emit `action`; main does the work.

signal action(name: String)  # "upgrade", "repair", "demolish", "accuse", "buy"

const WIDTH := 270.0
const BOTTOM := Hud.MARGIN * 2 + Hud.VISIT_SIZE  # card bottom sits above the Visit button; toasts above it stop at top()

var sim: ParkSim
var map: ParkMap
var origin := GridView.NONE  # building on the card
var person := -1  # guest id on the card
var staff := -1  # staff index on the card
var plot := GridView.NONE  # land plot for sale on the card (plot coords)
var visitor := ""  # another player's character on the card (its name)
var days := ParkSim.BAN_DAYS  # blacklist days an accusation of the visitor asks for (1–7)
var ban_row := HBoxContainer.new()
var _days := Hud._label(15)
var title := Hud._label(22)
var body := Hud._label(16)
var upgrade := _action("upgrade")
var repair := _action("repair")
var demolish := _action("demolish")
var accuse := _action("accuse")
var buy := _action("buy")
var specs := HFlowContainer.new()  # a builder's specialty toggles; only the choosable or chosen ones show
var warning := Hud._label(13)
# Habitat: animal picker (portraits, the fence's category only), needs checklist, comfort bar, buy.
var hab := VBoxContainer.new()
var picks := HBoxContainer.new()
var pick := ""  # the animal the checklist is for
var needs_text := Hud._label(14)
var comfort_text := Hud._label(14)
var comfort_bar := Control.new()
var buy_animal := _action("buy_animal")
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
		for k in ["pressed", "hover_pressed"]:
			(b.get_theme_stylebox(k) as StyleBoxFlat).content_margin_bottom = 11  # room for the XP bar
		b.draw.connect(func() -> void:  # a picked specialty's XP bar along the button's bottom
			if not b.button_pressed:
				return
			var w := b.size.x - 16.0
			var f := Specialties.progress(map.spec_xp.get(origin, {}).get(s, 0))
			b.draw_colored_polygon(Squircle.points(Vector2(b.size.x * 0.5, b.size.y - 7.0), Vector2(w * 0.5, 2.5), 4.0, 32),
				Palette.shade(Specialties.ALL[s]["color"], 0.3))
			if f > 0.0:
				b.draw_colored_polygon(Squircle.points(Vector2(8.0 + w * f * 0.5, b.size.y - 7.0), Vector2(maxf(w * f * 0.5, 2.5), 2.5), 4.0, 32),
					Palette.CREAM))
		specs.add_child(b)
	ban_row.add_theme_constant_override("separation", 8)
	ban_row.add_child(Hud._button("−", func() -> void: days = maxi(days - 1, 1)))
	_days.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_days.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ban_row.add_child(_days)
	ban_row.add_child(Hud._button("+", func() -> void: days = mini(days + 1, ParkSim.BAN_MAX)))
	picks.add_theme_constant_override("separation", 6)
	for a: String in Animals.ALL:
		var b := Hud._button(Animals.ALL[a]["name"], func() -> void: pick = a)
		b.set_meta("animal", a)
		b.custom_minimum_size = Vector2(76, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		for k in ["normal", "hover", "pressed", "hover_pressed"]:
			(b.get_theme_stylebox(k) as StyleBoxFlat).set_content_margin_all(4)
			(b.get_theme_stylebox(k) as StyleBoxFlat).content_margin_top = 50  # the portrait sits above the name
		b.draw.connect(func() -> void: Animals.draw(b, a, Vector2(b.size.x * 0.5, 46), 1.0, "walk", 0.0, 1.6))
		picks.add_child(b)
	comfort_bar.custom_minimum_size = Vector2(0, 12)
	comfort_bar.draw.connect(_draw_comfort)
	needs_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hab.add_theme_constant_override("separation", 6)
	for c in [picks, needs_text, comfort_text, comfort_bar, buy_animal]:
		hab.add_child(c)
	for c in [title, body, hab, specs, upgrade, repair, demolish, ban_row, accuse, buy, warning]:
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
	plot = GridView.NONE
	visitor = ""
	_open()

func show_person(guest_id: int) -> void:
	origin = GridView.NONE
	person = guest_id
	staff = -1
	plot = GridView.NONE
	visitor = ""
	_open()

func show_staff(i: int) -> void:
	origin = GridView.NONE
	person = -1
	staff = i
	plot = GridView.NONE
	visitor = ""
	_open()

func show_plot(p: Vector2i) -> void:
	origin = GridView.NONE
	person = -1
	staff = -1
	plot = p
	visitor = ""
	_open()

## Another player's character: accuse it, with the blacklist days to ask for if it did something.
func show_visitor(name: String) -> void:
	origin = GridView.NONE
	person = -1
	staff = -1
	plot = GridView.NONE
	visitor = name
	days = sim.ban_days
	_open()

func close() -> void:
	origin = GridView.NONE
	person = -1
	staff = -1
	plot = GridView.NONE
	visitor = ""
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
	hab.visible = origin != GridView.NONE and map.habitats.has(origin)
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
		for b in [upgrade, repair, demolish, buy]:
			b.visible = false
		accuse.visible = true
		warning.visible = true
		specs.visible = false
	elif staff >= 0 and staff < sim.staff.size():
		var s: Dictionary = sim.staff[staff]
		title.text = "%s · Lv %d" % [(s["kind"] as String).capitalize(), s["level"]]
		var cost := sim.staff_upgrade_cost(staff)
		var lines := [staff_effect(s), "Wage $%d a day" % ParkSim.stat(s, "wage")]
		if cost >= 0:
			lines.append("Next, Lv %d: %s · $%d a day" % [s["level"] + 1, staff_effect(s, 1), ParkSim.stat({"kind": s["kind"], "level": s["level"] + 1}, "wage")])
		body.text = "\n".join(lines)
		upgrade.visible = true
		upgrade.disabled = cost < 0 or sim.money < cost
		if cost < 0:
			upgrade.text = "Upgrade · max level"
		elif sim.money < cost:
			upgrade.text = "Upgrade $%d · need $%d more" % [cost, cost - sim.money]
		else:
			upgrade.text = "Upgrade to Lv %d · $%d" % [s["level"] + 1, cost]
		for b in [repair, demolish, accuse, buy, warning, specs]:
			b.visible = false
	elif plot != GridView.NONE:
		if not map.buyable(plot):
			close()
			return
		_plot()
	elif visitor != "":
		if sim.avatar(visitor).is_empty():
			close()
			return
		title.text = visitor
		body.text = "Visiting your park in person"
		_days.text = "Ban for %d day%s" % [days, "" if days == 1 else "s"]
		accuse.text = "Accuse"
		for b in [upgrade, repair, demolish, buy, specs]:
			b.visible = false
		accuse.visible = true
		warning.visible = true
	ban_row.visible = visitor != ""
	_panel.reset_size()
	_panel.position.y = _panel.get_viewport_rect().size.y - _panel.size.y - BOTTOM

## What staff member `s` does at its level (+ `ahead` levels), in words.
static func staff_effect(s: Dictionary, ahead := 0) -> String:
	var n := {"kind": s["kind"], "level": s["level"] + ahead}
	if s["kind"] == "janitor":
		return "Looks for litter %d tiles around, cleans a spot in %.1f s" % [ParkSim.stat(n, "reach"), ParkSim.stat(n, "clean") / float(ParkSim.TPS)]
	var out := "Sees crimes %d tiles away, catches within %.1f tiles" % [ParkSim.stat(n, "sight"), ParkSim.stat(n, "catch")]
	return out + ", spots hidden troublemakers" if ParkSim.stat(n, "spot") > 0.0 else out

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
		"attraction" when hab.visible: lines.append(_habitat())
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
	if d["role"] != "path":
		var c := sim.path_charm(origin)
		if not is_nan(c):
			lines.append("Paths here: " + ParkSim.charm_word(c))
			if ParkSim.charm_word(c) == "dull":
				lines.append("Add decor or variety nearby")
	if j.is_empty():
		lines.append(_status())
	body.text = "\n".join(lines)
	var builder: bool = d["role"] == "staff" and not sim.builder_of(origin).is_empty()
	specs.visible = builder
	if builder:
		for b: Button in specs.get_children():
			b.visible = b.get_meta("spec") in map.spec_choices(origin)
			b.set_pressed_no_signal(b.get_meta("spec") in map.specs(origin))
			b.queue_redraw()

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
	buy.visible = false
	warning.visible = false

## Fill the habitat section for the habitat on the card; returns its body line.
func _habitat() -> String:
	var h: Dictionary = map.habitats[origin]
	var offer := Animals.picker(h["fence"])
	var has: String = h["animal"] if h.get("count", 0) > 0 else ""
	if not pick in offer:
		pick = has if has != "" else (offer[0] if not offer.is_empty() else "")
	for b: Button in picks.get_children():
		b.visible = b.get_meta("animal") in offer
		b.set_pressed_no_signal(b.get_meta("animal") == pick)
	var n: int = h["cells"].size()
	var appeal := roundi(n * Animals.appeal_factor(h))
	var line := "%d cells · appeal %d" % [n, appeal]
	if has == "":
		line += "\nNo animals yet: pick one below"
	else:
		var c := Animals.comfort(has, h)
		line += "\n%d %s%s · %s" % [h["count"], Animals.ALL[has]["name"], "" if h["count"] == 1 else "s",
			"happy and out" if c >= Animals.HAPPY else "unhappy, hiding and pacing"]
	needs_text.visible = pick != ""
	comfort_text.visible = pick != ""
	comfort_bar.visible = pick != ""
	buy_animal.visible = pick != ""
	if pick == "":
		return line
	needs_text.text = "\n".join(Animals.needs(pick, h).map(func(e: Dictionary) -> String:
		return ("✓  " if e["ok"] else "✗  ") + e["text"]))
	comfort_text.text = "Comfort %d / 100%s" % [Animals.comfort(pick, h), "" if pick == has else " (if it lived here)"]
	comfort_bar.queue_redraw()
	var why := map.animal_block(origin, pick)
	buy_animal.disabled = why != ""
	buy_animal.text = "Buy a %s · $%d" % [Animals.ALL[pick]["name"], Animals.ALL[pick]["price"]] if why == "" else why
	return line

func _draw_comfort() -> void:
	if pick == "" or not map.habitats.has(origin):
		return
	var c := Animals.comfort(pick, map.habitats[origin])
	var s := comfort_bar.size
	var r := s.y * 0.5
	comfort_bar.draw_colored_polygon(Squircle.points(s * 0.5, s * 0.5, 4.0, 48), Palette.STONE)
	if c > 0:
		var w := maxf(s.x * c / 100.0, 2.0 * r)
		comfort_bar.draw_colored_polygon(Squircle.points(Vector2(w * 0.5, r), Vector2(w * 0.5, r), 4.0, 48),
			Palette.MOSS if c >= Animals.HAPPY else Palette.CORAL)

func _plot() -> void:
	var price := map.plot_price()
	title.text = "Land for sale"
	body.text = "%d × %d plot · $%d\nYou own %d of %d extra plots" % [ParkMap.PLOT, ParkMap.PLOT, price,
		map.bought, ParkLevel.cap("plots", map.park_level())]
	for b in [upgrade, repair, demolish, accuse, warning, specs]:
		b.visible = false
	buy.visible = true
	buy.disabled = not map.can_buy(plot)
	var needs := map.plot_needs()
	if needs < 0:
		buy.text = "No more land for sale"
	elif needs > 0:
		buy.text = "More land at park level %d" % needs
	elif map.money < price:
		buy.text = "Buy $%d · need $%d more" % [price, price - map.money]
	else:
		buy.text = "Buy · $%d" % price

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
	var have: Array = map.specs(origin).map(func(s: String) -> String: return spec_line(map, origin, s))
	var free := ParkLevel.cap("specialties", map.park_level()) - have.size()
	if have.is_empty():
		have.append("Specialty: pick one below")
	elif free > 0:
		have.append("Pick a second specialty below")
	return "Builder shed · home of %s\n%s is %s\n%s" % [b["name"], b["name"], doing, "\n".join(have)]

## "Water Lv 2 · ×2 · 14/30 XP" (or "max"): level, build speed on its buildings, XP to the next level for the builder at `shed`.
static func spec_line(m: ParkMap, shed: Vector2i, s: String) -> String:
	var xp: int = m.spec_xp.get(shed, {}).get(s, 0)
	var lv := Specialties.level(xp)
	var next := "max" if lv >= Specialties.LEVEL_XP.size() else "%d/%d XP" % [xp, Specialties.LEVEL_XP[lv]]
	return "%s Lv %d · ×%s · %s" % [Specialties.ALL[s]["name"], lv, str(Specialties.LEVEL_SPEED[lv - 1]).trim_suffix(".0"), next]

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
