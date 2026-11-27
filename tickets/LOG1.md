---
id: LOG1
title: Version label and What's new card
status: todo
deps: BAR1
area: ui
parent: 0.3
human: false
owner: 
since: 
---
## Goal
`docs/design/game.md` → "Versions and changelog".
- A small version label ("v0.3.0") in the HUD's bottom-left, above the speed buttons, low contrast. From
  `ProjectSettings.get_setting("application/config/version")`.
- A **What's new** card (rounded, centred, scrollable, `Motion` pop) showing the newest released section of
  `res://CHANGELOG.md` (the first `## [x.y.z]` after Unreleased), rendered as simple rich text: headings and bullets,
  **bold** kept. It opens automatically once after the version changes (remember the last seen version in the save), and
  any time from the version label.
- CHANGELOG.md is already included in exports (`export_presets.cfg` include_filter). Make sure it's readable in an exported build.
## Acceptance
`tests/test_changelog.gd`: the parser picks the newest released section (not Unreleased); the card shows once per new
version. Shot of the card. `./gd check` ok. Add your player-facing change under `## [Unreleased]` in CHANGELOG.md.
