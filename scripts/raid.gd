class_name Raid
# Pure raid setup (docs/design/game.md → Raids): target offers, squad cost, the target's sim.

const COST := {"hooligan": 40, "litterbug": 20, "thief": 50, "spy": 60}
const GUARDS := {"small": [0, 1], "large": [2, 3]}
const WARMUP := 20 * ParkSim.TPS  # the target's day is 20 s in, so a 60 s raid ends before its 120 s close

## Three target cards {theme, size, seed, guards}; at least one festival.
static func offers(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var themes: Array = Buildings.themes().keys()
	var fest := rng.randi_range(0, 2)
	for i in 3:
		var size: String = ["small", "large"][rng.randi() % 2]
		out.append({"theme": "festival" if i == fest else themes[rng.randi() % themes.size()], "size": size,
			"seed": rng.randi(), "guards": rng.randi_range(GUARDS[size][0], GUARDS[size][1])})
	return out

## counts: raider kind -> how many. Total cost in money.
static func cost(counts: Dictionary) -> int:
	var total := 0
	for k: String in counts:
		total += COST[k] * counts[k]
	return total

static func squad(counts: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for k: String in COST:
		for i in counts.get(k, 0):
			out.append(k)
	return out

static func target(offer: Dictionary) -> ParkMap:
	return BotPark.generate(offer["theme"], offer["seed"], offer["size"])

## The target park's sim with its guards hired, warmed up, and the squad sent in.
static func start(map: ParkMap, offer: Dictionary, counts: Dictionary) -> ParkSim:
	var sim := ParkSim.new(map, offer["seed"])
	for i in offer["guards"]:
		sim.hire("guard")
	for i in WARMUP:
		sim.step()
	sim.start_raid(squad(counts))
	return sim
