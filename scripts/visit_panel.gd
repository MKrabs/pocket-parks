class_name VisitPanel
extends CanvasLayer
# Visiting UI: the picker of nearby parks, and while visiting the Send panel with the ledger strip and Back home.

signal picked(offer: Dictionary)
signal sent(kind: String)
signal home

var _picker := PanelContainer.new()
var _choices := VBoxContainer.new()
var _send := PanelContainer.new()
var _title := Hud._label(18)
var _ledger := Hud._label(15)

func _ready() -> void:
	var pbox := BuildBar.box(Palette.CREAM, 20)
	pbox.set_content_margin_all(20)
	_picker.add_theme_stylebox_override("panel", pbox)
	_choices.add_theme_constant_override("separation", 10)
	_picker.add_child(_choices)
	add_child(_picker)
	_picker.hide()

	_send.add_theme_stylebox_override("panel", BuildBar.box(Palette.STONE, 20))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.add_child(_title)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", BuildBar.box(Palette.CREAM))
	chip.add_child(_ledger)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(chip)
	col.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for kind: String in Visit.PRICES:
		var b := Hud._button("Send %s\n$%d" % [kind, Visit.PRICES[kind]], sent.emit.bind(kind))
		b.custom_minimum_size = Vector2(96, 0)
		row.add_child(b)
	var back := Hud._button("Back\nhome", home.emit)
	back.add_theme_stylebox_override("normal", BuildBar.box(Palette.BUTTER))
	back.add_theme_stylebox_override("hover", BuildBar.box(Palette.shade(Palette.BUTTER, 0.04)))
	back.custom_minimum_size = Vector2(84, 0)
	row.add_child(back)
	col.add_child(row)
	_send.add_child(col)
	add_child(_send)
	_send.hide()

## Show the picker with one button per offer, plus Cancel.
func open(offers: Array[Dictionary]) -> void:
	for c in _choices.get_children():
		c.queue_free()
	var head := Hud._label(18)
	head.text = "Visit a park"
	_choices.add_child(head)
	for o in offers:
		var b := Hud._button("%s\n%s · %d guards" % [o["name"], o["theme"], o["guards"]], func() -> void:
			_picker.hide()
			picked.emit(o))
		b.custom_minimum_size = Vector2(220, 0)
		_choices.add_child(b)
	_choices.add_child(Hud._button("Cancel", _picker.hide))
	_picker.show()
	_picker.reset_size()
	_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

## While visiting `name`: show the Send panel; call show_ledger every frame.
func watch(park_name: String) -> void:
	_title.text = park_name
	_send.show()
	show_ledger({"guests": 0, "hidden": 0, "wanted": 0, "earned": 0, "fines": 0}, 0)
	_send.reset_size()
	_send.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

func show_ledger(t: Dictionary, money: int) -> void:
	_ledger.text = "$ %d   Yours inside: %d guests · %d hidden · %d wanted   Earned $ %d   Fines $ %d" % [
		money, t["guests"], t["hidden"], t["wanted"], t["earned"], t["fines"]]

func close() -> void:
	_send.hide()
