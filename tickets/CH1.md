---
id: CH1
title: Park charm: path charm and stroll scoring
status: todo
deps: 
area: sim
parent: 0.3
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Park charm". Pure logic in ParkSim (or a small `Charm` class it uses).
- `charm(cell) -> float` (about -1..1) for every path tile, recomputed when the map changes (cache per map revision, plus litter
  and wrecked changes). Within ~2 tiles: + decor appeal, + water, + variety (distinct building ids in view), + open grass;
  − the same building id repeated nearby (anti-spam), − packed clutter with no open grass, − litter, − wrecked. Weights in
  one const block, commented.
- Each guest tracks the walk since its last stop (tiles, summed charm). At arrival: if the walk was ≥ 6 tiles, then avg ≥ 0.35
  is a **lovely stroll** (+mood, next purchase +30%) and avg ≤ -0.1 is a **dull walk** (−mood, next purchase −30% or skipped
  when mood is low); shorter walks are neutral. Store the last verdict on the guest (`stroll: "lovely"|"dull"|""`) for CH2.
- Spending scales with mood (a clear curve: below 30 mood guests often skip buying; above 70 they pay in full plus any
  stroll bonus).
## Acceptance
`tests/test_charm.gd`: decor raises a tile's charm; 4 identical snack stands in a row score lower than 4 different
buildings; a fully packed area scores lower than one with open grass; a long charming route yields "lovely" and more income
than the same length dull route (seeded); short walks are neutral. Existing sim tests stay green (retune if needed and say so).
`./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
