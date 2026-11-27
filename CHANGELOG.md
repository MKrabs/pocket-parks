# Changelog

All notable changes to Pocket Parks. Newest first. Each version is also a
[GitHub release](https://github.com/MKrabs/pocket-parks/releases) with builds for macOS and Linux,
and the game shows the latest entry in its "What's new" card.

## [Unreleased]

### Added
- **Park charm:** guests now rate the walk between stops. A long walk past decor, water, open grass and a mix of
  buildings is a lovely stroll: they cheer up and spend more at the next stop. A long walk past rows of the same stand,
  packed paving, litter or wrecks is a dull walk: they grumble and spend less.

### Changed
- What guests spend depends on their mood. Happy guests pay in full, and unhappy ones often skip buying.
- **The build bar tucks itself away** to a small tab when you're not using it, and slides back up when the mouse nears
  the bottom edge or you press **B**. Use the pin on the bar to keep it open. It never hides while you're placing
  something.

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
