---
id: CH1
title: Park charm: path charm and stroll scoring
status: done
deps: 
area: sim
parent: 0.3
human: false
owner: worker-CH1
since: 2026-11-27T03:31:51
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

> **review 2026-11-27T03:24:30:** Built park charm + strolls in ParkSim (scripts/park_sim.gd), no new class. charm(cell) scores each path tile from the 5x5 around it (CHARM_* const block, commented): +decor appeal (0.04/pt, cap 0.5), +water 0.2, +variety 0.08 per distinct id beyond the first (cap 0.32), +open grass up to 0.2 at 8 free cells, -0.15 per repeated non-decor id, -0.25 if <3 free cells, -0.12 per litter tile, -0.3 per wrecked building; clamped -1..1. Cache cleared in _load (map change), rebuilt when hash(litter keys, closed keys) changes. Guests count walk_tiles/walk_charm while walking; _arrive judges it (>=6 tiles: avg>=0.35 lovely +6 mood, <=-0.1 dull -6 mood), stores g.stroll ('lovely'|'dull'|'') for CH2. spend_factor(g): mood<30 skips 50% of the time (always after a dull walk), 30..70 ramps 0.7->1.0, >=70 full; x1.3 lovely / x0.7 dull. Shop pay, cash_events and today income use the paid amount; +5 mood and litter chance only when they actually buy. Tests: new tests/test_charm.gd covers decor, litter+cache, 4 same stands vs 4 different, packed vs grass, 12-tile tree-lined route = lovely and more per visit than the paved one (seeded), short walk neutral, spend curve. ./gd check: all ok (0 non-ok lines), existing sim tests green with no retuning. CHANGELOG Unreleased updated. No screenshot: no visuals changed. Guesses: 'water' = a building whose specialty is water (fountain, pond, water tank), so no theme data change; the repeat penalty skips decor so a row of trees isn't punished; path/entrance tiles count as neither grass nor buildings; stroll bonus applies at the stop it ends at (attractions have no price, so only shops). Not verified: how it feels in a real park (weights untuned beyond the tests).
