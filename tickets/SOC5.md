---
id: SOC5
title: Mischief in person and the blacklist
status: done
deps: SOC2, SOC6
area: social
parent: M5
human: false
owner: worker-SOC5
since: 2026-11-27T01:25:51
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

> **review 2026-11-27T01:19:22:** Built: in-person mischief + blacklist. ParkSim (scripts/park_sim.gd): characters carry actor fields (crimes, loot, spied, strike); crimes_for(name) offers Wreck/Litter/Steal/Spy beside an open attraction/shop (Steal only at shops); avatar_strike runs the same crime code as actors (_strike split into _crime), exposed for STRIKE_TICKS and can't walk meanwhile; loot/blueprints delivered when the character stands on the gate or leaves (leave_avatar). Guards who see a striking character catch it on the spot (_ban: fine like an actor, loot back, out of the park, blacklisted for sim.ban_days, default 3). accuse_avatar(name, days) bans 1-7 days after a crime, else wrongful (host pays, no ban). blacklist name->days counts down in new_day(); send_limit halved, send_cost x2, join_avatar refused while banned; sent_by carries banned. Net: crime {t,kind} message, avatars carry a strike flag, banned rides in the ledger's inside. SaveGame keeps blacklist + ban_days. UI: Send panel gets a coral 'You, in person:' action row (only where crimes apply) + blacklist reason line; host clicks a visitor's character -> card with Ban for N days -/+ and Accuse; HUD top-left 'Blacklist' chip unfolds to the guard-catch default (-/+) and names with days left + Lift; a striking character's name tag turns coral. Client: toast 'Blacklisted here for N days: your character went home' (character rejoins your home park; you can still watch and send at x2). Back home after a crime in a live park walks your character to the gate first so the loot arrives while connected. Files: scripts/{park_sim,net,save_game,visit_panel,info_card,hud,walker_view}.gd, main.gd, tests/test_blacklist.gd, tests/show_blacklist.gd. ./gd check: all ok (incl. new test_blacklist: witnessed strike -> 3 days over ENet, client hears it, limit halved, rejoin gets no character, send costs x2, accuse 5 days, wrongful no ban, expiry after 5 days, gate loot delivery, clamp, save). Shots: shots/SOC5.png (Mia's accuse card with Ban for 5 days, Blacklist unfolded with Theo/Juno + Lift) and SOC5-visit.png (action row beside a shop, a friend's coral striking tag) look right. Not verified: real two-machine feel, the walk-out-then-travel timing, click-picking a visitor at all zooms. Guesses: effect happens at strike start like actors; a guard catches a striking character instantly (no chase); mixed crimes are fined at the worst crime's base x crimes; a blacklisted visitor stays connected (watch + send) but has no character; banned in a bot park works locally only; no host toast on a guard catch (the arrest float + Blacklist chip show it). Owner two-machine test: A hosts and hires a guard; B joins A, walks beside a shop, presses Steal -> A sees B's coral tag and the robbed toast. If A's guard is near: B is caught, B gets the blacklisted toast and goes home, A's Blacklist chip shows B · 3 days. Else A clicks B's character, sets 5 days, Accuse. B rejoins: no character, reason line says double prices/half limit; Send guest costs $6. A: Lift -> B can walk in again. Also: A accuses B before any crime -> A pays $40, no ban. Next day on A counts the days down.
