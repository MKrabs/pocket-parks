---
id: HAB1
title: Habitats: paint areas with fence types
status: todo
deps: SH1, VAR1, CH2
area: zoo
parent: 0.4
human: false
owner: 
since: 
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
