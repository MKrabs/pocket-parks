---
id: MAP
title: Expandable map: buy plots
status: done
deps: 
area: world
parent: M3
human: false
owner: worker-MAP
since: 2026-11-26T23:05:46
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

> **review 2026-11-26T23:04:14:** Built: IsoGrid.SIZE is now 20×20, laid out as 5×5 plots of 4×4 cells. You start with the 3×3 plots in the centre (cells 4..15, 12×12), and the 16 plots around them are for sale. Files: scripts/park_map.gd adds owned/bought/start_small/plot_of/owns/buyable/plot_price/plot_needs/can_buy/buy/on_unowned, and fits() now refuses unowned cells, so can_place and sim.build do too. scripts/park_level.gd: UNLOCKS plots 1/2/3/4/5 at levels 2/4/6/8/10 (BASE 0), plus a describe line. scripts/grid_view.gd: unowned tiles are GRASS_PALE with no checker, and buyable plots get a small post with a butter $ board. scripts/info_card.gd: show_plot card with size, price, owned vs cap, and a Buy button that shows the reason when disabled. scripts/zoo_view.gd: the ghost label says 'Buy this land first'. main.gd: the seed moved into the centre, clicking a buyable plot in Select mode opens the card, the buy action pays from sim money, cam zoom went from 0.92 to 0.74, and grid.map switches to null while visiting. scripts/palette.gd adds GRASS_PALE. Tests: new tests/test_plots.gd (unowned refused, adjacent-only including diagonal corners, price rises, level cap, money). I updated the cell coords in test_select, test_iso_grid, test_park_map and test_park_level, and in show_hud, show_construction and show_specialty_card, for the moved seed and 20×20. ./gd check: all ok. Shot shots/MAP.png (./gd shot shots/MAP.png 2 res://tests/show_plots.gd) shows the green owned centre with the seeded zoo, muted for-sale land around it with $ signs on the 12 edge-adjacent plots, and the Land for sale card open (4×4 plot · $200, Buy · $200). Guesses: price = 200 × (plots bought + 1). Corner plots only become buyable after a neighbour plot is bought. Bot parks use the full 20×20 (empty owned = all land is yours). Not verified: real mouse clicking on a plot (only select_at is tested), and the plot on the card isn't highlighted on the map.
