#!/usr/bin/env bash
# iwd backend for the Quickshell Wi-Fi popup.
#   iwd.sh list                 -> "P␟on|off" then "N␟conn␟ssid␟security␟dBm␟known" per network
#   iwd.sh scan                 -> trigger a scan (async in iwd)
#   iwd.sh connect <ssid>       -> passphrase (if any) is read from $WIFI_PASS
#   iwd.sh disconnect
#   iwd.sh power on|off
# Fields are separated by \x1f so SSIDs with spaces/tabs survive.

IFACE="${WIFI_IFACE:-wlan0}"
US=$'\x1f'
strip() { sed 's/\x1b\[[0-9;]*m//g'; }

case "$1" in
list)
    powered=$(iwctl device "$IFACE" show | strip |
        awk '{for(i=1;i<NF;i++) if($i=="Powered"){print $(i+1); exit}}')
    printf 'P%s%s\n' "$US" "${powered:-off}"
    [[ "$powered" == "on" ]] || exit 0

    mapfile -t known < <(iwctl known-networks list | strip | tail -n +5 |
        sed -E 's/^ +//; s/ +(psk|open|8021x) .*$//' | sed '/^$/d')

    iwctl station "$IFACE" get-networks rssi-dbms | strip | tail -n +5 |
        sed -nE "s/^ *(>)? +(.*[^ ]) +(psk|open|8021x|wep) +(-?[0-9]+) *\$/\1$US\2$US\3$US\4/p" |
    while IFS="$US" read -r conn name sec rssi; do
        k=0; for n in "${known[@]}"; do [[ "$n" == "$name" ]] && { k=1; break; }; done
        printf 'N%s%s%s%s%s%s%s%s%s%s\n' "$US" "${conn:+1}" "$US" "$name" "$US" "$sec" "$US" "$(( rssi / 100 ))" "$US" "$k"
    done
    ;;
status)
    # "wifi␟SSID", "ethernet" or "offline"
    for f in /sys/class/net/e*/operstate; do
        [[ -r "$f" && "$(<"$f")" == "up" ]] && { echo "ethernet"; exit 0; }
    done
    ssid=$(iwctl station "$IFACE" show 2>/dev/null | strip |
        sed -nE 's/^ *Connected network +(.*[^ ]) *$/\1/p')
    [[ -n "$ssid" ]] && printf 'wifi%s%s\n' "$US" "$ssid" || echo "offline"
    ;;
scan)       iwctl station "$IFACE" scan ;;
disconnect) iwctl station "$IFACE" disconnect ;;
power)      iwctl device "$IFACE" set-property Powered "$2" ;;
connect)
    if [[ -n "$WIFI_PASS" ]]; then
        out=$(iwctl --passphrase "$WIFI_PASS" station "$IFACE" connect "$2" 2>&1)
    else
        out=$(iwctl station "$IFACE" connect "$2" 2>&1)
    fi
    rc=$?
    out=$(printf '%s' "$out" | strip | tr -s '\n' ' ' | sed 's/^ *//; s/ *$//')
    # iwctl sometimes exits 0 on failure but prints an error
    grep -qiE 'fail|invalid|not found|error' <<<"$out" && rc=1
    # Always exit 0; the UI reads the result line ("OK" or "ERR␟message")
    if (( rc == 0 )); then echo "OK"; else printf 'ERR%s%s\n' "$US" "${out:-Connection failed}"; fi
    ;;
*) echo "usage: $0 list|scan|connect <ssid>|disconnect|power on|off" >&2; exit 2 ;;
esac
