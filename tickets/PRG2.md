---
id: PRG2
title: Unlocks by park level: animals, fences, variants
status: todo
deps: HAB3, PRG1, VAR1
area: progression
parent: 0.5
human: false
owner: 
since: 
---
## Goal
Extend `ParkLevel.UNLOCKS`, so the park level gates the new content: fence types (Fence at 1, Glass at 2, Wall at 3, Net at 4),
animals (one per category at the start, the rest spread over levels 2–8), variants (the 2×1 at level 2, the 2×2 at level 4).
- Locked items show in the bar or picker greyed, with "Unlocks at park level N" (they don't disappear), and the level-up card
  lists what each level unlocked.
## Acceptance
`tests/test_unlocks.gd`: every gate applies and opens at its level. Shot of the level-up card listing new content. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
