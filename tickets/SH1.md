---
id: SH1
title: Shape-language rework: dome, wall, glass, fences
status: done
deps: 
area: buildings
parent: 0.3
human: false
owner: worker-SH1
since: 2026-11-27T03:34:22
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

> **review 2026-11-27T03:28:07:** Built: parts can now carry a 'kind' (Buildings.shaped / Buildings.ring in scripts/buildings.gd) that BuildingView draws as one silhouette (scripts/building_view.gd: _shaped, _ring_shape, _dome). Aviary = translucent SKY superellipse dome (convex-hull shell + paler upper layer + CLOUD highlight arc + soft outline) with 4 thin WOOD meridian arcs (back ones faint) and a WOOD footing ring. Reinforced = one continuous STONE wall along the outline (darker base band, lighter cap band, top cap) with 8 buttresses (2 per side). Water tank = STONE plinth, translucent glass ring with a CLOUD highlight stripe and STONE rim, WATER inside below the rim with a lighter surface squircle; no pillars. Enclosure fence = two continuous WOOD rails + a post on each diagonal (~2.5 tiles of outline apart). Rings split into far/near halves so inside items draw between them (rotation sort works via catalog order). Wrecks: wreck_plan gains 'gap' (outline angle facing the viewer); shaped parts never fall/chip; rings get a V breach notch there (fence rails/posts broken, glass cracked + water drops), the dome sags, a jagged flap tears open and the nearest net arc snaps and sags. Files: scripts/buildings.gd, scripts/building_view.gd, scripts/themes/zoo.gd, tests/test_wreck.gd (shaped parts break in place on every turn, ring halves ordered, torn dome draws), tests/show_shapes.gd (new), CHANGELOG.md. ./gd check: all ok. Shots: ./gd shot shots/SH1.png 1 res://tests/show_shapes.gd shows the 4 buildings intact / wrecked / turned 1; tests/show_wrecked.gd shows them among all buildings; main scene renders the new fence fine. Previous look: render show_wrecked.gd on main for comparison (not side by side in one shot). Audit: festival/cinema/other zoo buildings don't read as 'many small blocks', so no extra ones changed. Not verified: the crumble/mend tween in motion (only end states shot). Guesses: 4 fence posts (ticket says ~3 tiles; on a 3x3 ring that's one per diagonal), dropped the rock/weed from the tank for a clean water surface, torn-dome look is a flap cut from the footing up (no holes in a polygon).
