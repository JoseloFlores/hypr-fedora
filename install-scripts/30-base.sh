#!/bin/bash
# 30-base.sh — Paquetes base + backlight + locales en Fedora.
# Port de Debian: nombres adaptados a Fedora (ver README tabla).
# firefox-esr->firefox, mako-notifier->mako, fonts-*-mono->*-fonts, etc.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "30-base"

log "3/10 Instalando herramientas base..."

BASE_PKGS=(
    wget curl bc jq python3 fontconfig libnotify xdg-utils
    gcc gcc-c++ make pkgconf-pkg-config unzip pciutils
    NetworkManager network-manager-applet iw rfkill
    gvfs gvfs-fuse udisks2 udiskie
    pipewire pipewire-alsa pipewire-pulseaudio wireplumber pavucontrol
    alsa-utils alsa-ucm
    bluez blueman
    wl-clipboard cliphist brightnessctl playerctl
    foot alacritty grim slurp swappy wf-recorder wlogout
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs
    vim zenity
    # mako provee el virtual notification-daemon que blueman exige.
    # Nunca se autostartea: Noctalia es quien sirve las notificaciones.
    mako
    jetbrains-mono-fonts google-noto-color-emoji-fonts fira-code-fonts
    gnome-keyring gnome-keyring-pam seahorse
    polkit qt6-qtwayland
)
# nwg-look no está garantizado en Fedora Everything: best-effort aparte.
# Apps opcionales por preset.
if [ "${INSTALL_FIREFOX:-ON}" != "OFF" ]; then
    BASE_PKGS+=(firefox)
fi
if [ "${INSTALL_THUNDERBIRD:-OFF}" = "ON" ]; then
    BASE_PKGS+=(thunderbird)
fi
if [ "${INSTALL_THUNAR:-ON}" != "OFF" ]; then
    BASE_PKGS+=(thunar thunar-archive-plugin thunar-volman xarchiver tumbler ffmpegthumbnailer)
fi
if [ "${INSTALL_MEDIA:-ON}" != "OFF" ]; then
    BASE_PKGS+=(imv mpv)
fi
if [ "${INSTALL_ZSH_EXTRA:-OFF}" = "ON" ]; then
    BASE_PKGS+=(zsh)
fi

dnf_install_resilient "${BASE_PKGS[@]}"
# Best-effort que pueden no existir en ciertas versiones:
dnf_install_resilient nwg-look || log_warn "nwg-look no disponible, se omite (solo era visor de temas)."
dnf_install_resilient xdg-desktop-portal-hyprland || log_warn "xdg-desktop-portal-hyprland no instalable desde base (COPR sdegler lo provee)."
dnf_install_resilient hyprpolkitagent || log_warn "hyprpolkitagent aún no (40-hypr lo instala)."
dnf_install_resilient flatpak || true

run_cmd systemctl enable bluetooth || true

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] udev 90-backlight.rules + xdg-user-dirs-update (sin locale-gen en Fedora)" | tee -a "$LOG"
    exit 0
fi

cat > /etc/udev/rules.d/90-backlight.rules <<'UDEV'
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
UDEV
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger --subsystem-match=backlight --action=add 2>/dev/null || true
for bl in /sys/class/backlight/*/brightness; do
    [ -e "$bl" ] || continue
    chgrp video "$bl" 2>/dev/null || true
    chmod g+w "$bl" 2>/dev/null || true
done

# Fedora no usa locale-gen: los locales ya vienen en glibc-langpack-*.
# Asegura español si se quiere (best-effort).
dnf_install_resilient glibc-langpack-es || true

USER_LANG="$(sudo -u "$REAL_USER" bash -lc 'printf %s "${LANG:-}"' 2>/dev/null || true)"
if locale -a 2>/dev/null | grep -qi 'es_ES'; then
    XDG_LANG="es_ES.UTF-8"
elif [ -n "$USER_LANG" ]; then
    XDG_LANG="$USER_LANG"
else
    XDG_LANG="C.UTF-8"
fi
sudo -u "$REAL_USER" env HOME="$USER_HOME" LANG="$XDG_LANG" xdg-user-dirs-update --force || true
sudo -u "$REAL_USER" env HOME="$USER_HOME" bash -c 'thunar -q 2>/dev/null || true' || true
log_ok "Base OK"
