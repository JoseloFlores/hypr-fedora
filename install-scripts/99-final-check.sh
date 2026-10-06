#!/bin/bash
# 99-final-check.sh — Verificación post-instalación en Fedora (rpm -q, no dpkg).
# No instala nada, solo reporta. Siempre exit 0 salvo error grave de uso.
set -u
set -o pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "99-final-check" || true

echo ""
echo "--- FINAL CHECK ---"
echo "Sistema: Fedora ${OS_VERSION:-?} | Usuario: ${REAL_USER:-?}"
missing=()
bins_missing=()

check_pkg() {
    if pkg_installed "$1"; then
        echo "[OK] $1: $(rpm -q "$1" 2>/dev/null)"
    else
        echo "[FALTA] $1 no instalado"
        missing+=("$1")
    fi
}

for p in noctalia hyprland greetd tuigreet foot NetworkManager brightnessctl wl-clipboard xdg-desktop-portal-hyprland; do
    # noctalia-git (COPR) cuenta como noctalia:
    if [ "$p" = "noctalia" ] && pkg_installed noctalia-git; then
        echo "[OK] noctalia-git: $(rpm -q noctalia-git 2>/dev/null) (cuenta como noctalia)"
        continue
    fi
    check_pkg "$p"
done

for b in Hyprland tuigreet noctalia foot hyprlock hypridle nmcli brightnessctl; do
    if command -v "$b" >/dev/null 2>&1; then
        echo "[OK] bin $b: $(command -v "$b")"
    else
        echo "[FALTA] bin $b no en PATH"
        bins_missing+=("$b")
    fi
done

# Noctalia (informativo: no bloquea el GREAT!, cubre INSTALL_NOCTALIA=OFF)
if [ "${INSTALL_NOCTALIA:-ON}" = "OFF" ]; then
    echo "[INFO] Noctalia omitido por preset (INSTALL_NOCTALIA=OFF)"
else
    for b in noctalia wlogout playerctl grim slurp wf-recorder powerprofilesctl; do
        if command -v "$b" >/dev/null 2>&1; then
            echo "[OK] noctalia bin $b: $(command -v "$b")"
        else
            echo "[FALTA] noctalia bin $b no en PATH (revisa 30-base/71-noctalia)"
        fi
    done
    if sudo -u "${REAL_USER:-$USER}" env HOME="${USER_HOME:-$HOME}" noctalia config validate >/dev/null 2>&1; then
        echo "[OK] noctalia config validate"
    else
        echo "[FALTA] noctalia config inválida (revisa ~/.config/noctalia/)"
    fi
    for f in templates.toml templates/foot.ini templates/wlogout.css templates/hyprlock.conf templates/matugen-template.lua hooks/foot-apply.sh hooks/sync-lock-wallpaper.sh; do
        if [ -f "${USER_HOME:-$HOME}/.config/noctalia/$f" ]; then
            echo "[OK] noctalia/$f"
        else
            echo "[FALTA] ~/.config/noctalia/$f (re-ejecuta 70-dots)"
        fi
    done
    if [ "${NOCTALIA_PLUGINS:-ON}" = "OFF" ]; then
        echo "[INFO] plugins Noctalia omitidos por preset (NOCTALIA_PLUGINS=OFF)"
    else
        if [ -d "${USER_HOME:-$HOME}/Vídeos/Recordings" ]; then
            echo "[OK] ~/Vídeos/Recordings (destino jo/capture)"
        else
            echo "[FALTA] ~/Vídeos/Recordings (re-ejecuta 71-noctalia o capture-apply.sh)"
        fi
        if [ -f "${USER_HOME:-$HOME}/.config/hypr/capture-apply.sh" ]; then
            echo "[OK] capture-apply.sh desplegado (re-ejecutable tras login)"
        else
            echo "[FALTA] capture-apply.sh (re-ejecuta 70-dots)"
        fi
        if grep -q 'jo/capture' "${USER_HOME:-$HOME}/.local/state/noctalia/settings.toml" 2>/dev/null; then
            echo "[OK] plugin jo/capture en settings.toml"
        else
            echo "[FALTA] plugin jo/capture no configurado (ejecuta ~/.config/hypr/capture-apply.sh)"
        fi
        if [ -d "${USER_HOME:-$HOME}/.local/share/noctalia/plugins/capture" ]; then
            echo "[OK] plugin jo/capture desplegado en local/share"
        else
            echo "[FALTA] plugin jo/capture no desplegado (ejecuta ~/.config/hypr/capture-apply.sh)"
        fi
        if grep -q 'jo/updates-fedora' "${USER_HOME:-$HOME}/.local/state/noctalia/settings.toml" 2>/dev/null; then
            echo "[OK] plugin jo/updates-fedora en settings.toml"
        else
            echo "[INFO] plugin jo/updates-fedora no configurado (ejecuta ~/.config/hypr/updates-apply-fedora.sh)"
        fi
    fi
fi

echo "Greetd: $(systemctl is-enabled greetd 2>&1 || echo 'no habilitado') (tuigreet)"
# El comando del greeter vive en config.toml, no en la unit de systemd:
# `systemctl cat greetd` jamás contiene "tuigreet" (falso negativo).
if grep -q "tuigreet" /etc/greetd/config.toml 2>/dev/null; then
    echo "[OK] greetd usa tuigreet ($(grep -m1 -o '/[^ ]*tuigreet' /etc/greetd/config.toml))"
else
    echo "[FALTA] greetd no apunta a tuigreet en /etc/greetd/config.toml (re-ejecuta 60-greetd)"
fi
if getent passwd greeter >/dev/null 2>&1 || getent passwd _greetd >/dev/null 2>&1; then
    echo "[OK] usuario greeter existe: $(getent passwd greeter 2>/dev/null || getent passwd _greetd)"
else
    echo "[FALTA] no existe usuario greeter ni _greetd (re-ejecuta 60-greetd)"
fi
echo "auto-timezone.timer (sistema): $({ systemctl is-enabled auto-timezone.timer 2>/dev/null || true; } | head -n1) | $({ systemctl is-active auto-timezone.timer 2>/dev/null || true; } | head -n1)"

# Llavero: PAM solo auto-desbloquea el llavero `login`.
if [ -f /etc/pam.d/greetd ]; then
    if grep -q 'pam_gnome_keyring\.so auto_start' /etc/pam.d/greetd && \
       grep -q 'pam_gnome_keyring\.so$' /etc/pam.d/greetd; then
        echo "[OK] greetd PAM: auth + session auto_start con gnome-keyring"
    else
        echo "[FALTA] greetd PAM sin keyring (re-ejecuta 80-pam-portals)"
    fi
else
    echo "[FALTA] /etc/pam.d/greetd no existe (re-ejecuta 60-greetd y 80-pam-portals)"
fi

if command -v hyprland >/dev/null 2>&1 || command -v Hyprland >/dev/null 2>&1; then
    echo "-> hyprland --verify-config:"
    # Bajo sudo no hay XDG_RUNTIME_DIR y hyprland aborta (core): correrlo
    # como el usuario real con un runtime temporal evita el ruido.
    _RT="/run/user/$(id -u "$REAL_USER" 2>/dev/null || echo 1000)"
    [ -d "$_RT" ] || _RT="$(sudo -u "$REAL_USER" env HOME="$USER_HOME" mktemp -d 2>/dev/null || echo /tmp)"
    (sudo -u "$REAL_USER" env HOME="$USER_HOME" XDG_RUNTIME_DIR="$_RT" hyprland --verify-config 2>&1 || sudo -u "$REAL_USER" env HOME="$USER_HOME" XDG_RUNTIME_DIR="$_RT" Hyprland --verify-config 2>&1 || true) | tail -n 5 | tee -a "$LOG"
fi

# Wallpapers: con WALLPAPER_URL vacío el dir queda vacío en limpia.
_WP_DIR="${WALLPAPER_DIR:-${USER_HOME:-$HOME}/Imágenes/wallpapers/wallpaper}"
if ls "$_WP_DIR"/*.{jpg,jpeg,png,webp} &>/dev/null; then
    echo "[OK] wallpapers en $_WP_DIR"
else
    echo "[INFO] $_WP_DIR vacío (WALLPAPER_URL vacío; Noctalia arranca sin fondo e hyprlock sin semilla)"
fi

if [ ${#missing[@]} -eq 0 ] && [ ${#bins_missing[@]} -eq 0 ]; then
    echo "${OK} GREAT! Paquetes esenciales instalados." | tee -a "$LOG"
else
    echo "${WARN} Faltantes rpm: ${missing[*]:-ninguno} | bins: ${bins_missing[*]:-ninguno}" | tee -a "$LOG"
    printf "%s\n" "${missing[@]}" "${bins_missing[@]}" >> "$LOG"
fi

if pkg_installed hyprland; then
    if pkg_installed noctalia || pkg_installed noctalia-git; then
        echo "¡INSTALACIÓN COMPLETADA!" | tee -a "$LOG"
    else
        echo "¡INSTALACIÓN COMPLETADA CON ADVERTENCIA! Hyprland OK, falta Noctalia." | tee -a "$LOG"
        echo "Reintenta luego:" | tee -a "$LOG"
        echo "  sudo ./install.sh --only 71-noctalia,99-final-check" | tee -a "$LOG"
        echo "Sin Noctalia el sistema arranca a Hyprland (sin barra/launcher)." | tee -a "$LOG"
    fi
    if [ "${GPU_TYPE:-generic}" = "nvidia" ]; then
        echo "AVISO NVIDIA: akmod compila tras reboot. Si falla el arranque gráfico, revisa: modinfo -F version nvidia ; mokutil --list-enrolled (Secure Boot)." | tee -a "$LOG"
    fi
else
    echo "¡INSTALACIÓN INCOMPLETA! Falta Hyprland. Revisa logs en $LOG_DIR" | tee -a "$LOG"
    exit 1
fi
