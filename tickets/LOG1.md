---
id: LOG1
title: Version label and What's new card
status: done
deps: BAR1
area: ui
parent: 0.3
human: false
owner: worker-LOG1
since: 2026-11-27T03:47:31
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

> **review 2026-11-27T03:38:26:** Built: scripts/changelog.gd (Changelog.latest picks the first ## [x.y.z] section after Unreleased -> {version,title,body}; to_bbcode turns ### headings, '- ' bullets with wrapped lines joined, and **bold** into BBCode and escapes stray [; should_show(seen, current, fresh)). hud.gd: a low-contrast flat 'v<config/version>' label above the speed buttons, which opens open_whats_new(): a rounded CREAM card, centred, Motion.pop, title 'What's new in x.y.z', the section title under it, a scrollable RichTextLabel (Nunito regular/bold, palette scrollbar) and a 'Nice' button that vanishes it. main.gd: seen_version is read from and written to the park save ('seen_version'); on start the card opens deferred if seen != current, then seen = current. tests/test_changelog.gd covers the parser (Unreleased skipped, only that section, bold/bullets/escaping, the real res://CHANGELOG.md parses) and show-once logic. tests/show_whats_new.gd is for the shot. CHANGELOG line added under Unreleased/Added. ./gd check: all 35 ok. Shot shots/LOG1.png: card centred over the park showing 0.2.0 'Visit in person', bold lead-ins kept, soft scrollbar, 'v0.2.0' faint in the bottom-left above the speed buttons, nothing overlapping. Export: ./gd export ok, and the Linux binary's embedded pack contains the CHANGELOG text (grep). I didn't launch the exported build to see the card. Guesses: (1) no card on a brand-new start (no save), since there's nothing new and the identity card opens then; (2) if the identity card opens (save without a nick), it takes priority and What's new waits until the next start; (3) seen_version is written on the next save (close/identity), not right away, so a crash before saving shows the card again. Note: project version is still 0.2.0, so the label reads v0.2.0 until the release bump.
