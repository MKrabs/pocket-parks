# Game definition (working title: Pocket Parks)

Status labels: **Decided** = owner agreed. **Default** = Claude's pick, open to change. **Open**. **Parked** = don't design or scaffold it.

## Pitch
Build a small park, run its days, make money from guests. Visit friends' parks and send
people in: honest guests who spend money there, and bad actors who blend into the crowd,
strike, hide again, and press their luck.

## Pillars
1. **Park, not zoo (Decided).** The game is about a generic park. A **theme** is a data pack:
   its buildings, names and colours. Zoo is the first theme. Later candidates (Open): amusement
   park with rollercoasters, conference with booths, food festival. The prototype ships zoo plus a
   tiny **food festival** theme, only to prove that themes swap.
2. **Main loop = build + manage (Decided).** Place buildings, hire staff, balance money and guest
   happiness across a day.
3. **No raid mode (Decided 2026-11-26, replaces the raid screen).** Conflict is implicit: while visiting
   a park you send guests in, and some of them are bad actors. There's no timer, no stars, no finish card.
4. **Soft and readable.** Pastel, squircles, tiny guests you can watch. Every crime has to be visible the moment it happens.

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
- Staff are hired units, paid a wage per day. **Janitor:** cleans litter. **Guard:** patrols, catches bad actors.
- End of day: income, guests, average happiness.

## Sending people (Decided by owner; numbers are Defaults)
While **visiting** a park (a bot park until M4, then a friend's), you open a Send panel and send people
in through its gate, over time:
- **Guests:** normal guests. They spend money in that park, so the host earns.
- **Bad actors:** hooligan (wrecks an attraction or shop for a while), litterbug (litters),
  thief (steals from a shop's till), spy (copies a building's blueprint).

A bad actor's life:
1. **Hidden.** It looks and behaves like a normal guest, walking and queueing.
2. **Strike.** It does its crime. It's exposed only for those few seconds.
3. **Hide again.** It blends back in. Then it either **leaves** (and the loot reaches the sender) or
   **stays for another round**. Its urge to stay shrinks with every crime (stay chance about 80% → 55% → 30% → 10%).
4. **Caught** (by a guard, or by the host; see Open):
   - before any crime: the sender pays the host a **base fine**;
   - after crimes: the fine grows with every crime committed (base × (1 + crimes)), and any loot it
     carries goes back to the host (Default: loot is delivered only when the actor leaves).

So every bad actor is a push-your-luck bet. Damage is temporary: wrecked buildings reopen after a
while, and janitors clean the litter.
**Both directions:** bot visitors also send mixed groups into *your* park, so defending (guards,
catching, collecting fines) is playable solo.

## Roadmap (owner wishlist 2026-11-26, grouped by what each depends on)
Only the next milestone gets detailed tickets. Later ones stay one-liners until it's done.

**M3 Depth (single player, next).** Each item is independent.
- Building upgrades: levels 1–3 per building, more appeal/capacity/price, visible on the model (extra tier, flag, trim).
- Staff levels: janitors clean faster and see further; guards move faster, catch from further away, and spot hidden bad actors sooner. Paid upgrade.
- Expandable map: start smaller (about 12×12), buy a few adjacent plots up to about 20×20. "Not by too much."
- Cinema theme (third pack): ticket booth entrance, screens (attractions), popcorn stand (shop), posters/plants (decor).
- Staff levels also make guards better at spotting hidden bad actors.

**M4 Local network foundation.** See Decided: networking, below.
- Each game hosts its own park on the local network; a "Parks nearby" list (UDP broadcast discovery).
- Identity-lite: a name and a colour.
- Visit a nearby park live: connect to its owner's game and watch its real day.

**M5 Live social** (needs M4)
- Your own character: walk around the park you're visiting, alongside the guests.
- Presence: see who is visiting your park right now, and who else is in the park you are visiting.
- Chat through your character: speech bubbles over it, plus a small log.

**M6 Sending people over the network** (needs M4): the Send mechanic above, between real players.
Rules to settle then: limits per visit, so nobody gets farmed.

**Later themes:** amusement park, conference, food festival in full.

## Decided: networking (2026-11-26)
**Peer-to-peer on the local network, no server.** Each player's game is the authority for its own park:
it runs the day sim, judges the bad actors sent into it, and passes presence and chat between its visitors. Games find
each other by UDP broadcast and connect directly (Godot ENet, one channel for "my park" and one for "the
park I'm visiting"). **Parks whose owner is offline, or on another network, are unavailable. That is
accepted, not a problem to solve.** Friends elsewhere can join a shared virtual network (e.g. Tailscale);
that's their setup, not a feature. Cheating isn't a concern (friends only).
Would reverse it: the game is meant for players who don't know each other.

## Parked
Roguelike run structure. Meta progression. Saving your own park to disk (small; becomes needed in M4, since your park must survive a restart).
Sound. Leagues and likes.

## Open (sending people)
- What does the sender get for sending honest guests? (They're cover for bad actors, but is there a direct reward?)
- How does the host catch a hidden actor: only guards, or can the host also accuse a suspect by hand, and what does a wrong accusation cost?
