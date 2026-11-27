---
id: POL2
title: Simulation edge cases from reviews
status: todo
deps: PRG2
area: sim
parent: 0.5
human: false
owner: 
since: 
---
## Goal
Fix the known simplifications (they're marked `ponytail:` in the code):
1. **People still inside a park when its day ends disappear without settling** (`park_sim.gd` new_day). Settle them as if they
   left: guest shares and carried loot go to their senders.
2. **Builders walk in a straight line across grass and buildings.** Path them along paths where possible (fall back to straight
   lines on open ground).
3. **The janitor picks the nearest litter by grid distance, not by walking distance.** Use path distance.
4. **The fence category mapping:** the design says Wall = highlands, but a plain wood Fence also offers the highland animals.
   Keep Fence offering a small "starter" set (one animal from each category that suits open ground: capybara, red panda,
   klipspringer), and the specialist fences the full category. Update the habitat card and tests.
## Acceptance
A test per item. `./gd check` ok. Add lines to CHANGELOG.md.
