---
id: HAB3
title: Habitat decor items
status: todo
deps: HAB2
area: zoo
parent: 0.4
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Habitats and animals", step 4. From the habitat card: click an item, then click inside the habitat
to place it (the same ghost as buildings, limited to that habitat's cells; R rotates; right-click cancels).
- Items: **Pool** (1×1 and 2×2, water), **Rocks** (1×1 and 2×1, rocks), **Tree** (1×1, trees), **Shelter** (1×1), **Waterfall**
  (2×1, water + rocks, a highlight stream). Each counts toward the needs shares (HAB2) and adds charm to nearby paths (CH1).
- Items can be selected and removed (refund half), and they're saved and replicated.
## Acceptance
`tests/test_habitat_items.gd`: placing is limited to the habitat; shares update comfort; remove refunds. Shot: a decorated
habitat with happy animals. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
