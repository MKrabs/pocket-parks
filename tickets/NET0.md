---
id: NET0
title: Network test: find nearby parks and visit one live
status: todo
deps: 
area: net
parent: M4
human: false
owner: 
since: 
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
