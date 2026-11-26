class_name Palette
# The only place colours are defined. Natural, slightly pastel. Never use Color literals elsewhere.

const CREAM := Color("#F2EDE3")     # background / sky
const INK := Color("#5B5348")       # text, outlines (use sparingly, often at low alpha)
const GRASS := Color("#B5D1A4")     # ground tile
const GRASS_DARK := Color("#A3C293")  # checker / alternate tile
const MOSS := Color("#86A97E")      # foliage, trees
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

## Faces of an extruded iso shape: top is the base colour, sides get darker.
static func shade(c: Color, amount: float) -> Color:
	return c.darkened(amount)
