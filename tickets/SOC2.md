---
id: SOC2
title: Your character: walk around the park you visit
status: done
deps: 
area: social
parent: M5
human: false
owner: worker-SOC2
since: 2026-11-27T01:08:08
---
## Goal
`docs/design/game.md` → M5. You have a **character** in the park you're in: a bigger bean in your colour (SOC1 adds the
colour; use SKY until then) with a little name tag.
- **At home** your character stands near your gate and can walk your own park. **While visiting** (bot or real park) your
  character enters at that park's gate.
- Controls: click a path tile in Select mode to walk there (path-finding on paths, like guests), and WASD/arrows nudge
  along paths while the character is selected (or: hold Shift+click; pick what feels least in the way of building, and say so).
  The camera follows it softly while it walks (toggle with **F**).
- **Real parks: the host is the authority.** The visitor sends `{t:"move", cell}`. The host's sim owns an `avatar` entry per
  connected player (name, colour, cell, pos), walks it, and replicates it in the live message. Visitors see every avatar
  in that park, including the host's own character. Bot parks: the same entity, simulated locally.
- Avatars are not guests: no spending, no mood, never accused by the Accuse tool (SOC5 adds the in-person rules), and they're ignored by
  guards for now.
## Acceptance
`tests/test_avatar.gd`: in-process host + client, the client's move request walks its avatar on the host along paths and the
client sees it arrive; both avatars appear in the live state; disconnect removes the visitor's avatar. Shot with two avatars
and name tags. `./gd check` ok.

> **review 2026-11-27T01:06:39:** Built player characters (avatars). ParkSim: avatars list (name, color, cell, pos, path) plus join_avatar/leave_avatar/move_avatar/step_avatars. They're kept apart from guests, so there's no spending, no mood, Accuse and guards never see them, and load_map re-routes them. step_avatars runs every world tick at 1x, so characters still walk while the day is paused or over. Net: hello now carries color, and the host adds an avatar for each visitor at its gate. A visitor's move {t,cell} goes to sim.move_avatar on the host. The live message carries avatars [name,color,pos,walking], and a disconnect removes the visitor's avatar. Visitors get Net.move_avatar(cell). Net.color defaults to SKY until SOC1. main.gd: your character stands at your gate at home. While you're in a bot park or a real one it moves there, and it comes back to your gate when you go home. The host's own character replicates to visitors. Controls: at home, Shift+click a path tile in Select mode to walk, so plain clicks still select and building stays as it was. While visiting, a plain click walks, since you can't build there. The camera eases after your character while it walks, and F toggles that. WalkerView draws a bigger bean in the player's colour with a darker cap and a cream name tag (FONT_BOLD 9). Files: scripts/park_sim.gd, scripts/net.gd, scripts/walker_view.gd, main.gd, tests/test_avatar.gd, tests/show_avatars.gd. ./gd check: every test prints ok, test_avatar included. That test covers: entering at the gate, paths only, the in-process host+client move walking on the host until the client sees it arrive, both avatars in the client's live state with the visitor in its colour, and disconnect removing only the visitor. Shot (./gd shot shots/SOC2.png 4 res://tests/show_avatars.gd) shows two avatars on the path with readable tags, mago271 in SKY and Mia in CLAY. Not verified: mouse feel, the camera-follow feel (FOLLOW_RATE 3), and a real two-machine run. Guesses: (1) I left out WASD nudging because WASD/arrows already pan the camera, and used Shift+click at home instead. (2) Your home character leaves your park while you visit elsewhere. (3) Walk speed is 0.25 tiles/tick, a little faster than guests. (4) The avatar name is net.player, and in bot parks it is separate from the Visit.ME sender id.
