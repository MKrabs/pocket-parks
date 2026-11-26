---
id: CIN
title: Cinema theme
status: done
deps: 
area: world
parent: M3
human: false
owner: worker-CIN
since: 2026-11-26T23:02:11
---
## Goal
A third theme pack: **cinema** (`scripts/themes/cinema.gd`), same squircle and palette language, every role covered.
- Ticket Booth (entrance, 1×1), Red Carpet (path: a muted CLAY runner on STONE), Screen Room (attraction 2×2: a
  rounded box with a big pale screen face), **Big Screen** (attraction 3×3, specialist-only), Popcorn Stand (shop: BUTTER
  popcorn cup on top), Poster Wall (decor), Potted Palm (decor), and a cinema Builder Shed.
- Themes bring their own specialties: add **Projection** (a projector glyph) available only in the cinema theme. The
  Big Screen needs it; the Screen Room is "faster" with it. The shed card only offers specialties relevant to the
  active theme plus the shared ones (Landscaper, Water, Carpenter).
- `T` cycles zoo → festival → cinema. `BotPark.generate` supports cinema, and the Visit offers can include cinema parks.
## Acceptance
`tests/test_themes.gd` covers 3 themes (one entrance each, all roles present, unique ids). Specialty tests cover Projection.
Shot `shots/CIN.png`: all cinema buildings (show script), plus a cinema bot park. `./gd check` ok.

> **review 2026-11-26T23:00:39:** Built: scripts/themes/cinema.gd (cin_booth entrance arch in STONE/CLAY with a BUTTER marquee, cin_carpet CLAY runner on STONE, cin_room 2x2 CLAY hall with a pale CLOUD screen on its +x face (Projection faster), cin_big 3x3 open-air screen with a framed CLOUD screen at the back, rising CORAL seat rows and a projector (Projection only), cin_popcorn CORAL stand with a CLOUD cup of BUTTER popcorn, cin_poster, cin_palm (Landscaper faster), cin_shed with a CORAL roof). The theme is registered in buildings.gd. specialties.gd: a new 'projection' specialty (glyph 'P', BUTTER); aviary and heavy are tagged theme 'zoo'; new Specialties.for_theme(). park_map.spec_choices now offers only the active theme's specialties plus the shared ones (a specialty already picked stays visible after a theme swap). main.gd: T cycles through Buildings.themes() in order zoo, festival, cinema. visit.gd: the 3 offers are now one park of each theme, in shuffled order (before, zoo and festival alternated). Tests: test_themes checks the 3 themes and their order; test_specialties covers Projection (only in cinema, Big Screen specialist-only, Screen Room 2x, festival can't pick Aviary); test_bot_park covers cinema; test_visit_flow checks one offer per theme. New tests/show_cinema.gd. ./gd check: all ok. Shot shots/CIN.png (./gd shot shots/CIN.png 1 res://tests/show_cinema.gd) shows a row of all 8 cinema buildings and a large cinema bot park below it, all readable and pastel. Guesses: the 'projector glyph' is the letter P, because every existing glyph is a letter; the shed theme is Buildings.active (the build theme), since the park has no theme of its own; the colour and appeal/cost numbers are mine. Not verified: the shed card's look in the cinema theme (not screenshotted) and the feel of pressing T in game.
