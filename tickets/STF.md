---
id: STF
title: Staff levels for janitors and guards
status: todo
deps: 
area: staff
parent: M3
human: false
owner: 
since: 
---
## Goal
Owner: "guards and janitors should have levels too."
- Janitors and guards have level 1–3. Upgrade from the person card (staff card) for money; wages rise with level.
- Janitor: faster walking and cleaning, a larger area to look for litter.
- Guard: faster, a larger sight radius for witnessing crimes (3 → 4 → 5 tiles), better at catching (catch radius up), and
  from Lv 3 a small chance per second to notice a *hidden* actor who has already committed a crime nearby (it becomes wanted).
  Guards still never arrest anyone without a crime.
- Staff wear a small level mark: 1–3 thin stripes on their cap (not dots). The card shows the level and the next level's effect.
- All numbers in one const table in `park_sim.gd`.
## Acceptance
`tests/test_staff_levels.gd`: costs and wages; a Lv 3 guard witnesses from further away than Lv 1 (seeded); a Lv 3 janitor
cleans faster; guards still never arrest honest guests or 0-crime actors. Shot of a staff card. `./gd check` ok.
