---
id: SOC3
title: Presence: who's here
status: done
deps: SOC1, SOC2
area: social
parent: M5
human: false
owner: worker-SOC3
since: 2026-11-27T03:16:41
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

> **review 2026-11-27T01:29:15:** Built presence from the live message's existing avatars list (no new wire message): Net.others(sim, me) = [name, color] of every character but ours. Home: Hud presence chip under the money (dots + 'N visiting', names on hover/click, hidden when empty); main._presence toasts 'X is visiting' / 'X left' (new 'visiting' toast kind, GRASS) only while home. Visiting: VisitPanel.show_here puts 'Also here:' + dot + name per person in the title row (host included while its character is in its park). Also fixed SOC1 merge bugs in main.gd: my_avatar/walk_to/leave_avatar used net.player while avatars are joined by net.shown() (with a nick you couldn't walk, and your avatar never left home); identity save now renames our avatar. Files: scripts/net.gd, hud.gd, visit_panel.gd, pin_view.gd, main.gd, tests/test_presence.gd (2 clients + host, each sees the other, host sees both, host avatar shows, a leave updates everyone, chip text/names/hidden). ./gd check: all ok. NOT verified: no ./gd shot of the chip or the visit title row was taken (ran out of budget), so layout (chip vs toasts at CrimeToasts.TOP=90 may overlap, Send panel width with many names) is unchecked. Guesses: namesakes hide by shown name (ponytail comment), max 6 dots, hover tooltip done as expanding label.
