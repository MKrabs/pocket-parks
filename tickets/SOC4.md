---
id: SOC4
title: Chat: speech bubbles and a log
status: todo
deps: SOC2
area: social
parent: M5
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → M5 chat. You talk **through your character**.
- Press **Enter** (or a small chat button) to type a line (max 80 chars). It shows as a rounded speech bubble over your
  character for ~5 s (with `Motion` pop and vanish), and in a small fading chat log (bottom-left, above the speed buttons,
  last 6 lines, names in their colour).
- Everyone in that park sees it: the host relays a visitor's line to all visitors and shows it in its own park. At home, your
  own lines appear over your own character.
- Typing must not trigger hotkeys (T, R, F9, WASD...).
## Acceptance
In-process test: a client's line reaches the host and the other client; the log keeps the last 6. Shot with two bubbles and the
log. `./gd check` ok.
