---
id: PRG1
title: Builder XP and specialty levels
status: todo
deps: CH2
area: progression
parent: 0.5
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → Roadmap 0.5. Builders earn XP from every finished job (more for jobs in their specialty). A
specialty has levels 1–3: speed ×1.5 / ×2 / ×3 on that specialty's buildings (today a specialist is a flat 2×). Levels up
automatically at XP thresholds (one table), with a small "Bo is now a Lv 2 Water specialist" toast and `Motion` on the shed.
- The shed card shows the builder's level, XP bar and current speed. The second-specialty rule (park level 6) stays.
- Saved; existing saves load with level 1 and 0 XP.
## Acceptance
`tests/test_builder_xp.gd`: XP per job; level thresholds; speed per level; the second specialty levels separately. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
