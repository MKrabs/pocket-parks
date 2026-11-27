---
id: BAR1
title: Auto-hiding bottom bar
status: done
deps: 
area: ui
parent: 0.3
human: false
owner: worker-BAR1
since: 2026-11-27T03:33:04
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

> **review 2026-11-27T03:23:50:** Built: the build bar auto-hides. Logic is in scripts/build_bar.gd: step() and toggle(). The BuildBar CanvasLayer's offset:y slides with the new Motion.glide (BAR_TIME 0.25 s, cubic ease out). It goes down to a rounded STONE tab with a chevron (up when hidden, down when shown; clicking it toggles), after HIDE_AFTER=1.0 s with the mouse away from the bar. It comes back up when the mouse enters the bottom NEAR=70 px (which covers the handle) or on B (main.gd). A pin button (drawn push pin) sits at the end of the tab row. Its state is saved as an extra 'bar_pinned' key in the park save (main.save/_ready), so old saves load fine. The bar never hides while an item is picked (placing) or a LineEdit has focus. If it's hidden when placing starts, it shows. The speed and Visit buttons are on the HUD layer and don't move. Files: scripts/build_bar.gd, scripts/motion.gd, main.gd, tests/test_bar.gd, CHANGELOG.md. ./gd check: all ok, including the new test_bar: hides after the delay, slides to the handle offset, shows near the edge, B shows and hides, pinned never hides, placing never hides, pin is saved. Shots: shots/BAR1-shown.png (1 s, full bar with the pin and the down-chevron tab above it) and shots/BAR1-hidden.png (3 s, only the small tab at the bottom centre, speed and Visit unchanged). Not verified: how the slide feels with a real mouse, and loading the pin back from a save (only writing it is tested). Guesses: (1) A bar opened with B stays up until the mouse has visited it and left, otherwise B would be undone after 1 s. Hiding with B while the mouse is near the edge stays hidden until the mouse leaves and comes back, because showing triggers on entering the zone. (2) B does nothing to a pinned or busy bar (it doesn't unpin). (3) The whole bottom strip counts as near, including above the speed and Visit buttons. (4) Note for other tickets: plain ./gd shot captures at 2 s or later will now show the bar hidden unless it's pinned.
