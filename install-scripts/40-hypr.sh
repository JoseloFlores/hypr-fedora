#!/bin/bash
# 40-hypr.sh — Hyprland stack en Fedora (repos base + COPR sdegler/hyprland respaldo).
# En F42 el paquete oficial está huérfano (0.45), en F43 puede faltar:
# si dnf no lo ve, se habilita el COPR mantenido y se reintenta.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "40-hypr"

log "4/10 Instalando Hyprland..."

# Obligatorios: si falta uno, no hay escritorio (reintento vía COPR).
HYPR_PKGS=(hyprland hyprlock hypridle xdg-desktop-portal-hyprland greetd tuigreet)
# Opcionales: mejoran pero no bloquean (polkit, lanzador uwsm, utilidades Qt).
HYPR_OPT_PKGS=(hyprpolkitagent uwsm)
HYPR_QT_PKGS=(hyprland-qtutils hyprland-qt-support)

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] dnf install -y ${HYPR_PKGS[*]} (+ best-effort ${HYPR_OPT_PKGS[*]} ${HYPR_QT_PKGS[*]})" | tee -a "$LOG"
    exit 0
fi

if ! dnf_install_resilient "${HYPR_PKGS[@]}"; then
    log_warn "Repos base no traen el stack completo. Habilitando COPR sdegler/hyprland y reintentando..."
    dnf copr enable -y sdegler/hyprland || log_warn "COPR falló, reintentando de todos modos."
    dnf_install_resilient "${HYPR_PKGS[@]}"
fi
# Best-effort por separado: un nombre ausente en F44 no tumba el stack.
for _opt in "${HYPR_OPT_PKGS[@]}" "${HYPR_QT_PKGS[@]}"; do
    dnf_install_resilient "$_opt" || log_warn "$_opt no disponible, se omite."
done
# NOTA uwsm: queda instalado como lanzador opcional, pero tuigreet lanza
# Hyprland directo (--cmd Hyprland validado en 60-greetd) por simplicidad.
log_ok "Hyprland stack OK"
