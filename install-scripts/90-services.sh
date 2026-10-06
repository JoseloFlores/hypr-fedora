#!/bin/bash
# 90-services.sh — Servicios y red NetworkManager en Fedora.
# Port de Debian: sin /etc/network/interfaces ni dhcpcd; solo NM + systemd.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "90-services"

log "9/10 Configurando servicios y preparación de red..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] NM unmanaged-devices=none + enable NetworkManager/bluetooth/greetd + disable gdm/sddm + mask getty@tty1 (solo si greetd validado)" | tee -a "$LOG"
    exit 0
fi

log "-> Preparando configuración de NetworkManager para el próximo arranque..."
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/10-globally-managed-devices.conf <<'NMCONF'
[keyfile]
unmanaged-devices=none
NMCONF

systemctl enable NetworkManager 2>/dev/null || true
systemctl enable bluetooth 2>/dev/null || true
rfkill unblock all 2>/dev/null || true

systemctl disable sddm lightdm gdm 2>/dev/null || true
# tty1 solo se enmascara si greetd quedó sano (config + tuigreet + sesión).
# Si no, se deja getty activo para no perder el login en hardware real.
# NOTA: se exige UNA de las dos sesiones (hyprland.desktop o Hyprland.desktop),
# no las dos: pedir ambas con `ls A B` siempre fallaba y dejaba getty+greetd
# peleando por tty1 (boot a TTY sin tuigreet).
GREET_OK=1
grep -q "tuigreet" /etc/greetd/config.toml 2>/dev/null || GREET_OK=0
[ -x "$(command -v tuigreet || echo /usr/sbin/tuigreet)" ] || GREET_OK=0
if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ] && [ ! -f /usr/share/wayland-sessions/Hyprland.desktop ]; then
    GREET_OK=0
fi
id greeter &>/dev/null || id _greetd &>/dev/null || GREET_OK=0
if [ "$GREET_OK" = "1" ]; then
    systemctl mask getty@tty1.service 2>/dev/null || true
    log "-> getty@tty1 enmascarado (greetd validado; tty2-6 siguen con getty)"
else
    log_warn "greetd no validado (¿falta sesión Hyprland o tuigreet?); NO se enmascara getty@tty1."
    log_warn "Re-ejecuta: sudo ./install.sh --only 60-greetd,90-services,99-final-check"
fi
systemctl enable greetd
log_ok "Servicios OK"
