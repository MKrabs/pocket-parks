---
id: SOC2
title: Your character: walk around the park you visit
status: todo
deps: 
area: social
parent: M5
human: false
owner: 
since: 
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
