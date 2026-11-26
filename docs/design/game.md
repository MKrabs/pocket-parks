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
4. **Caught.** Arrests need evidence:
   - an actor caught **during or after a crime**: the sender pays the host a fine that grows with every
     crime (base × crimes), and any loot it carries goes back to the host (loot is delivered only when the actor leaves);
   - a **wrongful arrest** (an honest guest, or an actor with no crime yet): the **host pays the sender**.
     A risk the host has to take. (Decided by owner 2026-11-26.)
   - **Guards** only arrest on evidence: they catch an actor mid-crime, or one they saw commit a crime
     (it's marked *wanted* and they chase it). So guards never cause wrongful arrests.
   - **The host** can click any guest to accuse it. That's the gamble.

Honest guests you send pay you **20% of what they spend** (Default).

**Crime reports (UI).** Every crime is reported to the host as it happens: a toast ("Snack Stand was
robbed: −$24"), and clicking it pans the camera there. The report says *what* and *where*, never *who*,
unless a guard saw it. Working out who it was is the host's job.

**Building pins (UI).** A small map-pin-style bubble with an icon floats above a building that needs
something: *wrecked, needs rebuilding* (click: pay to repair now, or it reopens by itself after a while),
*littered, needs cleaning* (janitors), *robbed* (info, fades). Future: damaged building models (see Roadmap).

So every bad actor is a push-your-luck bet. Damage is temporary: wrecked buildings reopen after a
while, and janitors clean the litter.
**Both directions:** bot visitors also send mixed groups into *your* park, so defending (guards,
catching, collecting fines) is playable solo.

## Building (Decided by owner 2026-11-26; numbers are Defaults)
- **Placing:** a neutral **Select** mode is the default. A build item turns on place mode with a preview; Esc,
  right-click or the same button again cancels. **R** rotates before placing. Paths and trees stay active for painting;
  other buildings return to Select after one placement (Shift keeps placing).
- **Construction and upgrades take time** (game time, since the park only runs while the game is open). The site
  shows a scaffold and a progress ring and is closed until done. Path instant, tree 5 s, shop 20 s, pond 40 s,
  enclosure 60 s; upgrades ×1.5 (Lv 2) / ×2.5 (Lv 3). Money is still paid up front.
- **Builders do the work.** A **builder shed** houses exactly one builder; more sheds mean more parallel jobs. The first
  shed and builder are free. A job needs a free builder, who walks to the site (a bean with a hard hat).
- **Specialties:** every builder builds all normal buildings at speed 1. A builder can pick **one specialty**
  (a **second** at a higher park level). For simplicity, **all specialties are available**: no XP or training for now.
  Buildings in a specialty are either *specialist-only* (only that specialist can build or upgrade them) or
  *faster with a specialist* (anyone at 1×, the specialist at 2×). The UI only shows specialties a builder can
  choose or already has, never locked ones.
  Zoo specialties: **Landscaper** (trees, hedges, gardens), **Water** (ponds, fountains, water-tank enclosure),
  **Aviary** (bird enclosures), **Heavy** (reinforced enclosures, stone), **Carpenter** (stalls, fences, decks).
- **Lending builders** (needs networking): a friend requests one of your builders, and **the owner sets the price**.
  The builder works in their park. Parked until M4.

## Park level (Decided)
Guests served and happiness fill an XP ring. Each park level unlocks things: more builder sheds, a higher
maximum building level, the second specialty, later map plots and themes. One progression thread.

## Screen layout (Default)
Top-left: park name, level with its XP ring, a thin day bar. Top-right: money, guests, mood face; crime toasts
below. Bottom centre: build bar with category tabs (Paths, Attractions, Shops, Decor, Staff). Bottom-right: a big
round Visit button. Bottom-left: pause / play / fast. Right side: the info card for whatever is selected
(building or person). Actions such as Upgrade, Repair, Demolish, Rotate and Accuse live in the cards, not in the bar.

## Visiting in person, limits and the blacklist (Decided by owner 2026-11-27; numbers are Defaults)
- **You can visit in person** (your character, M5). You can just walk around and interact, or do mischief
  yourself, with the same crimes as the actors.
- **Caught fair and square** (a guard saw you strike, or the host accused you after a crime) puts you on that
  park's **blacklist**:
  - you can't enter that park in person any more;
  - sending people there costs more (×2), and fewer people take the job: your send limit for that park is halved.
- A wrongful accusation never blacklists anyone. It still pays the sender, as today.
- **Send limit:** how many of your people can be inside one park at once. Default: 3 + your park level, halved while
  you're blacklisted there. Other conditions can be added later.
- Open: does a blacklist last forever, until the host lifts it, or for a number of days?

## Roadmap (updated 2026-11-27)
**Done:** M3 depth (building levels, staff levels, plots, cinema theme, damaged models, builders and specialties,
park level), M4 local network (discovery, live visits, join by address, saving), M6 sending over the network.

**Next, in order**
1. **Owner's two-machine test** (GATE4).
2. **M5 Live social:** your character in the park you visit (walk, interact, mischief in person), presence (who is
   in your park, who else is where you are), chat (speech bubbles plus a log), identity (choose a name and colour),
   send limits and the blacklist (above).
3. **Polish:** the owner's small details, plus: land ownership contrast, the aviary dome, builders using paths, people
   inside at day end settle instead of vanishing, plot card highlight, a proper toast for a lost connection,
   in-park markers and pins during live visits, smoother movement in live visits.
4. **Animals:** enclosures, the aviary and the water tank get animals (ahead of new themes).
5. **Themes:** amusement park (rollercoasters), conference with booths, the food festival in full.

**Parked**
- Lending builders between friends. Edge cases: a dropped connection or a player leaving mid-job. Revisit with a design
  where the builder never leaves the owner's save (a contract the host runs, paid per finished job).
- Builder XP and training. Roguelike runs, meta progression, leagues and likes. Sound.

## Decided: networking (2026-11-26)
**Peer-to-peer on the local network, no server.** Each player's game is the authority for its own park:
it runs the day sim, judges the bad actors sent into it, and passes presence and chat between its visitors. Games find
each other by UDP broadcast and connect directly (Godot ENet, one channel for "my park" and one for "the
park I'm visiting"). **Parks whose owner is offline, or on another network, are unavailable. That is
accepted, not a problem to solve.** Friends elsewhere can join a shared virtual network (e.g. Tailscale);
that's their setup, not a feature. Cheating isn't a concern (friends only).
Would reverse it: the game is meant for players who don't know each other.
