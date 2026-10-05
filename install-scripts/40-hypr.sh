#!/bin/bash
# 40-hypr.sh — Hyprland stack en Fedora (repos base + COPR sdegler/hyprland respaldo).
# En F42 el paquete oficial está huérfano (0.45), en F43 puede faltar:
# si dnf no lo ve, se habilita el COPR mantenido y se reintenta.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "40-hypr"

log "4/10 Instalando Hyprland..."

HYPR_PKGS=(hyprland hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland greetd tuigreet uwsm)

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] dnf install -y ${HYPR_PKGS[*]} (+ hyprland-qtutils best-effort)" | tee -a "$LOG"
    exit 0
fi

if ! dnf_install_resilient "${HYPR_PKGS[@]}"; then
    log_warn "Repos base no traen el stack completo. Habilitando COPR sdegler/hyprland y reintentando..."
    dnf copr enable -y sdegler/hyprland || log_warn "COPR falló, reintentando de todos modos."
    dnf_install_resilient "${HYPR_PKGS[@]}"
fi
# Utilidades Qt de Hyprland (nombre nuevo; el viejo hyprland-guiutils ya no existe).
dnf_install_resilient hyprland-qtutils hyprland-qt-support || true
log_ok "Hyprland stack OK"
