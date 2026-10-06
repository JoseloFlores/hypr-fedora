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
    # Backup antes de tocar el arranque (hardware real).
    cp -a /boot/grub2/grub.cfg "/boot/grub2/grub.cfg.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
    # En UEFI Fedora /boot/grub2/grub.cfg suele ser el destino real y
    # /boot/efi/EFI/fedora/grub.cfg un stub que lo referencia; regenerar
    # solo el primero es lo documentado. Si existe el stub, se re-sincroniza.
    grub2-mkconfig -o /boot/grub2/grub.cfg || true
    if [ -f /boot/efi/EFI/fedora/grub.cfg ]; then
        cp -a /boot/efi/EFI/fedora/grub.cfg "/boot/efi/EFI/fedora/grub.cfg.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
    fi
    log "-> GRUB regenerado con grub2-mkconfig (backup previo en /boot/grub2/)"
else
    log_warn "grub2-mkconfig no disponible (bootloader distinto, p.ej. systemd-boot). Se omite."
fi
