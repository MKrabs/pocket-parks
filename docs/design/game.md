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
- **Duration:** the host chooses **1–7 in-game days** when the catch happens (Decided 2026-11-27). Arrests by guards
  while the host isn't deciding use the host's default (a setting, starting at 3 days).

## Park charm: why a nice park beats a spammed one (Proposed 2026-11-27, numbers are Defaults)
**How other games do it**
- *RollerCoaster Tycoon*: scenery near paths raises happiness, and long walks make guests tired and lost.
- *Planet Coaster*: every ride and shop gets a *scenery rating* from the decoration around it, and a high rating
  lets you charge more.
- *Parkitect*: a decoration level per area, and a penalty when guests see the back of house.
- *Two Point* games: each room has an *attractiveness* score from the items in it, and variety counts.
- *Planet Zoo*: habitat appeal comes from how happy the animals are.

The common pattern is "decoration near X makes X better". It's solid but well-worn.

**Our one twist: strolls matter.** Guests don't just rate buildings, they rate the **walk between stops**:
- Every path tile has a **charm** value from what's around it (within about 2 tiles):
  - **+** decor, water, and a **variety** of different buildings in view;
  - **+** some **open space** (grass tiles with nothing on them nearby);
  - **−** the **same building type repeated** close by ("seen it"; this is the anti-spam rule);
  - **−** packed clutter with no open space;
  - **−** litter, and wrecked buildings.
- When a guest reaches their next stop, the walk is scored by its average charm and its length:
  - **long and charming:** a "lovely stroll", a mood boost, and they spend more at that stop (up to +30%);
  - **long and dull:** an "ugh, that walk", a mood drop, and they spend less;
  - **short walks** are neutral, so you can't avoid charm by building tightly.
- **Spending:** what a guest will pay scales with mood. Happy guests buy at full price plus the stroll bonus; unhappy
  ones skip purchases.
- **Making it visible**, since a system you can't see isn't fun:
  - press **C** for a *charm view* that tints path tiles from dull to glowing;
  - guests show a tiny ♥ after a lovely stroll and a ~ after a dull one;
  - building cards show the charm of the paths leading to them.

## Shape language (Decided by owner 2026-11-27)
Squircles stay the signature for **solid objects**: buildings, blocks, trees, UI. Where the real thing has another
shape, use that shape as **one clear silhouette instead of many small blocks**:
- **domes:** one smooth translucent dome with a few thin net arcs, not beaded posts;
- **walls:** one continuous extruded wall following the outline, with a cap and some definition (buttresses, a darker
  base), not a ring of pillars;
- **glass:** translucent panels with a highlight stripe;
- **water:** sits *inside* a basin, below the rim, with a surface highlight, never a floating blob;
- **nets and rails:** thin lines;
- **fences:** a continuous rail with posts at intervals.

## Habitats and animals (Proposed 2026-11-27; the owner judges the feel at the end)
Instead of fixed enclosure buildings, the zoo **paints habitats**, and an animal lives in each one.

**How you use it** (built to be quick with a mouse *or* a trackpad):
1. Bottom bar → Attractions → **Habitat**, then pick a **fence type**:
   - **Fence** (wood): anyone can build it;
   - **Glass** (water habitats): needs a Water specialist;
   - **Net** (birds, a dome): needs an Aviary specialist;
   - **Wall** (reinforced): needs a Heavy specialist.
2. **Drag** a rectangle on the grid. A live preview shows the outline, the cell count and the cost.
   - **Drag again from inside or along the edge** to add more: L shapes and other outlines come from adding rectangles.
   - **Right-drag** removes cells.
   - Release, and a builder fences it (a normal construction job).
3. The **habitat card** opens on the right, where the info card lives:
   - an **animal picker**: only animals this fence type allows, each with a small drawn portrait;
   - a **needs checklist** for the chosen animal: size, water, rocks, trees, shelter;
   - one **comfort bar**.
4. **Decorate** from the card: click an item (pool, rocks, tree, shelter, waterfall), then click inside the habitat.
   It's the same ghost placement as buildings, limited to the habitat. No drag-and-drop, which is fiddly on a trackpad.

**Animals: 3 categories × 3**, avoiding the usual top picks:
| Category | Fence | Animals |
|---|---|---|
| Water | Glass | Asian small-clawed otter, capybara, platypus |
| Highlands | Wall | red panda, takin, klipspringer |
| Birds | Net | shoebill, Atlantic puffin, hornbill |

- **Needs** per animal: a minimum size, plus terrain shares (water, rocks, trees) and a shelter.
- **Comfort** sets how the animal behaves:
  - *happy*: out and active, and the habitat's appeal to guests rises;
  - *unhappy*: hides and paces, and appeal drops.
- **Park level unlocks** new animals and fence types.

**Shops are not free-shaped** (the owner's question). Free shapes suit areas (habitats, paths) but make buildings look
accidental. Instead, building types get **size variants**:
- Snack: Cart (1×1) → Hot-dog Stand (2×1) → Burger Diner (2×2);
- the festival and cinema themes get their own;
- bigger means more capacity and a higher price;
- one build-bar button per type with a small variant switcher (arrows, or 1/2/3 while placing).

## Bottom bar (Decided by owner 2026-11-27)
The build bar **auto-hides**:
- it slides down to a slim handle when you're not using it;
- it slides up when the mouse comes near the bottom edge, or with **B**;
- a pin toggle keeps it open.

## Versions and changelog (Decided by owner 2026-11-27)
- Every playable step is a **version** (`application/config/version`), with an entry in `CHANGELOG.md` and a GitHub
  release with notes.
- The game shows its version and a **"What's new"** card: once after an update, and any time from the version label.

## Roadmap (updated 2026-11-27, night)
**Done:**
- 0.1: everything up to the local network;
- 0.2: the social layer: identity, characters, chat, presence, send limits, in-person mischief, blacklist.

**Next, in order** (no owner test needed in between; the owner judges at the end)
1. **0.3, a nicer park:** park charm and strolls, the shape-language rework, the auto-hiding bottom bar, building
   variants, the changelog and "What's new".
2. **0.4, habitats and animals:** painting habitats, fence types, 9 animals with needs, habitat decor.
3. **0.5, progression:** builders earn XP and level up their specialty (×1.5 / ×2 / ×3), and the park level unlocks
   animals, fence types and variants.
4. **0.6, themes:** amusement park (rollercoasters), conference with booths, the food festival in full.

**Parked**
- Lending builders between friends. Edge cases: a dropped connection or a player leaving mid-job. Revisit with a design
  where the builder never leaves the owner's save (a contract the host runs, paid per finished job).
- Roguelike runs, meta progression, leagues and likes. Sound.

## Decided: networking (2026-11-26)
**Peer-to-peer on the local network, no server.** Each player's game is the authority for its own park:
it runs the day sim, judges the bad actors sent into it, and passes presence and chat between its visitors. Games find
each other by UDP broadcast and connect directly (Godot ENet, one channel for "my park" and one for "the
park I'm visiting"). **Parks whose owner is offline, or on another network, are unavailable. That is
accepted, not a problem to solve.** Friends elsewhere can join a shared virtual network (e.g. Tailscale);
that's their setup, not a feature. Cheating isn't a concern (friends only).
Would reverse it: the game is meant for players who don't know each other.
