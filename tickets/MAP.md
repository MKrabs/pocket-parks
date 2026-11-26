---
id: MAP
title: Expandable map: buy plots
status: todo
deps: 
area: world
parent: M3
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → Roadmap: start smaller and buy land, "but not by too much".
- The world becomes 20×20 (`IsoGrid.SIZE`). Land is in **plots**; you own a starting area of about 12×12 that covers the
  seeded start park (move the seed if needed). The rest is split into plots of about 4×4 cells.
- Unowned land is drawn muted (paler, desaturated grass, no checker) with a small "for sale" sign on each plot next to
  your land. Clicking a buyable plot opens a card: size, price (rising with each plot bought), and Buy. Only plots
  touching your land can be bought.
- Park level gates how many plots you can own: add `plots` to `ParkLevel.UNLOCKS` (e.g. +1 at levels 2, 4, 6, 8, 10).
- Building, paths and the sim respect ownership (`can_place` refuses unowned cells, with the reason in the ghost).
- Bot parks stay 16×16 inside the 20×20 grid, or use the full size. Your call; keep the camera framing nice.
## Acceptance
`tests/test_plots.gd`: you can't place on unowned land; you can buy only adjacent plots; the price rises; the cap follows the
park level. Shot `shots/MAP.png` showing owned land, for-sale plots and an open plot card. `./gd check` ok.
