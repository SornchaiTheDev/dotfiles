#!/usr/bin/env bash
# Wi-Fi picker for iwd, shown with rofi.
# Left-click in waybar: pick a network / disconnect / rescan / toggle Wi-Fi.

IFACE="${WIFI_IFACE:-wlan0}"

strip() { sed 's/\x1b\[[0-9;]*m//g'; }
notify() { notify-send -a "Wi-Fi" -i network-wireless "Wi-Fi" "$1"; }
menu() { rofi -dmenu -i -p "$1" "${@:2}"; }

powered=$(iwctl device "$IFACE" show | strip | awk '{for(i=1;i<NF;i++) if($i=="Powered"){print $(i+1); exit}}')
if [[ "$powered" != "on" ]]; then
    choice=$(printf '󰖩  Turn Wi-Fi on\n' | menu "Wi-Fi (off)")
    [[ -n "$choice" ]] && iwctl device "$IFACE" set-property Powered on && notify "Wi-Fi turned on"
    exit 0
fi

# Do a quick scan so the list is fresh. It's asynchronous, so give it a moment.
iwctl station "$IFACE" scan 2>/dev/null && sleep 1.5

# Networks iwd already has credentials for
mapfile -t known < <(iwctl known-networks list | strip | tail -n +5 |
    sed -E 's/^ +//; s/ +(psk|open|8021x) .*$//' | sed '/^$/d')
is_known() { local k; for k in "${known[@]}"; do [[ "$k" == "$1" ]] && return 0; done; return 1; }

# Parse "  >   Name with  spaces     psk     -4800" (signal is dBm * 100)
ssids=(); secs=(); labels=()
current=""
while IFS=$'\x1f' read -r conn name sec rssi; do
    dbm=$(( rssi / 100 ))
    if   (( dbm >= -55 )); then bars="󰤨"
    elif (( dbm >= -65 )); then bars="󰤥"
    elif (( dbm >= -75 )); then bars="󰤢"
    else                        bars="󰤟"; fi
    [[ "$sec" == "open" ]] && lock="  " || lock="󰌾 "
    mark=""
    [[ "$conn" == ">" ]] && { mark="  (connected)"; current="$name"; }
    is_known "$name" && [[ -z "$mark" ]] && mark="  (saved)"
    ssids+=("$name"); secs+=("$sec")
    labels+=("$bars  $lock $name$mark")
done < <(iwctl station "$IFACE" get-networks rssi-dbms | strip | tail -n +5 |
    sed -nE 's/^ *(>)? +(.*[^ ]) +(psk|open|8021x|wep) +(-?[0-9]+) *$/\1\x1f\2\x1f\3\x1f\4/p')

# Extra actions after the network list
actions=()
[[ -n "$current" ]] && actions+=("󰖪  Disconnect from $current")
actions+=("󰑐  Rescan" "󰖪  Turn Wi-Fi off")

idx=$(printf '%s\n' "${labels[@]}" "${actions[@]}" | menu "Wi-Fi" -format i)
[[ -z "$idx" ]] && exit 0

# Selected an action?
if (( idx >= ${#ssids[@]} )); then
    case "${actions[idx - ${#ssids[@]}]}" in
        *Disconnect*) iwctl station "$IFACE" disconnect && notify "Disconnected from $current" ;;
        *Rescan)      exec "$0" ;;
        *"Wi-Fi off") iwctl device "$IFACE" set-property Powered off && notify "Wi-Fi turned off" ;;
    esac
    exit 0
fi

ssid="${ssids[idx]}"; sec="${secs[idx]}"
[[ "$ssid" == "$current" ]] && { notify "Already connected to $ssid"; exit 0; }

if [[ "$sec" == "open" ]] || is_known "$ssid"; then
    out=$(iwctl station "$IFACE" connect "$ssid" 2>&1)
elif [[ "$sec" == "psk" ]]; then
    pw=$(rofi -dmenu -password -p "Password for $ssid" < /dev/null)
    [[ -z "$pw" ]] && exit 0
    out=$(iwctl --passphrase "$pw" station "$IFACE" connect "$ssid" 2>&1)
else
    notify "$ssid uses $sec security — set it up with iwctl in a terminal"
    exit 1
fi

if [[ $? -eq 0 ]]; then
    notify "Connected to $ssid"
else
    notify "Failed to connect to $ssid: ${out:-unknown error}"
fi
