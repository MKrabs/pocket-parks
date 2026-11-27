---
id: SOC6
title: Send limits per park
status: todo
deps: 
area: social
parent: M5
human: false
owner: 
since: 
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
