class_name RaidPanel
extends CanvasLayer
# Raid screens: the picker (target cards + squad), the timer while the raid runs, the finish card.

signal go(offer: Dictionary, counts: Dictionary)
signal home(result: Dictionary)

const STARS := ["Wrecked a building", "Stole money or a blueprint", "Happiness below 50%"]

var sim: ParkSim  # the target's sim while a raid runs
var money := 0    # your money, for the squad budget
var _end := 0
var _offers: Array[Dictionary] = []
var _pick := 0
var _counts := {}
var _picker := _panel()
var _cards := HBoxContainer.new()
var _count_labels := {}
var _total := Hud._label(16)
var _go: Button
var _timer := PanelContainer.new()
var _timer_text := Hud._label(20)
var _card := _panel()
var _card_text := Hud._label(18)
var _result := {}

func _ready() -> void:
	var col := _column(_picker)
	col.add_child(Hud._label(22))
	col.get_child(0).text = "Raid a park"
	_cards.add_theme_constant_override("separation", 10)
	col.add_child(_cards)
	for k: String in Raid.COST:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lbl := Hud._label(16)
		lbl.text = "%s   $%d" % [k.capitalize(), Raid.COST[k]]
		lbl.custom_minimum_size = Vector2(170, 0)
		row.add_child(lbl)
		row.add_child(_small(Hud._button("−", func() -> void: _add(k, -1))))
		_count_labels[k] = Hud._label(18)
		_count_labels[k].custom_minimum_size = Vector2(28, 0)
		_count_labels[k].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(_count_labels[k])
		row.add_child(_small(Hud._button("+", func() -> void: _add(k, 1))))
		col.add_child(row)
	col.add_child(_total)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(Hud._button("Cancel", _picker.hide))
	_go = Hud._button("Go", func() -> void:
		_picker.hide()
		go.emit(_offers[_pick], _counts.duplicate()))
	_go.custom_minimum_size = Vector2(80, 0)
	buttons.add_child(_go)
	col.add_child(buttons)
	_picker.hide()

	_timer.add_theme_stylebox_override("panel", BuildBar.box(Palette.CORAL, 20))
	_timer.add_child(_timer_text)
	add_child(_timer)
	_timer.hide()

	var card_col := _column(_card)
	card_col.add_child(_card_text)
	card_col.add_child(Hud._button("Back home", func() -> void:
		_card.hide()
		_timer.hide()
		sim = null
		home.emit(_result)))
	_card.hide()

## Show the picker with three fresh targets.
func open(rng: RandomNumberGenerator, your_money: int) -> void:
	money = your_money
	_offers = Raid.offers(rng)
	_counts = {}
	for c in _cards.get_children():
		_cards.remove_child(c)
		c.queue_free()
	var group := ButtonGroup.new()
	for i in _offers.size():
		var o := _offers[i]
		var b := Hud._button("%s\n%s park\nGuards %d" % [o["theme"].capitalize(), o["size"], o["guards"]],
			func() -> void: _pick = i)
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(120, 0)
		_cards.add_child(b)
	_pick = 0
	(_cards.get_child(0) as Button).button_pressed = true
	_refresh()
	_picker.show()

## The raid view is up: run the timer until the sim says the raid is over.
func watch(target: ParkSim) -> void:
	sim = target
	_end = sim.tick + ParkSim.RAID_TICKS
	_timer.show()

func _process(_delta: float) -> void:
	if not sim:
		return
	var left := ceili(maxi(_end - sim.tick, 0) / float(ParkSim.TPS)) if sim.raiding else 0
	_timer_text.text = "Raid %d:%02d" % [left / 60, left % 60]
	_timer.reset_size()
	_timer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 16)
	if not sim.raiding and not _card.visible:
		_result = sim.raid_result()
		var lines := PackedStringArray(["Raid over"])
		for i in STARS.size():
			lines.append(("★  " if _result["stars"][i] else "☆  ") + STARS[i])
		lines.append("Loot   $ %d" % _result["stolen_money"])
		var names := PackedStringArray()
		for id: String in _result["blueprints"]:
			names.append(Buildings.get_def(id)["name"])
		lines.append("Blueprints   " + (", ".join(names) if not names.is_empty() else "none"))
		_card_text.text = "\n".join(lines)
		_card.show()
		_center(_card)

func _add(kind: String, d: int) -> void:
	_counts[kind] = maxi(_counts.get(kind, 0) + d, 0)
	_refresh()

func _refresh() -> void:
	for k: String in _count_labels:
		_count_labels[k].text = str(_counts.get(k, 0))
	var c := Raid.cost(_counts)
	_total.text = "Squad $ %d   ·   you have $ %d" % [c, money]
	_go.disabled = c > money or Raid.squad(_counts).is_empty()
	_center(_picker)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var box := BuildBar.box(Palette.CREAM, 20)
	box.set_content_margin_all(22)
	p.add_theme_stylebox_override("panel", box)
	p.custom_minimum_size = Vector2(260, 0)
	return p

func _column(p: PanelContainer) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	p.add_child(col)
	add_child(p)
	return col

func _center(p: Control) -> void:
	p.reset_size()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

static func _small(b: Button) -> Button:
	b.custom_minimum_size = Vector2(36, 0)
	return b
