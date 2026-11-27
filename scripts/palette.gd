class_name Palette
# The only place colours are defined. Natural, slightly pastel. Never use Color literals elsewhere.

const CREAM := Color("#F2EDE3")     # background / sky
const INK := Color("#5B5348")       # text, outlines (use sparingly, often at low alpha)
const GRASS := Color("#B5D1A4")     # ground tile
const GRASS_DARK := Color("#A3C293")  # checker / alternate tile
const GRASS_PALE := Color("#CCD9C0")  # land you don't own yet (muted, desaturated)
const HABITAT := Color("#CBD3A0")   # habitat floor (a warmer, drier meadow than the lawn)
const MOSS :=Color("#86A97E")      # foliage, trees
const SAND := Color("#E8D8B4")      # paths
const WATER := Color("#A7CFD9")     # pools
const WOOD := Color("#C9A783")      # fences, stalls
const CLAY := Color("#DDA88F")      # roofs, accents
const STONE := Color("#D3CCC0")     # rock, walls
const BUTTER := Color("#EDD898")    # highlight, money
const CORAL := Color("#E9A99C")     # warnings, invalid placement
const SKY := Color("#B9CFE6")       # selection, hover
const CLOUD := Color("#FBF7EF")     # cloud puffs (warm off-white)
const CLOUD_SHADOW := Color("#E7DFD3")  # underside of a puff
# Animals (Animals.ALL): one body colour each, soft enough to sit with the rest.
const OTTER := Color("#A88A70")
const CAPYBARA := Color("#C9A27A")
const PLATYPUS := Color("#8F7F70")
const RED_PANDA := Color("#D9926A")
const TAKIN := Color("#E0C487")
const KLIPSPRINGER := Color("#BCA586")
const SHOEBILL := Color("#A9B5BF")
const PUFFIN := Color("#6F6B73")
const HORNBILL := Color("#6A635F")

## Faces of an extruded iso shape: top is the base colour, sides get darker.
static func shade(c: Color, amount: float) -> Color:
	return c.darkened(amount)

## The one UI font (Nunito, OFL, assets/fonts/). Semi-bold reads best on pastel. Also the project's default theme font.
static var FONT: FontVariation = _font(650)
static var FONT_BOLD: FontVariation = _font(800)

static func _font(weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = load("res://assets/fonts/Nunito.ttf")
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f
