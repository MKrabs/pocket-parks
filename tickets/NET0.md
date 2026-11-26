---
id: NET0
title: Network test: find nearby parks and visit one live
status: done
deps: 
area: net
parent: M4
human: false
owner: worker-NET0
since: 2026-11-26T23:14:07
---
## Goal
The first step of `docs/design/game.md` → Decided: networking. Two copies of the game on the same network (or the same
machine) find each other, and one can visit the other's **real, live** park. Read-only for now: no sending yet (NET1).
- `scripts/net.gd` (an autoload or a node from `main.gd`). Each game:
  - hosts its park with `ENetMultiplayerPeer.create_server` on the first free port from 24610;
  - announces itself with UDP broadcast every 2 s: park name, player name, port, theme. Two copies on one machine can't
    both bind the same UDP port, so listen on the first free port in 24600–24609 and broadcast to every port in that range
    (both to 255.255.255.255 and 127.0.0.1). A park that isn't heard from for 6 s drops off the list.
  - Player name: the OS user name for now, plus a random 2-digit suffix so two local copies differ.
- The **Visit picker** shows a "Nearby" section (real parks, with a small live dot) above the bot parks.
- Visiting a real park: connect as an ENet client (a separate `MultiplayerAPI` from the host side, e.g. via
  `get_tree().set_multiplayer(api, path)`), receive the map once (buildings, rotations, levels, construction sites)
  and then the live state about 10×/s (people with positions/kind/state, litter, closed, pins). Show it with the existing
  views and the cloud transition. The host's own game keeps running normally while it's being visited.
- Keep the wire format small and plain (Dictionaries via `var_to_bytes` or RPCs). Disconnects return you home with a toast.
## Acceptance
- `tests/test_net.gd`: **in one process**, a host and a client over ENet on 127.0.0.1; the client receives the host's map
  and sees a guest move. Discovery: a broadcast from one listener is heard by another bound to a different port.
- `./gd check` ok. Handoff: exact steps for the owner to test with two windows (`./gd run` twice) and what you couldn't verify.

> **review 2026-11-26T23:10:59:** Built scripts/net.gd (class Net, a Node added by main.gd): hosts our park with ENetMultiplayerPeer.create_server on the first free port from 24610, listens for discovery on the first free UDP port in 24600-24609, and announces every 2 s (id, park name, player, port, theme) to every port in that range on 255.255.255.255 and 127.0.0.1. A park not heard from for 6 s drops off the list. Player name = $USER (or $USERNAME) plus a random 2-digit suffix. Visiting: Net.join() opens its own ENet client peer and polls it by hand, so neither side uses the tree's MultiplayerAPI and host and visit stay separate. The host sends the map {buildings, levels, rotations} on connect, and again whenever its serialized layout changes (so builds and finished upgrades show up). Live state goes out at ~10/s: guests as compact arrays [id, kind, pos, state, mood, wanted], staff [kind, pos, walking], builders, jobs (sites), litter, closed, and robbed events from the last 20 s. That last part is the pin data: the mirror sim's building_status works with it, but visits still don't draw pins (they didn't for bot parks either). The client writes all of this into a mirror ParkMap/ParkSim that is never stepped, and the existing ZooView and WalkerView draw it behind the cloud transition. Disconnects (host closes, or no answer) emit lost, and main shows a toast and travels home. While you are away the host's own day runs at 1x (same as a bot visit). main.gd: visit() branches to _visit_live for offers with live=true; the shared view swap moved into _enter_visit; send() refuses during a live visit; step_world no longer keeps visits[0] alive during a live visit; T also updates the announced theme. visit_panel.gd: the picker has a 'Nearby' section (a MOSS live dot left of the park name, or 'No parks on your network yet') above 'Bot parks'. watch(title, sending=false) hides the Send buttons and the ledger, leaving the title and Back home. Tests: tests/test_net.gd covers, in one process, two Nets on different UDP ports (the announce is heard on the other port, a game doesn't list itself), then a client over ENet on 127.0.0.1: the map arrives, the client sees the host's guest at the same position, then sees it move, a newly placed tree gets resent, and the host closing triggers lost. ./gd check: all ok, including test_net. Screenshots: tests/show_net.gd runs a second 'game' in the same process (Net hosting a festival bot park as Otter Lane / sam42). shots/NET0.png shows the picker with Otter Lane under Nearby with its dot. NET_VISIT=1 ./gd shot shots/NET0-visit.png 10 res://tests/show_net.gd shows the live visit: the festival park with guests on its paths and a small panel with just 'Otter Lane · sam42' and Back home. OWNER TEST, two windows: 1) ./gd run in two terminals. 2) Wait ~2 s, then click Visit in window A: the other copy is under Nearby as 'Pocket Zoo' / '<user><NN> · zoo' (both parks are named Pocket Zoo; the player suffix tells them apart). 3) Pick it: clouds, then B's park, with guests moving live. 4) In B, build something or press T and build: it appears in A within ~0.1 s (sites show scaffolds). 5) Close B: within a few seconds A gets the toast 'Lost the connection: back home' and returns. 6) Back home also works. For two machines, both on the same LAN; the firewall must allow UDP 24600-24609 and 24610+. NOT VERIFIED: two real windows or two machines (only in-process and offscreen); LAN broadcast delivery (only loopback is tested); how long ENet takes to notice a host that crashed instead of closing (ENet timeout, likely 5-30 s); how smooth the motion looks at 10 Hz with no interpolation (people may step slightly). GUESSES: the disconnect toast reuses the 'wrecked' kind (coral, hammer glyph), since no toast kind fits; the picker only lists parks seen when it opens and doesn't refresh while open; ENet free ports are found by probing with a UDP bind first, to avoid ENet's error log; the park name is the HUD's 'Pocket Zoo', the same for everyone; the visit title is 'park · player'.
