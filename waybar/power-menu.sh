#!/usr/bin/env bash
# Power menu via vicinae's dmenu mode.
choice=$(printf '󰌾  Lock\n󰍃  Log out\n󰤄  Suspend\n󰜉  Reboot\n󰐥  Shut down\n' | vicinae dmenu -p "Power")
case "$choice" in
    *Lock)      swaylock -f ;;
    *"Log out") niri msg action quit --skip-confirmation ;;
    *Suspend)   systemctl suspend ;;
    *Reboot)    systemctl reboot ;;
    *"Shut down") systemctl poweroff ;;
esac
