---
id: SOC1
title: Identity: choose your name and colour
status: done
deps: 
area: social
parent: M5
human: false
owner: worker-SOC1
since: 2026-11-27T01:21:00
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

> **review 2026-11-27T01:14:45:** Built the identity card (scripts/identity_card.gd, a CanvasLayer like VisitPanel). It has your name (2–16 chars, trimmed), your park's name (2–24, a guess), 6 squircle swatches (SKY/CORAL/BUTTER/MOSS/CLAY/WATER), and Cancel and Save buttons. Save is disabled while a name is invalid. The card opens on first start when there is a real save path and no nick is saved yet, which also covers old saves. It also opens when you click the colour chip or park name in the HUD top-left (new Hud.name_pressed and set_identity). Net gets nick, colour and the existing park_name, all in Net.state(), so they're saved under the optional 'net' key and old saves load with defaults. Announce carries nick and colour, which are optional on receive so older copies still list. Offers show the nick as 'player' and carry 'colour'. Hello also sends nick and colour, but the host doesn't use them yet. In the Visit picker, friend rows draw their colour chip left of the name line. The cloud title going home now shows your park name instead of 'Home'. The picker's 'you are' shows the nick. Design choice: net.player stays the stable random id (login+2 digits), and ledgers are still keyed on it. The nick is display only. So renaming never loses money owed, and two copies with PARK_SAVE still differ even if both pick the same name. Tests: tests/test_identity.gd covers validation, colour lookup, the save round trip through SaveGame write/read, old-save defaults, and that an announce over loopback carries nick, park and colour. ./gd check: all ok. Screenshot (tests/show_identity.gd → shots/SOC1.png): the centred cream card on the paused park, prefilled with the login name, the park 'Otter Bay' and the CORAL swatch ringed. The HUD top-left shows the coral chip and 'Otter Bay'. Not verified: clicking the HUD name, typing in the fields, the live picker chip with two real machines (the shot only covers the card). Guesses: the default name is the capitalised login (e.g. 'Mago 2'); Cancel on first start just asks again next launch. Worth an owner eye: CORAL and CLAY swatches look quite similar.
