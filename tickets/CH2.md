---
id: CH2
title: Charm view, stroll marks, charm in cards
status: done
deps: CH1
area: ui
parent: 0.3
human: false
owner: worker-CH2
since: 2026-11-27T03:47:31
---
## Goal
Make charm visible (`docs/design/game.md` → Park charm).
- **C** toggles a *charm view*: path tiles tinted from muted STONE (dull) through GRASS to a soft BUTTER glow (charming),
  buildings slightly faded so the paths read. A tiny legend chip ("Charm view · C") while it's on.
- Guests show a small ♥ (CORAL) puff after a lovely stroll and a ~ (STONE) after a dull one, for ~2 s, with `Motion`.
- The building card gains a line: "Paths here: lovely / pleasant / dull" (average charm of the path tiles touching it), and a
  tip line when dull ("Add decor or variety nearby").
## Acceptance
Shots: charm view on a park with one lovely and one dull area; a guest with a ♥. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.

> **review 2026-11-27T03:41:42:** Built: C toggles charm view (main.gd key, scripts/charm_view.gd = CanvasLayer legend chip 'Charm view · C' with STONE/GRASS/BUTTER dots + static tint()). ZooView tints path BuildingViews by sim.charm (new BuildingView.tint, drawn at the right depth) and fades other buildings to alpha 0.4. Stroll marks: ParkSim.strolls log {tick,pos,stroll} appended in _judge_stroll; Feedback.stroll_mark pops a small cloud chip with a CORAL heart (polygons) or STONE ~ wave over the guest, drifts up 2 s (Motion.STROLL_TIME/RISE), vanishes. Card: ParkSim.path_charm(origin) = avg charm of path tiles 4-adjacent to the footprint (NAN if none) + ParkSim.charm_word -> 'Paths here: lovely/pleasant/dull', plus 'Add decor or variety nearby' when dull; shown for every non-path building. CHANGELOG line added. ./gd check: 34 ok (test_net failed once in an earlier run on network ports, passed on rerun; unrelated). Tests added to tests/test_charm.gd (stroll log, path_charm ordering + NAN, charm words, tint endpoints). Shot: ./gd shot shots/CH2.png 3 res://tests/show_charm.gd shows the start park zoomed in: grey paved stand-lined corner on the left, yellow tree/fountain stretch on the right, legend chip top centre, a ♥ near the fountain and a ~ on the dull side, card of a dull stand with the tip. Guesses: faded = modulate alpha 0.4 (translucent trees show their inner parts a bit; owner may prefer another fade); mid-charm paths are GRASS-coloured and sit on grass ground, readable only by their raised edge; C does nothing while visiting and turns off on entering a visit; the stroll marks come from the sim's log, so in the shot they were triggered directly. Not verified: the live feel of marks appearing in play, the C key while the chat is open.
