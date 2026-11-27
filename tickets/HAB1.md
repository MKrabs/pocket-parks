---
id: HAB1
title: Habitats: paint areas with fence types
status: done
deps: SH1, VAR1, CH2
area: zoo
parent: 0.4
human: false
owner: worker-HAB1
since: 2026-11-27T04:15:56
---
## Goal
`docs/design/game.md` → "Habitats and animals" → **How you use it**, steps 1–2 (animals are HAB2, decor HAB3). This
replaces the fixed Enclosure, Water Tank, Aviary and Reinforced Enclosure buildings in the zoo theme.
- Attractions tab: **Habitat** button with a fence-type switcher (Fence / Glass / Net / Wall, the latter three
  specialist-only via the existing builder specialties: Water / Aviary / Heavy).
- **Drag** to paint a rectangle of cells, with a live preview (outline in the fence style, cell count, cost per cell). Dragging
  again starting inside or touching an existing habitat **adds** to it (L shapes, any union of rectangles). **Right-drag**
  removes cells. Habitats must stay one connected region of at least 4 cells. Cells must be owned, free land.
- `ParkMap` stores habitats: id → {cells, fence, animal (empty for now), items (empty)}. The fence is drawn along the
  region's outline in the fence's style (SH1 shapes generalised to any outline: wood rail, glass panels, net dome over the
  bounding area, stone wall). The floor is a habitat ground colour.
- Building the fence is a construction job (builders, specialty rules, time by outline length). Guests visit a habitat from any
  path tile touching it (it's an attraction; appeal comes from size for now, then from animals in HAB2).
- Save/load and live-visit replication include habitats. The start park seeds one small wood-fence habitat in place of the old enclosure.
- Remove the old fixed enclosure buildings from the zoo catalog (keep Pond and decor). Bot parks paint a habitat or two instead.
## Acceptance
`tests/test_habitats.gd`: paint, add (L shape), remove, connectivity and min-size rules, ownership, a fence job per
specialty, guests visit, save round trip. Shots: painting preview, L-shaped habitats with each fence type. `./gd check` ok.
Handoff: how painting feels (you can't feel it; say what you'd want the owner to try). Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.

> **review 2026-11-27T04:13:11:** Built: zoo habitats are painted. ParkMap.habitats: origin (smallest cell) -> {cells, fence, animal:'', items:[]}. Each habitat is also a building entry (buildings[origin] = fence id, every cell in occupied), so sim targets, doors, charm, the info card, demolish, jobs, save and net reuse the existing paths. paint/unpaint/paint_target/unpaint_plan, outline() and connected() live in park_map.gd. Zoo catalog: Enclosure, Water Tank, Aviary and Reinforced are gone. In their place are 4 fence variants (habitat / _glass / _net / _wall, the last three specialist-only for Water/Aviary/Heavy) in one Attractions button that reuses the VAR1 variant switcher (arrows, keys 1-4). Bar label shows '$N / cell'. ParkSim.paint/unpaint open or extend a fence site: FENCE_SECONDS=1.5 per outline side; appeal and capacity = cells x 1. New scripts/habitat_view.gd (extends BuildingView) draws the floor (Palette.HABITAT), per-cell fence sides depth-sorted in four styles (wood rails+posts, glass panels on a stone plinth, rounded stone wall, net footing plus one _dome over the bounding box), and the drag preview with the label 'N cells · $X ($c / cell)' or 'Remove N cells'. Input: GridView gets a released signal. While a habitat is picked, left-drag paints, right-drag removes (right-click no longer leaves place mode then; Esc does). The start park seeds a 3x3 wood habitat where the enclosure was. Bot zoo parks paint 1-2 habitats next to a path. Save and live-visit map messages carry habitats. Removed the now-unused Buildings.ring and zoo ring helpers, and updated the tests and show scripts that used the old ids. Tests: new tests/test_habitats.gd covers paint, L add, edge add, remove, split/min-size refusals, origin re-key, ownership, money, a fence job per specialty (right builder, waits for a specialist, add extends the site, remove drops it), guests visiting with appeal by size, and a save round trip. ./gd check: 37 ok, nothing else. Shots: shots/HAB1.png (./gd shot shots/HAB1.png 1 res://tests/show_shapes.gd) shows L-shaped habitats in Fence, Glass, Net (dome) and Wall plus a live drag preview with its label. It reads well. The main shot shows the seeded wood habitat on the path. Could not verify drag feel. Owner, please try: a quick drag; growing an L from inside vs from the edge; right-drag to trim; releasing the mouse over the bottom bar (the drag then stays open until the next release on the grid). Guesses: per-cell costs 16/26/26/28 (old 3x3 prices / 9). Adding to a fenced habitat closes it again while the whole outline is re-fenced. A drag that touches two habitats, or one with another fence, is refused (no merging). Wrecks don't change a habitat's look. The net dome covers the bounding box, so it also covers the empty corner of an L. The variant arrows' tooltips still say Smaller/Bigger.
