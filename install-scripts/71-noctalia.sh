#!/bin/bash
# 71-noctalia.sh — Shell Noctalia v5 en Fedora.
# Oficial en repos desde Fedora 44 (`dnf install noctalia`).
# En F42/F43: COPR lionheartp/Hyprland (noctalia-git). No bloqueante igual que Debian.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "71-noctalia"

if [ "${INSTALL_NOCTALIA:-ON}" = "OFF" ]; then
    log "Noctalia desactivado por preset (INSTALL_NOCTALIA=OFF), se omite."
    exit 0
fi

log "7b/10 Instalando Noctalia v5 + deps runtime..."

dnf_install_resilient upower power-profiles-daemon brightnessctl cliphist wl-clipboard || true

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] dnf install noctalia (repos base; si falta -> copr lionheartp/Hyprland noctalia-git) + deploy noctalia/*.toml + Capturas/Recordings + capture-apply + validate" | tee -a "$LOG"
    exit 0
fi

NOCTALIA_OK=0
if dnf_install_resilient noctalia; then
    log "-> noctalia instalado desde repos base"
    NOCTALIA_OK=1
else
    log_warn "noctalia no está en repos base (normal en F42/F43). Probando COPR lionheartp/Hyprland..."
    if dnf copr enable -y lionheartp/Hyprland && dnf_install_resilient noctalia-git; then
        log "-> noctalia-git instalado desde COPR lionheartp/Hyprland"
        NOCTALIA_OK=1
    else
        log_warn "noctalia no instalable ni por COPR."
    fi
fi

# --- ~/.config/noctalia (sin pisar config del usuario si ya existe) ---
if [ -d "$REPO_ROOT/noctalia" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$USER_HOME/.config/noctalia"
    for f in "$REPO_ROOT"/noctalia/*.toml; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        if [ ! -f "$USER_HOME/.config/noctalia/$base" ]; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$f" "$USER_HOME/.config/noctalia/"
        fi
    done
    chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config/noctalia" 2>/dev/null || true
fi

# --- ~/Pictures/Capturas + symlink ~/Imágenes/Capturas ---
sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$USER_HOME/Pictures/Capturas"
if [ ! -e "$USER_HOME/Imágenes/Capturas" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" ln -s "$USER_HOME/Pictures/Capturas" "$USER_HOME/Imágenes/Capturas" \
        && log "-> symlink Imágenes/Capturas -> Pictures/Capturas" || true
fi
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/Pictures/Capturas" 2>/dev/null || true

# --- ~/Vídeos/Recordings (destino del plugin jo/capture) ---
sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$USER_HOME/Vídeos/Recordings"
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/Vídeos/Recordings" 2>/dev/null || true

# --- Plugin local jo/capture (foto+video, backend wf-recorder) ---
if [ "${NOCTALIA_PLUGINS:-ON}" = "OFF" ]; then
    log "Plugins Noctalia desactivados por preset (NOCTALIA_PLUGINS=OFF), se omite."
elif [ -f "$REPO_ROOT/noctalia/capture-apply.sh" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" \
        NOCTALIA_PLUGINS=ON DRY_RUN=0 \
        bash "$REPO_ROOT/noctalia/capture-apply.sh" >>"$LOG" 2>&1 \
        && log "-> plugin jo/capture aplicado" \
        || log_warn "capture-apply.sh no completó (¿Noctalia sin arrancar?). Re-ejecuta tras el primer login: ~/.config/hypr/capture-apply.sh"
fi

# --- Plugin jo/updates-fedora (contador dnf + flatpak) ---
if [ "${NOCTALIA_PLUGINS:-ON}" != "OFF" ] && [ -f "$REPO_ROOT/noctalia/updates-apply.sh" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" DRY_RUN=0 \
        bash "$REPO_ROOT/noctalia/updates-apply.sh" >>"$LOG" 2>&1 \
        && log "-> plugin jo/updates-fedora aplicado" \
        || log_warn "updates-apply.sh no completó. Re-ejecuta tras el primer login."
fi

# --- GTK oscuro base (los templates gtk3/gtk4 de Noctalia ponen los colores) ---
for gver in 3.0 4.0; do
    gdir="$USER_HOME/.config/gtk-$gver"
    gini="$gdir/settings.ini"
    sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$gdir"
    if [ ! -f "$gini" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cat > "$gini" <<EOF
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF
    else
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            sed -i -E 's/^gtk-theme-name=.*/gtk-theme-name=Adwaita-dark/; s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$gini" || true
    fi
done
log "-> GTK en Adwaita-dark + prefer-dark (colores via templates Noctalia)"

if command -v noctalia >/dev/null 2>&1; then
    log "-> $(noctalia --version 2>&1 | head -n1)"
    rm -f "$LOG_DIR/noctalia-missing.flag" 2>/dev/null || true
    if sudo -u "$REAL_USER" env HOME="$USER_HOME" noctalia config validate >/dev/null 2>&1; then
        log_ok "Noctalia OK (arranca con exec-once = noctalia en hyprland.conf)"
    else
        log_warn "Noctalia instalado pero 'noctalia config validate' reporta avisos; revisa ~/.config/noctalia/"
    fi
    exit 0
fi
touch "$LOG_DIR/noctalia-missing.flag" 2>/dev/null || true
log_warn "Noctalia no instalable en esta Fedora."
log_warn "Hyprland queda usable sin shell Noctalia. Reintenta luego:"
log_warn "  sudo ./install.sh --only 71-noctalia,99-final-check"
exit 0
