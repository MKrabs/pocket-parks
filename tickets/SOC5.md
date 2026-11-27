---
id: SOC5
title: Mischief in person and the blacklist
status: todo
deps: SOC2, SOC6
area: social
parent: M5
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Visiting in person, limits and the blacklist". Your character can do a crime itself, and getting caught gets you blacklisted.
- Standing next to a building in a park you visit, your character's card (or a small action bar) offers **Wreck / Litter /
  Steal / Spy** where they apply. It works like the actors: a few seconds of `striking` (exposed), then the effect, and loot
  is delivered when you **leave through the gate** (or Back home walks you out). The host's sim does all of it for real parks.
- **Caught fair and square:** a guard witnesses you striking, or the host accuses your character after a crime. You're fined
  like an actor (base × crimes), and your carried loot goes back. You're **blacklisted** at that park:
  - the host picks **1–7 in-game days** on a small card when they accuse you; guard catches use the host's default (a setting, start 3);
  - while blacklisted you can't enter that park in person (join refused with a clear message, and your character is sent home);
  - sending there costs **×2**, and your send limit there is **halved** (SOC6 hooks).
  - Wrongful accusations never blacklist.
- The host has a small "Blacklist" list (in a settings or presence card) with names and days left, and can lift a ban early.
- Blacklists are saved on the host (SaveGame) and count down in the host's in-game days.
## Acceptance
`tests/test_blacklist.gd` (in-process host + client): a witnessed strike blacklists for the default days; a host accusation
with 5 days sets 5; a blacklisted join is refused; cost ×2 and limit halved; the ban expires after N days; a wrongful
accusation doesn't ban. `./gd check` ok. Handoff: owner steps for a two-machine test.
