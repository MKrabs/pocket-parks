---
id: POL1
title: Visual and UI polish from reviews
status: todo
deps: PRG2
area: ui
parent: 0.5
human: false
owner: 
since: 
---
## Goal
Fix the rough edges collected during reviews (each was seen in a screenshot):
1. **The info/habitat card grows under the money chip** when it has many rows. Cap its height between the top-right column
   (`hud.right_bottom()`) and the Visit button, and make the body scroll.
2. **The bar's pin icon reads as a magnifying glass.** Draw a clear pushpin.
3. **The 2×2 shops look alike across themes** (zoo Burger Diner, cinema Lobby Café, conference Pavilion, festival halls). Give
   each a distinct silhouette in its theme's language.
4. **The net dome covers the empty corner of L-shaped habitats.** Draw one dome per rectangle of the habitat (a few domes
   joined), or follow the outline.
5. **Owned and for-sale land look too alike.** More contrast, still pastel.
6. **Player characters are barely bigger than guests.** Make them clearly bigger and give them a subtle outline in their colour.
7. **The "lost connection" toast borrows the wrecked hammer glyph.** Give it its own glyph (an unplugged cable or a cloud with a gap).
8. **The plot card doesn't show which plot it means.** Highlight the plot on the map while its card is open.
## Acceptance
A before/after shot per item where visual. `./gd check` ok. Add a Fixed/Changed line to CHANGELOG.md.
9. **Show scripts that render the build bar** (e.g. `tests/show_unlocks.gd`) now show only the tucked handle, because the bar auto-hides with no mouse nearby. Pin or open the bar in show scripts.
