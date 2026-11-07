#!/usr/bin/env bash
# Usage: wallpaper.sh /path/to/image   -> set and remember
#        wallpaper.sh --restore        -> re-apply remembered (or solid color)
state="${XDG_STATE_HOME:-$HOME/.local/state}/niri-wallpaper"
if [[ "$1" == "--restore" ]]; then
    img="$(cat "$state" 2>/dev/null)"
    if [[ -f "$img" ]]; then awww img "$img" --transition-type none
    else awww clear 11111b; fi
    exit 0
fi
[[ -f "$1" ]] || { echo "no such file: $1" >&2; exit 1; }
mkdir -p "$(dirname "$state")"
realpath "$1" > "$state"
awww img "$1" --transition-type grow --transition-duration 1
