---
id: TH1
title: Amusement park theme
status: todo
deps: HAB1
area: world
parent: 0.6
human: false
owner: 
since: 
---
## Goal
A theme pack in the shape language (CLAUDE.md, Look), every role covered: rollercoasters: a Coaster (3×3 loop track of thin rails with a small car, specialist-only: new **Rides** specialty), Teacups (2×2), Ferris Wheel (2×2, a thin ring with gondolas), a Churro Cart and its variants, balloons and bunting as decor, a ticket arch entrance. Bot parks support it, the Visit picker offers it, and T cycles to it. Variants (VAR1) and unlocks (PRG2) apply.
## Acceptance
`tests/test_themes.gd` covers it. Shot: every building, plus a bot park. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
> **note:** started before PRG2 (unlocks). Leave gating to PRG2; just add the content.
