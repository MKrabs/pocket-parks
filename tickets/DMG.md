---
id: DMG
title: Damaged building models
status: done
deps: 
area: buildings
parent: M3
human: false
owner: worker-DMG
since: 2026-11-26T23:17:35
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

> **review 2026-11-26T23:13:24:** Built: wrecked buildings now show a damaged variant built from their own parts; the old grey-and-tilted look is gone. building_view.gd: static wreck_plan(id, turn, origin) is seeded by hash(origin) and decides which parts fall, where they land and at what tilt, which corners get chipped, and 3-5 STONE or WOOD rubble blocks. A part falls if it starts at or above 60% of the building's height, and only on buildings at least 12px tall, so the flat pond and path only get chips and rubble. Fallen parts slide off a front side (+x or +y) and lie tilted on the ground. The body is drawn 93% size, and the top 35% of parts that are at least 6px tall and 0.2 tiles wide is drawn with two corner squircles cut out (Geometry2D.clip_polygons). Level flags tip over. Colours go 7% darker and 20% less saturated; there is no grey wash. A new 'broken' value (0..1) replaces 'grey' and 'rotation'. Wreck tweens it to 1 with TRANS_BOUNCE (Motion.CRUMBLE_TIME). Repair or reopen tweens it back to 0 with TRANS_BACK (Motion.MEND_TIME), so parts overshoot and hop into place, with a Motion.MEND_HOP arc in between. TILT_TIME was removed from motion.gd. Files: scripts/building_view.gd, scripts/motion.gd, scripts/zoo_view.gd (comment only), tests/test_wreck.gd (new: same origin gives the same break, snack-stand roof falls and body stays, 3-5 rubble, pond has nothing that falls), tests/show_wrecked.gd (new). ./gd check: every test ok. Screenshot shots/DMG.png (./gd shot shots/DMG.png 1 res://tests/show_wrecked.gd) shows every zoo and festival building intact above its wrecked version. Roofs, the fountain's top bowl, the gate beam, tree canopies and the aviary dome top all land tilted beside their building; chips and rubble show; colours stay pastel. CIN has not merged, so there is no cinema building in the shot. Not verified: how the crumble and hop animations feel in motion (a still shot can't show that). Guesses (all tuning consts at the top of building_view.gd): what counts as a top part (the 60% height rule); the festival stage's tall back wall and rail count as top parts, so they fall and the rail lies far out across the neighbouring tile; fallen parts and rubble may draw over neighbouring tiles. The feedback.gd debris puffs still play on wreck, as before.
