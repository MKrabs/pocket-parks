---
id: NET1
title: Send people into a friend's real park
status: todo
deps: NET0, SAVE
area: net
parent: M4
human: false
owner: 
since: 
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
