---
id: PRG1
title: Builder XP and specialty levels
status: done
deps: CH2
area: progression
parent: 0.5
human: false
owner: worker-PRG1
since: 2026-11-27T04:17:11
---
## Goal
`docs/design/game.md` → Roadmap 0.5. Builders earn XP from every finished job (more for jobs in their specialty). A
specialty has levels 1–3: speed ×1.5 / ×2 / ×3 on that specialty's buildings (today a specialist is a flat 2×). Levels up
automatically at XP thresholds (one table), with a small "Bo is now a Lv 2 Water specialist" toast and `Motion` on the shed.
- The shed card shows the builder's level, XP bar and current speed. The second-specialty rule (park level 6) stays.
- Saved; existing saves load with level 1 and 0 XP.
## Acceptance
`tests/test_builder_xp.gd`: XP per job; level thresholds; speed per level; the second specialty levels separately. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.

> **review 2026-11-27T03:59:16:** Built specialty XP + levels. Specialties.gd: XP_JOB=1 (each specialty the builder has, per finished job outside it), XP_SPEC=3 (the job's own specialty), LEVEL_XP=[0,10,30], LEVEL_SPEED=[1.5,2,3]; level()/progress()/award(); speed() now float and takes the xp dict. ParkMap.spec_xp (shed -> {spec: xp}), erased on demolish, kept when a specialty is dropped and re-picked. ParkSim awards on job finish (builds and upgrades) and queues sim.leveled; main.advance toasts 'Bo is now a Lv 2 Carpenter specialist' (new 'levelup' toast kind, butter colour, chevron glyph in PinView) and Motion.bounce on the shed. Shed card: one line per specialty 'Carpenter Lv 2 · ×2 · 12/30 XP' plus a thin XP bar drawn inside each picked specialty button. Saved under map.spec_xp; old saves load with {} = Lv 1, 0 XP. Second-specialty rule unchanged. Tests: new tests/test_builder_xp.gd (thresholds, progress, speed per level, XP per job, second specialty levels separately, sim award + level-up report, card line, save round-trip, old save, demolish); test_specialties updated for 1.5x (snack stand 134 ticks, was 100). ./gd check: all ok (test_presence timed out once on the first run, passed on both reruns, so it looks flaky and unrelated). Screenshot (tests/show_builder_xp.gd): toast top-right, shed card shows Carpenter Lv 2 · ×2 · 12/30 XP with the bar on the button. Couldn't verify how the shed bounce or the toast timing feel. GUESSES: (1) XP sits on the specialty, not the builder, so a generalist earns nothing; (2) specialist-only buildings get the level speed too (Lv1 1.5x, was 1x); (3) the XP numbers and thresholds; (4) dropping a specialty keeps its XP. The docs/design/game.md line 84 still says 'no XP or training for now'. I left it alone for the owner to update.
