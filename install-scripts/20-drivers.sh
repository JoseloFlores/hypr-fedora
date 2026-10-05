#!/bin/bash
# 20-drivers.sh — Hardware y drivers gráficos en Fedora.
# Port de Debian: intel-microcode/amd64-microcode -> microcode_ctl,
# Mesa/VA-API con nombres Fedora, firmware via linux-firmware/sof-firmware,
# NVIDIA via RPM Fusion akmod-nvidia.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "20-drivers"

log "2/10 Detectando hardware e instalando drivers gráficos... (GPU=$GPU_TYPE)"

# Base gráfica y seat para cualquier entorno (físico o VM).
dnf_install_resilient mesa-dri-drivers mesa-vulkan-drivers mesa-libEGL mesa-libGL xorg-x11-server-Xwayland seatd libseat || true

# Microcode (un solo paquete en Fedora que cubre Intel+AMD).
dnf_install_resilient microcode_ctl || true

if [ "$GPU_TYPE" = "nvidia" ]; then
    # RPM Fusion nonfree requerido (10-repos lo instala).
    dnf_install_resilient akmod-nvidia libva-nvidia-driver || true
    log "-> NVIDIA: akmod compila el módulo en background (revisa con: modinfo -F version nvidia tras reboot)."
elif [ "$GPU_TYPE" = "amd" ]; then
    dnf_install_resilient mesa-va-drivers mesa-vdpau-drivers libva-utils || true
    # Codec patentados: variante freeworld de RPM Fusion (best-effort).
    dnf_install_resilient mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld || true
elif [ "$GPU_TYPE" = "intel" ]; then
    dnf_install_resilient intel-media-driver libva-intel-driver libva-utils || true
else
    log "-> GPU genérica/VM: solo base Mesa."
fi

dnf_install_resilient linux-firmware || true
# SOF audio: nombres que cambian entre versiones (sof-firmware no existe en F44).
dnf_install_resilient sof-firmware || log_warn "sof-firmware no disponible, se omite."
dnf_install_resilient alsa-sof-firmware || log_warn "alsa-sof-firmware no disponible, se omite."
log_ok "Drivers OK (GPU=$GPU_TYPE)"
