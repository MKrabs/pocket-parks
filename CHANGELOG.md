# Changelog

All notable changes to Pocket Parks. Newest first. Each version is also a
[GitHub release](https://github.com/MKrabs/pocket-parks/releases) with builds for macOS and Linux,
and the game shows the latest entry in its "What's new" card.

## [Unreleased]

### Changed
- **Habitats instead of enclosures:** Attractions → Habitat, pick a fence (wood Fence, or Glass, Net and Wall for
  Water, Aviary and Heavy builders) and drag a rectangle on your land. A preview shows the outline, the cell count and
  the cost. Drag again from inside or along the edge to grow it into L shapes and more; right-drag removes cells.
  A builder puts up the fence, and bigger habitats draw more guests. The old Enclosure, Water Tank, Aviary and
  Reinforced Enclosure are gone; new parks start with a small fenced habitat.
### Added
- **Conference theme:** a fourth theme with a Registration Desk entrance, carpet paths, a big Main Stage (needs the new
  Tech specialist), Booths in three sizes (Booth, Expo Stand, Pavilion), a Coffee Bar, office plants and roll-up
  banners. Press **T** to switch to it, and conference parks now turn up when you visit.
- **Builders level up:** every finished job gives a builder XP, and more for jobs in their specialty. Each specialty
  goes from Lv 1 to Lv 3 and builds its buildings ×1.5, ×2, then ×3 as fast. A second specialty levels on its own. A
  toast says when someone levels up, and the shed card shows each specialty's level, speed and XP bar.

### Changed
- A new specialist now starts at ×1.5 on their specialty's buildings (it was ×2), and specialist-only buildings get the
  speed bonus too.

## [0.3.0] - 2026-11-27: A nicer park

### Added
- **Park charm:** guests now rate the walk between stops. A long walk past decor, water, open grass and a mix of
  buildings is a lovely stroll: they cheer up and spend more at the next stop. A long walk past rows of the same stand,
  packed paving, litter or wrecks is a dull walk: they grumble and spend less.
- **What's new:** the game's version sits in the bottom-left corner. After an update a card shows what changed, and
  clicking the version opens it again any time.
- **Charm view:** press **C** to tint every path from grey (dull) through green to a soft yellow glow (charming), with
  the other buildings faded. Guests show a little ♥ after a lovely stroll and a ~ after a dull one, and building cards
  say how charming the paths next to them are, with a tip when they're dull.
- **Bigger shops:** every food shop comes in three sizes. Zoo: Snack Cart, Hot-dog Stand, Burger Diner. Festival: Food
  Truck, Taco Truck, Food Hall. Cinema: Popcorn Stand, Candy Bar, Lobby Café. Bigger shops serve more guests at once and
  charge more. Switch sizes with the small ‹ › arrows on the shop's button, or press **1**/**2**/**3** while placing.
  A row of different sizes from the same family still counts as "the same stand" for park charm.

### Changed
- The zoo's Snack Stand is now called the Snack Cart.
- What guests spend depends on their mood. Happy guests pay in full, and unhappy ones often skip buying.
- **The build bar tucks itself away** to a small tab when you're not using it, and slides back up when the mouse nears
  the bottom edge or you press **B**. Use the pin on the bar to keep it open. It never hides while you're placing
  something.
- **Clearer enclosures:** the aviary is now a see-through dome with a few net arcs, the reinforced enclosure has one
  solid stone wall with buttresses, the water tank has glass sides with the water inside, and fences are a continuous
  rail with posts. When wrecked, the dome's net tears open and walls, fences and glass get a breach.

## [0.2.0] - 2026-11-27: Visit in person

### Added
- **Your identity:** choose your name, your park's name and your colour on first start. Change them any time by clicking the
  top-left of the HUD.
- **Your character** stands at your gate and walks the park you're in. At home, Shift+click a path to walk there. While
  visiting, a plain click walks. The camera follows softly; press **F** to turn that off.
- **Chat:** press **Enter** to talk. Lines show as speech bubbles over your character and in a small log, for everyone in
  that park.
- **Presence:** a chip under your money shows who's visiting you, and pop-ups say when friends arrive and leave. While
  visiting, "Also here:" lists everyone else.
- **Mischief in person:** next to a building in a park you visit, your character can Wreck, Litter, Steal or Spy. Your
  loot arrives once you walk out through the gate.
- **Blacklist:** get caught (a guard saw you, or the host accused you after a crime) and you're banned from that park for
  1–7 in-game days, chosen by the host. While banned you can't enter in person, sending people there costs ×2 and your
  send limit there is halved. The host can lift a ban early.
- **Send limit:** at most 3 + your park level of your people inside one park at a time.
- **Visit picker:** always at least 3 parks. Friends found on your network come first, and bot parks fill the rest. It
  refreshes live and shows a "Looking for friends…" status.
- **Join by address**, and your own address shown in the picker, for networks that block discovery.
- macOS builds ask for local network access, which macOS 15 needs to find other games.

### Fixed
- The Visit picker no longer grows each time you open it.
- Pop-ups no longer cover the presence chip.

## [0.1.0] - 2026-11-26: First playable

### Added
- Isometric park builder: paths, attractions, shops and decor. Rotate with **R**, upgrade buildings to level 3, buy
  land in 4×4 plots.
- Three themes: zoo, food festival and cinema. Press **T** to switch.
- Builders: every construction and upgrade takes time and a builder from a builder shed. Specialties (Landscaper, Water,
  Aviary, Heavy, Carpenter, Projection) build faster and unlock specialist-only buildings.
- Park level with XP, unlocking higher building levels, more sheds, more plots and a second specialty.
- A park day: guests walk, visit, spend and litter. Janitors and guards, with levels.
- Sending people: visit bot parks and send in guests (you get a share) or hooligans, litterbugs, thieves and spies,
  who hide until they strike.
- Defending: crime reports, pins over damaged buildings, accusing (a wrongful arrest costs you), damaged-building
  models.
- Local network play: parks find each other and you can visit a friend live and send people into their park.
- Saving every 30 s and on quit. **F9** starts a new park.
- Motion everywhere: cloud transition between parks, money pop-ups, crime effects, building squish.
