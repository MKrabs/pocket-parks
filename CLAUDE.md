# project-szm: Pocket Parks

Isometric park builder in Godot 4.6 (GDScript). You build and run a park; themes (zoo,
festival, ...) are data packs. Conflict is implicit: you visit parks and send in guests and hidden bad actors. **The game definition
lives in `docs/design/game.md`. Read it before any gameplay ticket.** Current phase:
prototype 3, visiting and sending people (bot parks stand in for friends). Everything that doc marks
Parked stays parked.

## Roles
- **Owner (human):** decides direction, judges look and feel, approves merges.
- **Claude (main session):** orchestrator. Turns goals into tickets, runs the factory,
  reviews what comes back (it reads the diff, runs `./gd check` and looks at `./gd shot`),
  and keeps this file current. It doesn't silently assume: it picks a sensible default
  and writes the open question into the ticket.
- **Workers** (`.claude/agents/worker.md`): one ticket each, in their own worktree. They
  hand back with evidence. They never make product decisions.

## How work flows
- `tickets/<ID>.md` = one ticket. Header: status, deps, area, parent, human.
- `./factory` claims every READY ticket (todo + deps done + not human), up to the WIP
  limit of 3. It runs one `worker` per ticket in `.claude/worktrees/<ID>` on branch
  `t/<ID>`, headless, capped per run (`FACTORY_BUDGET_USD`, default $3).
- `./wall` = tmux view: board on the left, live worker panes on the right.
- `./tix board`, `./tix approve ID` (merges the branch), `./tix reject ID "why"`,
  `./tix unblock ID "answer"`, `./tix done ID` (for human-only tickets).
- Logs: `tickets/log.txt` (state changes, cost per run), `logs/<ID>-<time>.jsonl`.

## Running and checking
```bash
./gd check          # headless: every tests/test_*.gd must pass. Run it before every commit.
./gd shot out.png   # offscreen render of the main scene (xvfb), then look at the PNG
./gd run            # play it in a window (humans)
./gd edit           # Godot editor (humans)
./gd export         # builds/PocketParks-macos.zip (universal, ad-hoc signed) + builds/PocketParks.x86_64
python3 test_tix.py # self-check for the ticket queue
```
Godot binary: `$GODOT`, default `~/Downloads/Godot_v4.6.2-stable_linux.x86_64`.

## Rules
- **Verify before you claim.** "Done" means `./gd check` passes and you looked at a
  `./gd shot` for anything visual. Report the commands you ran and what came back. Also
  name what you could *not* verify (e.g. mouse feel can't be screenshotted).
- **Smallest change that meets the acceptance criteria.** No abstraction with one
  implementation, no scaffolding for later tickets, no addons or dependencies.
- **Product decisions belong to the owner.** Implementation details are yours: guess,
  and name the guess in the handoff.
- **Parked means don't design it or scaffold for it.** See `docs/design/game.md` → Parked.
- New ideas become one-line tickets right away, so nothing lives only in chat.

## Godot conventions
- GDScript, typed (`var x: int`). Tabs for indentation.
- `main.tscn` is the only scene file. Build node trees in code (`add_child(...)` in
  `main.gd` or in the scripts it creates). Text-merging `.tscn` files across worktrees
  goes badly.
- Scripts live in `scripts/`, one concept per file, with `class_name` when another
  file uses it. Keep pure logic (grid math, rules, the simulation) free of nodes so tests can reach it.
- Tests: `tests/test_<thing>.gd`, extending `SceneTree`. Copy the `ok()`/`done()` pattern
  from `tests/test_palette.gd`. Every non-trivial piece of logic gets at least one check.
- Draw with `_draw()` and polygons (no image assets in this phase). The one font is Nunito (`assets/fonts/`, OFL): use `Palette.FONT` / `Palette.FONT_BOLD`, never `ThemeDB.fallback_font`.

## Look
- **Colours:** natural, slightly pastel, only from `scripts/palette.gd` (no Color
  literals elsewhere). Extruded shapes: top face = base colour, sides use
  `Palette.shade(c, 0.12 / 0.22)`.
- **Forms:** semi-rounded squircles (superellipse, n ≈ 4), never sharp boxes or full
  circles. Soft, low-contrast outlines if any.
- Isometric 2:1 tiles. Background `Palette.CREAM`.
