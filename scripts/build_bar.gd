class_name BuildBar
extends CanvasLayer
# Bottom bar: one button per catalog building plus an eraser. Money chip top-left.

signal picked(id: String)  # "" = eraser

const RADIUS := 14

var money_label := Label.new()

static func box(c: Color, radius: int = RADIUS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.set_content_margin_all(10)
	s.border_color = Palette.shade(c, 0.12)
	s.set_border_width_all(2)
	return s

func _ready() -> void:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", box(Palette.BUTTER))
	chip.position = Vector2(16, 16)
	money_label.add_theme_color_override("font_color", Palette.INK)
	money_label.add_theme_font_size_override("font_size", 20)
	chip.add_child(money_label)
	add_child(chip)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", box(Palette.STONE, 20))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	var group := ButtonGroup.new()
	for id: String in Buildings.CATALOG:
		var b: Dictionary = Buildings.CATALOG[id]
		row.add_child(button("%s\n$%d" % [b["name"], b["cost"]], id, group))
	row.add_child(button("Eraser\n ", "", group))
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	(row.get_child(0) as Button).button_pressed = true

func button(text: String, id: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(96, 0)
	b.add_theme_stylebox_override("normal", box(Palette.CREAM))
	b.add_theme_stylebox_override("hover", box(Palette.shade(Palette.CREAM, 0.04)))
	b.add_theme_stylebox_override("pressed", box(Palette.SKY))
	b.add_theme_stylebox_override("hover_pressed", box(Palette.SKY))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, Palette.INK)
	b.toggled.connect(func(on: bool) -> void:
		if on:
			picked.emit(id))
	return b

func set_money(m: int) -> void:
	money_label.text = "$ %d" % m
