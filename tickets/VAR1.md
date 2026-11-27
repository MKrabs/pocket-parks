---
id: VAR1
title: Building size variants
status: todo
deps: BAR1
area: buildings
parent: 0.3
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → Habitats and animals → "Shops are not free-shaped". Building types get size variants.
- Catalog: a building can name its `variants` (ids of the same role and family). Zoo: **Snack Cart** (1×1, today's snack
  stand) → **Hot-dog Stand** (2×1) → **Burger Diner** (2×2). Festival: Food Truck → **Taco Truck** (2×1) → **Food Hall**
  (2×2). Cinema: Popcorn Stand → **Candy Bar** (2×1) → **Lobby Café** (2×2). Bigger means more capacity and a higher price
  (your numbers, in the catalog). New models in the shape language (CLAUDE.md, Look).
- The build bar shows **one button per family**, with small ‹ › arrows to switch the variant (the button shows the current
  variant's name and price). While placing, **1/2/3** switch variants too.
- Charm treats variants of one family as "the same building" for the repetition penalty (CH1), if CH1 has merged. Otherwise
  leave a note.
## Acceptance
`tests/test_variants.gd`: families resolve; footprints and prices differ; switching while placing keeps the ghost. Shot of
all variants plus the build bar with arrows. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
