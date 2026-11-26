---
id: SAVE
title: Save and load your park
status: done
deps: MAP, STF
area: core
parent: M4
human: false
owner: worker-SAVE
since: 2026-11-26T23:26:28
---
## Goal
With no server, your park lives on your disk (`docs/design/game.md` → networking). Save to `user://park.json`.
- Everything needed to resume: map (buildings, rotations, levels, owned plots), construction jobs, builders and their
  specialties, staff with levels, money, XP/park level, day and tick, the theme, stolen blueprints. Guests and litter
  don't need saving (a fresh crowd is fine).
- Autosave every 30 s of game time and on quit (`NOTIFICATION_WM_CLOSE_REQUEST`). Load on start; no file = the seeded
  start park. Add a version number to the file.
- A debug key `F9` = start a new park (confirm with a small card).
## Acceptance
`tests/test_save.gd`: save then load gives an equal park (compare a canonical dict); an old/unknown version falls back to a
new park without crashing; a corrupt file doesn't crash. `./gd check` ok.

> **review 2026-11-26T23:25:07:** Built scripts/save_game.gd (SaveGame: pack/restore/to_text/from_text/read/write, VERSION=1, PATH=user://park.json). The JSON comes from JSON.from_native, so Vector2i keys and typed arrays survive the round trip. It saves: map (buildings, levels, rotations, owned plots, bought, specialties), money, xp, tick, day, theme, stolen blueprints, staff [kind, level], construction jobs, and builders (name, shed, pos, state). main.gd loads on start (no file or bad file = seeded park, now in _seed()), autosaves every 30 s of sim ticks (AUTOSAVE, counted in advance(), so it follows the game speed) and on NOTIFICATION_WM_CLOSE_REQUEST. F9 opens a small card in the HUD ('Start a new park? / Keep playing / New park'). New park deletes the file, switches to the zoo theme and reloads the scene. Saving only runs when main is the current scene and not under Movie Maker, so tests and ./gd shot never read or write the real save. Tests: tests/test_save.gd covers save -> file -> load giving an equal canonical dict (the park has a site with a builder on its way, a turned shop, staff levels, a specialty and a bought plot), an unknown version, six corrupt texts (empty, truncated, plain JSON, wrong types) and a missing file. ./gd check: all 24 ok. Screenshot shots/SAVE.png (tests/show_new_park.gd): the cream card is centred over the park with two rounded buttons and nothing overlapping. I also ran a headless end-to-end probe through main.tscn: change money, day, staff, stolen, theme, close, reload; it came back the same. Then new_park gave $500, day 1, zoo and deleted the file. I removed the probe's file afterwards. Not verified: a real window close (the probe sent the notification directly) and the F9 key feel. Guesses: staff restart at the gate. Wrecks, the sender ledger, visits in progress and money other parks still owe are not saved. The sim RNG reseeds to 1 on load. A save naming a building or stolen blueprint this build doesn't know drops it. Only the top-level types of the file are checked, so a hand-edited file with wrong inner types could still error.
