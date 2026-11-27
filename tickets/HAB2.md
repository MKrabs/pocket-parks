---
id: HAB2
title: Animals with needs, the habitat card
status: todo
deps: HAB1
area: zoo
parent: 0.4
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Habitats and animals", step 3, and the animals table (3 categories × 3; the fence type decides the
category).
- 9 animals drawn in the shape language (small, readable, distinct silhouettes and palette colours: otter, capybara,
  platypus, red panda, takin, klipspringer, shoebill, puffin, hornbill). Each animal walks, rests and swims (where there's
  water) inside its habitat, 2–4 per habitat.
- **Needs** per animal (one const table): min cells, water share, rocks share, trees share, shelter yes/no. **Comfort** 0–100 from
  how well the habitat meets them. Happy animals are out and active, and the habitat's appeal to guests scales with comfort.
  Unhappy animals hide or pace, and appeal drops.
- The **habitat card** (the right-side card when you select a habitat): an animal picker with portraits, only the
  fence type's category; a needs checklist with ✓/✗ and how much is missing ("needs 20% more water"); a comfort bar; buy
  the animals (a price per animal).
- Replicated in live visits; saved.
## Acceptance
`tests/test_animals.gd`: needs scoring; comfort changes with habitat contents; appeal follows comfort; the picker only offers the
category's animals. Shots: all 9 animals; a habitat card with a partly met checklist. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
