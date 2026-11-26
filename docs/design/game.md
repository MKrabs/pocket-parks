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

## Roadmap (owner wishlist 2026-11-26, grouped by what each depends on)
Only the next milestone gets detailed tickets. Later ones stay one-liners until it's done.

**M3 Depth (single player, next).** Each item is independent.
- Building upgrades: levels 1–3 per building, more appeal/capacity/price, visible on the model (extra tier, flag, trim).
- Staff levels: janitors clean faster and see further; guards move faster, catch from further away, and spot raiders sooner. Paid upgrade.
- Expandable map: start smaller (about 12×12), buy a few adjacent plots up to about 20×20. "Not by too much."
- Cinema theme (third pack): ticket booth entrance, screens (attractions), popcorn stand (shop), posters/plants (decor).
- Kick raiders by hand: click a raider in your park to throw it out (costs a moment of your attention, guards do it automatically).
- Raider readability: bigger beans and clearer role marks (from the GATE2 review).

**M4 Local network foundation.** See Decided: networking, below.
- Each game hosts its own park on the local network; a "Parks nearby" list (UDP broadcast discovery).
- Identity-lite: a name and a colour.
- Visit a nearby park live: connect to its owner's game and watch its real day.

**M5 Live social** (needs M4)
- Your own character: walk around the park you're visiting, alongside the guests.
- Presence: see who is visiting your park right now, and who else is in the park you are visiting.
- Chat through your character: speech bubbles over it, plus a small log.

**M6 Live raids** (needs M4, best after M5)
- Raid any park whenever you want, live, no matchmaking or shields (unlike Clash of Clans). You send raiders from inside the park you're visiting.
- The defender, if online, sees it happen and can kick raiders by hand. Otherwise only their guards defend.
- Rules to settle then: cooldowns or limits per target, so nobody gets farmed.

**Later themes:** amusement park, conference, food festival in full.

## Decided: networking (2026-11-26)
**Peer-to-peer on the local network, no server.** Each player's game is the authority for its own park:
it runs the day sim, judges raids on it, and passes presence and chat between its visitors. Games find
each other by UDP broadcast and connect directly (Godot ENet, one channel for "my park" and one for "the
park I'm visiting"). **Parks whose owner is offline, or on another network, are unavailable. That is
accepted, not a problem to solve.** Friends elsewhere can join a shared virtual network (e.g. Tailscale);
that's their setup, not a feature. Cheating isn't a concern (friends only).
Would reverse it: the game is meant for players who don't know each other.

## Parked
Roguelike run structure. Meta progression. Saving your own park to disk (small; becomes needed in M4, since your park must survive a restart).
Sound. Leagues and likes.
