---
id: BAR1
title: Auto-hiding bottom bar
status: todo
deps: 
area: ui
parent: 0.3
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Bottom bar".
- The build bar slides down (with `Motion`, ~0.25 s, ease out) to a slim handle (a small rounded tab with a chevron)
  when the mouse is away from it for ~1 s and nothing is being placed.
- It slides up when the mouse comes within ~70 px of the bottom edge or touches the handle, or with **B** (toggle).
- A small **pin** button on the bar keeps it open; the pin state is saved.
- Never hides while a placement ghost is active or while a text field has focus. The speed buttons and the Visit button
  stay put.
## Acceptance
`tests/test_bar.gd`: hides after the delay with the mouse away, shows near the edge, B toggles, pinned never hides,
placing never hides. Shots: shown and hidden states. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
