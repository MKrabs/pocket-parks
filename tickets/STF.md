---
id: STF
title: Staff levels for janitors and guards
status: done
deps: 
area: staff
parent: M3
human: false
owner: worker-STF
since: 2026-11-26T23:18:53
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

> **review 2026-11-26T23:14:09:** Built staff levels 1-3. All numbers are in ParkSim.STAFF (park_sim.gd): hire price plus a per-level table with cost, wage, speed and either clean/reach (janitor) or sight/catch/spot (guard). Removed STAFF_SPEED, GUARD_SPEED and GUARD_SIGHT. Staff dicts now carry a level, which survives new_day. New ParkSim API: stat(s, key), staff_upgrade_cost(i) (returns -1 at max) and upgrade_staff(i). Janitor: speed 0.15/0.2/0.25, spends 15/9/5 ticks cleaning a spot (cleaning used to be instant), only targets litter within 5/8/12 grid tiles and wanders to a random path when all litter is out of reach. Guard: speed 0.3/0.36/0.42, sight 3/4/5, catch 1.0/1.3/1.6. From Lv 3 it has a 0.1/s chance to mark a not-yet-wanted actor with crimes>0 within sight as wanted. Nobody with 0 crimes can become wanted. Staff card (info_card.gd) shows 'Guard · Lv 2', what the current level does, the wage, the next level's effect and wage, and an Upgrade button (shows 'need $X more' / max level). main.gd sends the card's upgrade to sim.upgrade_staff when a staff member is on the card. walker_view.gd draws 1-3 thin upright squircle stripes on the cap (cap colour shaded 0.45). Tests: tests/test_staff_levels.gd covers costs, the top level, too-poor upgrades, wages rising and the day's wage total per level, level kept overnight, a striker 4.5 tiles away seen by a Lv 3 guard but not a Lv 1 one (seeded), Lv 3 spotting a hidden actor that Lv 2 never spots, a Lv 3 janitor leaving less litter than a Lv 1 one in 100 ticks, and a full day of Lv 3 guards kept on top of honest guests and actors where nobody with 0 crimes is ever wanted and there are no wrongful or zero-amount arrests. ./gd check: all 20 ok. Shot: tests/show_staff_card.gd, zoomed in, shows the Lv 2 guard card on the right, and on the path a Lv 2 guard with 2 stripes and a Lv 1 guard with 1 stripe (an earlier frame showed the Lv 3 janitor with 3 stripes at the gate). Not verified: clicking the Upgrade button by mouse, and how the stripes read at normal zoom (barely visible there). Guesses: all numbers (costs 60/120, wages, clean ticks, reach, catch radii, 0.1/s spot chance), 'nearby' meaning within sight radius, upright rather than horizontal stripes, and that spotting doesn't set the crime event's witnessed flag.
