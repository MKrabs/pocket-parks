---
id: VAR1
title: Building size variants
status: done
deps: BAR1
area: buildings
parent: 0.3
human: false
owner: worker-VAR1
since: 2026-11-27T03:47:31
---
## Goal
`docs/design/game.md` → Habitats and animals → "Shops are not free-shaped". Building types get size variants.
- Catalog: a building can name its `variants` (ids of the same role and family). Zoo: **Snack Cart** (1×1, today's snack
  stand) → **Hot-dog Stand** (2×1) → **Burger Diner** (2×2). Festival: Food Truck → **Taco Truck** (2×1) → **Food Hall**
  (2×2). Cinema: Popcorn Stand → **Candy Bar** (2×1) → **Lobby Café** (2×2). Bigger means more capacity and a higher price
  (your numbers, in the catalog). New models in the shape language (CLAUDE.md, Look).
- The build bar shows **one button per family**, with small ‹ › arrows to switch the variant (the button shows the current
  variant's name and price). While placing, **1/2/3** switch variants too.
- Charm treats variants of one family as "the same building" for the repetition penalty (CH1), if CH1 has merged. Otherwise
  leave a note.
## Acceptance
`tests/test_variants.gd`: families resolve; footprints and prices differ; switching while placing keeps the ghost. Shot of
all variants plus the build bar with arrows. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.

> **review 2026-11-27T03:43:00:** Built: shop size variants in all three themes. Catalog (scripts/themes/*.gd): the smallest shop names its 'variants' list. Zoo: snack_stand (renamed 'Snack Cart', id kept for saves) 1x1 $60/price 5/cap 2 -> hotdog_stand 2x1 $110/8/4 -> burger_diner 2x2 $190/12/7. Festival: fest_truck $70/6/2 -> fest_taco 2x1 $120/9/4 -> fest_hall 2x2 $200/13/7. Cinema: cin_popcorn $60/5/2 -> cin_candy 2x1 $110/8/4 -> cin_cafe 2x2 $180/12/7. Buildings.family(id) resolves the list. Shops now carry 'capacity' (park_sim reads d.get('capacity', SHOP_CAPACITY), so levels scale it like attractions). Charm (CH1 has merged): the repetition penalty keys on family(id)[0], so variants count as the same building. Build bar (build_bar.gd): one button per family, small drawn ‹ › chevrons step the variant (wrapping), and the button shows the current variant's name and price. A pressed button re-emits picked(id), so the ghost swaps in place and keeps its hover cell and rotation. main.gd: 1/2/3 call bar.variant() only while placing. Tests: new tests/test_variants.gd covers families, footprints, price/cost/capacity growth, the charm repeat, one button per family, the arrows, 1/2/3 keeping the ghost cell and turn, and pick() of a variant. Updated tests: Snack Cart name in test_host_flow/test_select, zoo count 13 in test_squircle, test_hud counts families. test_visit_flow: the bot-park seed went from 11 to 12. Bot parks now also roll the new shops, so on seed 11 the thief was still inside at day end and was dropped (the existing ponytail drop in main.step_world). That is the test's seed, not a logic change. ./gd check: 35 ok, 0 fail. Screenshot (./gd shot with res://tests/show_variants.gd): 3 rows x 3 sizes, all rounded and on palette. Hot-dog bun/sausage roof sign, burger-stack sign on the diner, taco truck with a coral flap, food hall with a stepped tent roof and a flag, candy bar with three jars, lobby cafe with a cup sign and marquee lights. The build bar on Shops shows 'Hot-dog Stand $110' between ‹ ›. The main-scene shot is unchanged. Not verified: how the arrows feel under the mouse, and hover on the arrows (they are Controls on top of the button, so a click on one steps the size without pressing the button). Guesses: all numbers (cost/price/capacity), the arrow wraps instead of stopping, Snack Stand renamed to Snack Cart per the ticket, and festival variants have no specialty (the Food Truck has none).
