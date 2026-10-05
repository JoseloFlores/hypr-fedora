#!/bin/bash
# 10-repos.sh — Repositorios Fedora (RPM Fusion free/nonfree + COPR Hyprland fallback)
# Equivale al 10-repos.sh de Debian (contrib/backports). En Fedora no hay
# backports: Hyprland vive en repos oficiales (huérfano en F42, ausente en F43)
# y se usa COPR sdegler/hyprland como respaldo. Noctalia: repos oficiales F44+,
# si no, COPR lionheartp/Hyprland (noctalia-git).
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "10-repos"

log "1/10 Configurando repositorios Fedora (RPM Fusion + COPR respaldo)..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] dnf install rpmfusion-free/nonfree-release + makecache + copr sdegler/hyprland (solo si falta hyprland)" | tee -a "$LOG"
    exit 0
fi

FEDORA_VER="$(rpm -E %fedora 2>/dev/null || echo "$OS_VERSION")"
log "-> Fedora $FEDORA_VER"

# RPM Fusion free + nonfree (drivers, codecs, firmware, NVIDIA).
if ! pkg_installed rpmfusion-free-release; then
    log "-> instalando RPM Fusion free..."
    run_bash "rpmfusion free" \
        dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VER.noarch.rpm" || \
        log_warn "RPM Fusion free falló (revisa red). Se continúa sin él."
fi
if ! pkg_installed rpmfusion-nonfree-release; then
    log "-> instalando RPM Fusion nonfree..."
    run_bash "rpmfusion nonfree" \
        dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VER.noarch.rpm" || \
        log_warn "RPM Fusion nonfree falló (revisa red). Se continúa sin él."
fi

# Asegura plugin copr (dnf5 lo trae en dnf-plugins-core, pero puede faltar en Everything mínima).
if ! dnf copr --help &>/dev/null; then
    dnf_install_resilient dnf-plugins-core || true
fi

# COPR Hyprland (respaldo): solo si los repos base no ven hyprland.
# sdegler/hyprland es el fork mantenido de solopasha/hyprland (Qt 6.10 en F43+).
if ! dnf repoquery --available hyprland 2>/dev/null | grep -qi hyprland; then
    log "-> hyprland no visible en repos base, habilitando COPR sdegler/hyprland..."
    run_bash "copr hyprland" dnf copr enable -y sdegler/hyprland || \
        log_warn "COPR sdegler/hyprland falló (40-hypr lo reintentará o fallará)."
else
    log "-> hyprland visible en repos base (sin COPR por ahora)."
fi

# Noctalia: oficial en F44+. En F42/F43 se deja para 71-noctalia (COPR lionheartp).
if dnf repoquery --available noctalia 2>/dev/null | grep -qi "^noctalia"; then
    log "-> noctalia visible en repos (Fedora 44+)."
else
    log "-> noctalia no está en repos base (normal en F42/F43): 71-noctalia usará COPR lionheartp/Hyprland."
fi

dnf_update_resilient || true
log_ok "Repos OK (Fedora $FEDORA_VER)"
