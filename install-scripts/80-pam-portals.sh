#!/bin/bash
# 80-pam-portals.sh — PAM gnome-keyring + portales xdg en Fedora.
# Port de Debian: pam-auth-update no existe -> se edita /etc/pam.d/greetd
# directo (paquete gnome-keyring-pam provee pam_gnome_keyring.so).
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "80-pam-portals"

log "8/10 Finalizando permisos y PAM..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] parche /etc/pam.d/greetd (auth tras common-auth + session auto_start) + hyprland-portals.conf" | tee -a "$LOG"
    exit 0
fi

dnf_install_resilient gnome-keyring gnome-keyring-pam || true

if [ ! -f /etc/pam.d/greetd ]; then
    cat > /etc/pam.d/greetd <<'PAMGREETD'
#%PAM-1.0
auth       substack     system-login
auth       optional     pam_gnome_keyring.so
account    include      system-login
password   include      system-login
session    include      system-login
session    optional     pam_gnome_keyring.so auto_start
PAMGREETD
    log "-> /etc/pam.d/greetd creado (plantilla Fedora + keyring)"
fi
# Normaliza siempre (evita duplicados y orden incorrecto que deja el llavero bloqueado).
sed -i '/pam_gnome_keyring\.so/d' /etc/pam.d/greetd
if grep -q "system-login" /etc/pam.d/greetd; then
    sed -i '/^auth.*substack.*system-login/a auth       optional     pam_gnome_keyring.so' /etc/pam.d/greetd
    echo 'session    optional     pam_gnome_keyring.so auto_start' >> /etc/pam.d/greetd
elif grep -q "@include common-auth" /etc/pam.d/greetd; then
    sed -i '/@include common-auth/a auth    optional        pam_gnome_keyring.so' /etc/pam.d/greetd
    echo 'session optional        pam_gnome_keyring.so auto_start' >> /etc/pam.d/greetd
else
    echo 'auth       optional     pam_gnome_keyring.so' >> /etc/pam.d/greetd
    echo 'session    optional     pam_gnome_keyring.so auto_start' >> /etc/pam.d/greetd
fi
restorecon /etc/pam.d/greetd 2>/dev/null || true

mkdir -p /etc/xdg/xdg-desktop-portal
if [ ! -f /etc/xdg/xdg-desktop-portal/hyprland-portals.conf ]; then
    cat > /etc/xdg/xdg-desktop-portal/hyprland-portals.conf <<'PORTAL'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=gtk
PORTAL
fi
log_ok "PAM + portales OK"
