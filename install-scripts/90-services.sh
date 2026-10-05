#!/bin/bash
# 90-services.sh — Servicios y red NetworkManager en Fedora.
# Port de Debian: sin /etc/network/interfaces ni dhcpcd; solo NM + systemd.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "90-services"

log "9/10 Configurando servicios y preparación de red..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] NM unmanaged-devices=none + enable NetworkManager/bluetooth/greetd + disable gdm/sddm + mask getty@tty1" | tee -a "$LOG"
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
systemctl mask getty@tty1.service 2>/dev/null || true
systemctl enable greetd
log_ok "Servicios OK"
