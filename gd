#!/usr/bin/env bash
# gd: the one way agents and humans drive Godot here.
#   ./gd check              import + run every tests/test_*.gd headless; non-zero on any failure
#   ./gd shot [out] [sec] [script]
#                           render offscreen (xvfb), save the frame after `sec` seconds (default 1)
#                           to out (default shots/main.png). Renders the main scene, or with `script`
#                           a SceneTree script (e.g. res://tests/show_buildings.gd) that builds its own view
#   ./gd run                open the game in a window (humans)
#   ./gd edit               open the editor (humans)
set -uo pipefail
cd "$(dirname "$0")"
G="${GODOT:-$HOME/Downloads/Godot_v4.6.2-stable_linux.x86_64}"
[ -x "$G" ] || { echo "gd: Godot not found at $G (set GODOT=...)" >&2; exit 3; }
fail_on_errors() { ! grep -E 'SCRIPT ERROR|Parse Error|Failed to load script|FAIL' ; }

case "${1:-}" in
  check)
    timeout 120 "$G" --headless --path . --import >/dev/null 2>&1
    rc=0
    for t in tests/test_*.gd; do
      out="$(timeout 60 "$G" --headless --path . -s "res://$t" 2>&1)"; trc=$?
      if [ $trc -ne 0 ] || ! fail_on_errors <<<"$out" >/dev/null; then
        echo "FAIL $t (rc=$trc)"; grep -E 'ERROR|FAIL|Error' <<<"$out" | head -20; rc=1
      else echo "ok   $t"; fi
    done
    exit $rc ;;
  shot)
    out="${2:-shots/main.png}"; frames=$(( ${3:-1} * 30 ))
    tmp="$(mktemp -d)"; mkdir -p "$(dirname "$out")"
    scene=(); [ -n "${4:-}" ] && scene=(-s "$4")
    timeout 120 "$G" --headless --path . --import >/dev/null 2>&1
    timeout 120 xvfb-run -a -s "-screen 0 1600x900x24" "$G" --path . --rendering-driver opengl3 "${scene[@]}" \
      --resolution 1280x720 --fixed-fps 30 --write-movie "$tmp/f.png" --quit-after "$frames" \
      >"$tmp/log" 2>&1
    last="$(ls "$tmp"/f*.png 2>/dev/null | tail -1)"
    if [ -z "$last" ] || ! fail_on_errors <"$tmp/log" >/dev/null; then
      echo "gd shot failed:"; grep -E 'ERROR|Error' "$tmp/log" | head -20; rm -rf "$tmp"; exit 1
    fi
    mv "$last" "$out"; rm -rf "$tmp"; echo "$out" ;;
  run)  exec "$G" --path . ;;
  edit) exec "$G" --path . -e ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
