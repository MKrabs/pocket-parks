---
id: DMG
title: Damaged building models
status: doing
deps: 
area: buildings
parent: M3
human: false
owner: worker-DMG
since: 2026-11-26T22:58:00
---
## Goal
Replace the "grey and tilted" wrecked look with a real **damaged variant** of each building, generated from its parts
(no per-building art). In `building_view.gd`, with timings in `motion.gd`:
- Wrecked: the top parts (roof, canopy, flags) slide off and lie tilted on the ground beside the building, the body gets
  a few chipped corners (smaller squircles cut out, so draw the body slightly smaller with an uneven top), and 3–5 small
  STONE or WOOD rubble blocks lie around it. Colours shade a bit darker and desaturate a little, but stay pastel. No grey wash.
- Transitions: wreck = a quick crumble (parts drop with `Motion`); repair or auto-reopen = parts hop back into place.
- Deterministic per building (seeded by origin), so the same building always breaks the same way.
## Acceptance
Shot `shots/DMG.png`: every zoo building intact next to its wrecked version (show script), plus one festival and one
cinema building if CIN has merged. `./gd check` ok.
