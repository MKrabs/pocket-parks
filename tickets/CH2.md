---
id: CH2
title: Charm view, stroll marks, charm in cards
status: todo
deps: CH1
area: ui
parent: 0.3
human: false
owner: 
since: 
---
## Goal
Make charm visible (`docs/design/game.md` → Park charm).
- **C** toggles a *charm view*: path tiles tinted from muted STONE (dull) through GRASS to a soft BUTTER glow (charming),
  buildings slightly faded so the paths read. A tiny legend chip ("Charm view · C") while it's on.
- Guests show a small ♥ (CORAL) puff after a lovely stroll and a ~ (STONE) after a dull one, for ~2 s, with `Motion`.
- The building card gains a line: "Paths here: lovely / pleasant / dull" (average charm of the path tiles touching it), and a
  tip line when dull ("Add decor or variety nearby").
## Acceptance
Shots: charm view on a park with one lovely and one dull area; a guest with a ♥. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
