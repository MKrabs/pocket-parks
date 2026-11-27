---
id: SOC4
title: Chat: speech bubbles and a log
status: done
deps: SOC2
area: social
parent: M5
human: false
owner: worker-SOC4
since: 2026-11-27T01:14:41
---
## Goal
`docs/design/game.md` → M5 chat. You talk **through your character**.
- Press **Enter** (or a small chat button) to type a line (max 80 chars). It shows as a rounded speech bubble over your
  character for ~5 s (with `Motion` pop and vanish), and in a small fading chat log (bottom-left, above the speed buttons,
  last 6 lines, names in their colour).
- Everyone in that park sees it: the host relays a visitor's line to all visitors and shows it in its own park. At home, your
  own lines appear over your own character.
- Typing must not trigger hotkeys (T, R, F9, WASD...).
## Acceptance
In-process test: a client's line reaches the host and the other client; the log keeps the last 6. Shot with two bubbles and the
log. `./gd check` ok.

> **review 2026-11-27T01:12:01:** Chat built. Net (scripts/net.gd): say(text) cuts the line to 80 chars. A visitor sends {t:say}; the host relays {t:say,name,color,text} to every visitor (the speaker too) and emits said(name,color,text,home) in its own park. At home, say() shows the line locally and sends it to our visitors. ChatLog (scripts/chat_log.gd, new CanvasLayer): bottom-left above the speed buttons, keeps the last 6 lines, names in their colour (shaded 0.35 so they read), each row fades after 10 s, all rows come back while typing. Enter opens a LineEdit (max 80), Enter sends, Esc cancels. WalkerView.say(): a squircle speech bubble over the speaker for 5 s, Motion.pop in and Motion.vanish out; a newer line replaces it. main.gd: Enter hotkey, say()/_hear(), lines from our own park are ignored while we're away. In a bot park our line just shows locally. IsoCamera skips WASD panning while a LineEdit has focus. The other hotkeys are already safe because the focused LineEdit eats the keys. Tests: tests/test_chat.gd (host + 2 clients over ENet: a client line reaches the host, the other client and the speaker, it's cut to 80, empty lines and lines sent before hello are refused, a host line reaches visitors; the log keeps the last 6; pushed Enter/T/F/Enter keys type 'tf' and the theme and follow stay unchanged). ./gd check: all ok. Shot: tests/show_chat.gd -> shots/SOC4.png shows two characters with their bubbles (one wraps to 2 lines) and the 4-line log above the speed buttons. Not verified: how the fade and pop feel over time, and a real two-machine chat. Guesses: no separate chat button (Enter only; say if you want one), 10 s log fade, bubble width 130 world px, a visitor's colour comes from its host avatar.
