class_name Visit
# Visiting bot parks (stand-ins for friends): the offers in the picker, the park's live sim, send prices.

const ME := "you"  # our sender id in every visited park
const PRICES := {"guest": 3, "hooligan": 40, "litterbug": 20, "thief": 50, "spy": 60}
const KEEP := 3  # visited parks still simulated after you leave
const NAMES := ["Maple Hollow", "Sunny Burrow", "Pebble Bay", "Clover Fields", "Otter Lane", "Juniper Park",
	"Bramble Nook", "Honey Meadow", "Fern Gully", "Willow Cove"]

## Three nearby parks: distinct names, three different themes in shuffled order, 0-3 guards.
static func offers(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var names: Array = BotPark._shuffled(rng, NAMES)
	var themes: Array = BotPark._shuffled(rng, Buildings.themes().keys())
	for i in 3:
		out.append({"name": names[i], "theme": themes[i % themes.size()], "seed": rng.randi(),
			"size": "small" if rng.randf() < 0.6 else "large", "guards": rng.randi_range(0, 3)})
	return out

## The offer's park as a running day: generated map, guards hired on the bot's money.
static func open(offer: Dictionary) -> Array:
	var map := BotPark.generate(offer["theme"], offer["seed"], offer["size"])
	var sim := ParkSim.new(map, offer["seed"])
	for i in offer["guards"]:
		sim.hire("guard")
	return [map, sim]
