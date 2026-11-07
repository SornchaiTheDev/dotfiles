#!/usr/bin/env bash
# Root part of the DMS -> plain niri migration. Run: sudo ~/.config/niri/greeter/install.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing packages"
pacman -S --needed --noconfirm waybar swaylock swayidle playerctl polkit-gnome \
    gnome-keyring greetd-regreet noto-fonts-emoji

echo "==> Installing greeter config"
cp -n /etc/greetd/config.toml /etc/greetd/config.toml.dms-backup || true
install -m644 "$SRC/config.toml"       /etc/greetd/config.toml
install -m644 "$SRC/niri-greeter.kdl"  /etc/greetd/niri-greeter.kdl
install -m644 "$SRC/regreet.toml"      /etc/greetd/regreet.toml
install -m644 "$SRC/regreet.css"       /etc/greetd/regreet.css
install -d -o greeter -g greeter /var/lib/regreet /var/log/regreet

echo "==> Unlocking gnome-keyring at login (PAM)"
P=/etc/pam.d/greetd
grep -q pam_gnome_keyring "$P" || {
    cp "$P" "$P.bak"
    sed -i '/^auth.*system-local-login/a auth       optional     pam_gnome_keyring.so' "$P"
    sed -i '/^session.*system-local-login/a session    optional     pam_gnome_keyring.so auto_start' "$P"
}

echo "==> Removing DankMaterialShell"
pkgs=()
for p in dms-shell-niri dms-shell-hyprland dms-shell greetd-dms-greeter-git; do
    pacman -Q "$p" &>/dev/null && pkgs+=("$p")
done
((${#pkgs[@]})) && pacman -Rns --noconfirm "${pkgs[@]}"
# quickshell/dgop were pulled in as DMS deps; -Rns removes them unless something else needs them
for p in quickshell dgop; do
    pacman -Q "$p" &>/dev/null && pacman -Rns --noconfirm "$p" 2>/dev/null || true
done

echo "==> Done. Log out (Mod+Shift+E) or reboot to land on ReGreet."
