---
id: SAVE
title: Save and load your park
status: todo
deps: MAP, STF
area: core
parent: M4
human: false
owner: 
since: 
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
