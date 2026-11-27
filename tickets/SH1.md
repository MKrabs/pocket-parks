---
id: SH1
title: Shape-language rework: dome, wall, glass, fences
status: todo
deps: 
area: buildings
parent: 0.3
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Shape language". Replace the "many small blocks" compromises with one clear silhouette each:
- **Aviary:** a single smooth translucent dome (layered half-superellipse polygons in a pale SKY/CLOUD with low alpha, a
  highlight arc) with 3–4 thin WOOD net arcs over it, not beaded posts.
- **Reinforced enclosure:** one continuous STONE wall that follows the outline, with a cap band, a darker base and a few
  buttresses, not pillars.
- **Water tank:** glass sides (translucent WATER panels with a highlight stripe), water filling *inside* below the rim
  with a lighter surface ellipse, a STONE base and rim. No blob between pillars.
- **Fences** (enclosure, and anywhere posts are used as a ring): a continuous WOOD rail with posts every ~3 tiles of
  outline.
- Damaged variants (`wreck_plan`) still work with the new shapes. Give the dome and wall sensible wrecked looks: a torn
  net, a breach.
- Audit the other buildings for the same problem, and fix up to two more if they clearly read as "too many small blocks".
## Acceptance
Shot (show script): every changed building intact and wrecked, next to the previous look if easy. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
