---
id: SOC3
title: Presence: who's here
status: todo
deps: SOC1, SOC2
area: social
parent: M5
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → M5 presence.
- **At home:** a small presence chip under the money in the top-right: colour dots plus "2 visiting" when friends are in your
  park in person. Hover or click lists the names. A friendly toast when someone arrives or leaves ("Sam is visiting").
- **While visiting:** the Send panel's title row shows "Also here:" with the other visitors' colour dots and names
  (and the host, if their character is in the park).
- The host's game sends the presence list with the live message, or as its own small message on change.
## Acceptance
In-process test: two clients join one host, and each sees the other in "also here"; the host sees both; a leave updates
everyone. Shots of the chip and the visit title row. `./gd check` ok.
