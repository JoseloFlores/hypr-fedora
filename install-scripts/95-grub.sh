#!/bin/bash
# 95-grub.sh — Tema GRUB en Fedora (grub2-mkconfig, sin desktop-base de Debian).
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "95-grub"

log "10/10 Actualizando GRUB (grub2-mkconfig)..."
if [ "${INSTALL_GRUB_THEME:-ON}" = "OFF" ]; then
    log_warn "INSTALL_GRUB_THEME=OFF — se omite."
    exit 0
fi
if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] grub2-mkconfig -o /boot/grub2/grub.cfg" | tee -a "$LOG"
    exit 0
fi
if command -v grub2-mkconfig &>/dev/null; then
    grub2-mkconfig -o /boot/grub2/grub.cfg || true
    log "-> GRUB regenerado con grub2-mkconfig"
else
    log_warn "grub2-mkconfig no disponible (bootloader distinto). Se omite."
fi
