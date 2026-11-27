---
id: SOC1
title: Identity: choose your name and colour
status: todo
deps: 
area: social
parent: M5
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → M5 identity. Today everyone is "<login><2 digits>" and every park is "Pocket Zoo".
- First start (and later via the park name in the HUD's top-left): a small rounded card to set **your name** (2–16 chars),
  **your park's name**, and **your colour** (pick one of 6 palette swatches: SKY, CORAL, BUTTER, MOSS, CLAY, WATER).
- Saved with the park (SaveGame, optional keys, so old saves load). Used everywhere: the HUD title, Net announcements and
  hello (player name, park name, colour), the Visit picker rows (a small colour chip next to friends), the cloud title.
- Keep `net.player` stable once chosen. Two copies on one machine with PARK_SAVE still differ.
## Acceptance
`tests/test_identity.gd`: name validation, save round trip, announce carries name/park/colour. Shot of the card. `./gd check` ok.
