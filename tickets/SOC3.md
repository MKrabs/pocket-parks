---
id: SOC3
title: Presence: who's here
status: doing
deps: SOC1, SOC2
area: social
parent: M5
human: false
owner: worker-SOC3
since: 2026-11-27T01:21:00
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

> **note:** SOC1 + SOC2 merged: show `net.shown()` names (nick, else id) and `IdentityCard.colour_of(colour)` everywhere in presence. The host keys avatars and chat by the shown name (`_shown[peer]`) and ledgers by the stable id (`_names[peer]`). Never show the id when a nick exists.
> **correction (after SOC5 merged):** avatars are keyed by the stable id (`a["name"]` = player id) and carry `a["label"]` = the chosen name. Show `label`, match players by `name`.
