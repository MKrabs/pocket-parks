# Game definition (working title: Pocket Parks)

Status labels: **Decided** = owner agreed. **Default** = Claude's pick, open to change. **Open**. **Parked** = don't design or scaffold it.

## Pitch
Build a small park, run its days, make money from guests. Now and then, raid someone
else's park mid-day with a squad of troublemakers: one short fight, one finish card.

## Pillars
1. **Park, not zoo (Decided).** The game is about a generic park. A **theme** is a data pack:
   its buildings, names and colours. Zoo is the first theme. Later candidates (Open): amusement
   park with rollercoasters, conference with booths, food festival. The prototype ships zoo plus a
   tiny **food festival** theme, only to prove that themes swap.
2. **Main loop = build + manage (Decided).** Place buildings, hire staff, balance money and guest
   happiness across a day.
3. **Fights = raids (Decided).** You send troublemakers into another park's normal day. Damage is
   **temporary**: it reverts after the raid, except the loot.
4. **Soft and readable.** Pastel, squircles, tiny guests you can watch. Every raid effect has to be visible.

## Building roles (every theme maps its buildings to these)
| Role | Does | Zoo | Festival |
|---|---|---|---|
| entrance | guests spawn and leave here, entry fee | Zoo Gate | Festival Arch |
| path | walkable | Path | Boardwalk |
| attraction | appeal draws guests, has a capacity | Enclosure, Pond | Stage, Big Grill |
| shop | guests pay here, produces litter | Snack Stand | Food Truck |
| decor | raises happiness nearby | Tree | Lantern Tree |

## A park day (Default)
- Fixed-tick simulation: 10 ticks/s, seeded RNG, so it's deterministic. A day = 120 s of game time.
- Guests arrive at the entrance (rate grows with total appeal), walk the paths, visit
  attractions and shops, pay, sometimes drop litter, and leave when satisfied or unhappy.
- Happiness 0–100 per guest: + visits and nearby decor, − litter nearby, closed buildings, crowding.
- Staff are hired units, paid a wage per day. **Janitor:** cleans litter. **Guard:** patrols, catches raiders.
- End of day: income, guests, average happiness.

## Raids (Default)
- From your park press **Raid**, pick a target park (a bot park for now), and buy a squad
  with your own money (the raid budget).
- The raid is the target's normal day with your raiders entering at its entrance. **60 s.**
| Raider | Cost | Does | Temporary effect on the target |
|---|---|---|---|
| Hooligan | 40 | goes to an attraction or shop, wrecks it after 3 s | closed until the raid ends |
| Litterbug | 20 | walks the paths dropping litter every second | happiness drops |
| Thief | 50 | goes to a shop, steals after 4 s, must escape via the entrance | money moves to you if they escape |
| Spy | 60 | watches the highest-appeal building for 5 s, must escape | you get its blueprint, even from another theme |
- Guards catch any raider within 1 tile: the raider is out.
- **One finish card, 3 stars:** ★ wrecked at least one building, ★ stole money or a blueprint,
  ★ the target's average happiness ended below 50. You keep loot and stolen blueprints.

## Parked
Roguelike run structure (seasons or ladders of raids). Real multiplayer and async snapshots
of real players (bot parks stand in). Social features (visits, likes, leagues). Meta
progression. Saving. Sound. Themes beyond zoo + the festival proof.

## Open
- Does raiding cost more than money (cooldown, reputation)?
- How does a defender learn they were raided (a log or a replay)?
- Roguelike: per-raid upgrades, or runs of raids?
