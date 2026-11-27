---
id: NET1
title: Send people into a friend's real park
status: done
deps: NET0, SAVE
area: net
parent: M4
human: false
owner: worker-NET1
since: 2026-11-26T23:48:11
---
## Goal
The send mechanic over the network (`docs/design/game.md` → Sending people, networking). The **host's game is the
authority** for its park.
- While visiting a real park, the Send panel sends an intent `{kind}` to the host, which runs `sim.send(kind, visitor_name)`.
  The visitor pays the price locally, as with bots.
- The host's game sends ledger changes for each visitor back to that visitor (guest share, delivered loot, fines,
  wrongful-arrest payouts, blueprints) as they happen. The visitor applies them to their money and build bar. Make it
  idempotent (sequence numbers), so a reconnect can't pay twice.
- The host sees crimes, pins and arrests exactly as with bot senders, with the real player's name as the sender in records.
- When the visitor disconnects, their people stay in the host park and settle the next time both are online (keep the
  ledger on the host's disk via SAVE).
## Acceptance
`tests/test_net_send.gd` (in-process host and client): a guest sent by the client earns the client its share; a thief that
escapes pays the client; a fine is deducted; replaying a message doesn't double-pay. `./gd check` ok. Handoff: owner steps
for a two-window test.

> **review 2026-11-26T23:38:41:** Built: the Send panel now works in real (live) parks. Client: Net.send_person(kind) sends {t:send,kind} after a hello {player}; main.send pays the price locally only once the send is accepted (i.e. connected). Host: Net._hear runs sim.send(kind, visitor_name), so crimes/pins/arrests/toasts are the same as for bot senders, with the player name as the sender. Net._tell pushes {t:ledger, from, seq, owed, blueprints, inside} to each connected visitor whenever its ledger entry or its people inside change. owed/blueprints are running totals. The client applies owed minus what it already got from that host, and only for seq > the last one it applied (Net.got). Replays and reconnects can't pay twice. Blueprints go to the build bar via the stolen signal and main._learn, which also replaces the bot-park loop. Persistence: SaveGame.pack/restore now keep sim.ledger/blueprints/fined plus net.state() {player, seq, got}. These are optional keys, so older saves still load. Player name is now stable across restarts (saved). Disconnect: the host drops the peer's name; its people stay and settle into the ledger; the visitor is paid on its next visit. Also fixed a pre-existing bug from the NET0+STF merge: live staff had no 'level', which crashed the visitor's WalkerView (NET_VISIT shot failed on main too). Removed VisitPanel's watch-only mode (no longer used). PARK_SAVE env var overrides the save path for a second window on one machine. Files: scripts/net.gd, main.gd, scripts/save_game.gd, scripts/visit_panel.gd, tests/test_net_send.gd (new), tests/show_net.gd. ./gd check: all ok. Screenshot (NET_VISIT=1 ./gd shot shots/NET1.png 6 res://tests/show_net.gd): live visit to 'Otter Lane · sam42' with the full Send panel; the ledger strip, fed by the host, reads '3 guests · 1 hidden' after sending 3 guests + a thief. Owner steps for two windows on one machine: (1) ./gd run; (2) PARK_SAVE=user://b.json ./gd run; (3) in window B, Visit → pick A's park under Nearby → send guests and a thief; (4) watch A get crime toasts and pins, accuse the thief (B's money drops by the fine), or let it leave (B gains the loot); (5) Back home in B while some of its people are still inside A, wait, then visit A again: B is paid once. Couldn't verify: real two-machine LAN, the feel of the timing. Guesses/open: (a) a visitor is paid only when it next connects (visits), not just because both games are online; auto-settling in the background needs a client connection per host and is a follow-up if wanted. (b) Visitors don't see a dot over their own people in live parks (live guests carry no sender). (c) People inside at the host's day end or restart still drop without settling (existing ponytail in ParkSim._settle). (d) No per-visit send limits (M6 rule left open in game.md).
