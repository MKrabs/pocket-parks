---
id: SOC6
title: Send limits per park
status: done
deps: 
area: social
parent: M5
human: false
owner: worker-SOC6
since: 2026-11-27T01:10:59
---
## Goal
`docs/design/game.md` → "Visiting in person, limits and the blacklist". **Send limit = 3 + the sender's park level**: the most people of
yours (guests and actors together) inside one park at once.
- The host enforces it for real parks (the client sends its park level in hello and in each send; the host checks
  `sent_by(name)` counts). Bot parks enforce it locally. A refused send isn't charged.
- The Send panel shows "Inside: 4 / 7" and disables the buttons at the limit, with the reason.
- Leave a hook for SOC5: `send_limit(name)` and `send_cost(name, kind)` on the host side, so a blacklist can halve the limit and double the price.
## Acceptance
`tests/test_send_limits.gd`: the limit follows park level; the host refuses the 8th person at level 4 and doesn't charge;
people leaving free a slot. `./gd check` ok.

> **review 2026-11-27T01:07:57:** Send limit = ParkSim.SEND_BASE (3) + sender's park level. ParkSim (scripts/park_sim.gd): send_limit(name), send_cost(name, kind) (the SOC5 hooks, halve/double there), send_paid(kind, sender, level) refuses at the limit and otherwise charges via ledger; new dicts charged (saved in save_game.gd, so Earned excludes prices) and sender_levels; sent_by() now carries 'limit'. Net: level in hello and each send; host _hear runs send_paid (level clamped 1..MAX); limit rides in the ledger 'inside'. main.gd: bot parks use send_paid too, paid at once via _collect(); live sends are no longer charged locally, the host's ledger deducts the price (so a refused send is free). VisitPanel: 'Inside: 4 / 4' in the chip, send buttons disabled at the limit, a reason line under the buttons. Tests: new tests/test_send_limits.gd (limit by level, host refuses 8th at level 4 uncharged, leaving frees a slot, level-up raises it); test_net_send and test_visit_flow updated for ledger-charged prices. ./gd check: all ok. Screenshot shots/SOC6.png (show_visit): festival visit, Inside 4/4, buttons greyed, 'Full: at most 4 of yours inside at once (3 + your park level)...' line. Guesses: host charging through the ledger instead of client-side (needed for host-side send_cost; live price lands one round-trip later, so rapid clicks can briefly overspend); reason text hardcodes '3 + your park level' (SOC5 must reword when halved); client also pre-checks with the last known limit. Not verified: two-machine live play.
