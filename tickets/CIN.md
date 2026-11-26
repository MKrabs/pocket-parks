---
id: CIN
title: Cinema theme
status: doing
deps: 
area: world
parent: M3
human: false
owner: worker-CIN
since: 2026-11-26T22:57:57
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
