#!/bin/bash
# 70-dots.sh — Despliegue de dotfiles a ~/.config (port de Debian a Fedora).
# Idéntico al original salvo: rutas REPO_ROOT planas (no ../noctalia) y
# plugin de updates Fedora (jo/updates-fedora) en vez de Debian.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "70-dots"

log "7/10 Desplegando configuraciones en $USER_HOME/.config..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] cp hyprland.conf hypridle.conf foot.ini noctalia/{*.toml,templates,hooks} noctalia/capture-apply.sh+updates-apply.sh systemd/user/* wlogout/layout+icons scripts a $USER_HOME/.config + wallpapers download (\$WALLPAPER_URL -> \$WALLPAPER_DIR)" | tee -a "$LOG"
    exit 0
fi

DOTS_CONF="$USER_HOME/.config"
sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p \
    "$DOTS_CONF/hypr" "$DOTS_CONF/noctalia" "$DOTS_CONF/foot" \
    "$DOTS_CONF/systemd/user" "$DOTS_CONF/wlogout"

for src in hyprland.conf hypridle.conf; do
    if [ -f "$REPO_ROOT/$src" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/$src" "$DOTS_CONF/hypr/"
    fi
done
if [ -f "$REPO_ROOT/wallpaper.jpg" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/wallpaper.jpg" "$DOTS_CONF/hypr/"
    log "-> semilla wallpaper.jpg copiada a $DOTS_CONF/hypr/ (legado, no versionar)"
fi

for src in confirm_power.sh auto_timezone.sh screen_recorder.sh; do
    if [ -f "$REPO_ROOT/$src" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/$src" "$DOTS_CONF/hypr/"
        chmod +x "$DOTS_CONF/hypr/$src" 2>/dev/null || true
    fi
done
# Scripts Noctalia del repo (viven en noctalia/ en ambos proyectos).
for nsrc in capture-apply.sh updates-apply.sh plugins-apply.sh greeter-sync-apply.sh; do
    if [ -f "$REPO_ROOT/noctalia/$nsrc" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/noctalia/$nsrc" "$DOTS_CONF/hypr/${nsrc%.sh}-fedora.sh"
        # Nombres compatibles con la doc Debian para el plugin de captura:
        if [ "$nsrc" = "capture-apply.sh" ]; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/noctalia/$nsrc" "$DOTS_CONF/hypr/capture-apply.sh"
        fi
        chmod +x "$DOTS_CONF/hypr/"*.sh 2>/dev/null || true
    fi
done
# Parche legado region-recorder (se conserva por compat, jubilado por jo/capture).
if [ -d "$REPO_ROOT/noctalia/plugins" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$DOTS_CONF/hypr/noctalia-plugins"
    for pf in "$REPO_ROOT"/noctalia/plugins/*.patch; do
        [ -f "$pf" ] || continue
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$pf" "$DOTS_CONF/hypr/noctalia-plugins/"
    done
    log "-> parches en $DOTS_CONF/hypr/noctalia-plugins/"
fi

if [ -d "$REPO_ROOT/wlogout" ]; then
    if [ -f "$REPO_ROOT/wlogout/layout" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/wlogout/layout" "$DOTS_CONF/wlogout/"
    fi
    if [ -f "$DOTS_CONF/wlogout/style.css" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            sed -i -E "s#url\(\"/home/[^/\"]+#url(\"$USER_HOME#g" "$DOTS_CONF/wlogout/style.css" || true
    fi
    log "-> wlogout desplegado en $DOTS_CONF/wlogout/"
    if [ -d "$REPO_ROOT/wlogout/icons" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$USER_HOME/.local/share/wlogout/icons"
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/wlogout/icons/"*.png "$USER_HOME/.local/share/wlogout/icons/"
    fi
fi

if [ -d "$REPO_ROOT/nvim" ]; then
    if [ ! -e "$USER_HOME/.config/nvim" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$USER_HOME/.config/nvim/lua/plugins"
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/nvim/init.lua" "$USER_HOME/.config/nvim/"
        [ -f "$REPO_ROOT/nvim/lazy-lock.json" ] && sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/nvim/lazy-lock.json" "$USER_HOME/.config/nvim/"
        if [ -d "$REPO_ROOT/nvim/lua/plugins" ]; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/nvim/lua/plugins/"*.lua "$USER_HOME/.config/nvim/lua/plugins/"
        fi
        log "-> nvim desplegado en $USER_HOME/.config/nvim/ (plugins los baja lazy.nvim)"
    else
        log "-> nvim existente, no se pisa (el template aporta matugen.lua)"
    fi
fi

if [ -f "$REPO_ROOT/NOCTALIA_COMANDOS.md" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/NOCTALIA_COMANDOS.md" "$DOTS_CONF/hypr/"
fi

if [ -d "$REPO_ROOT/noctalia" ]; then
    for f in "$REPO_ROOT"/noctalia/*.toml; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        if [ ! -f "$DOTS_CONF/noctalia/$base" ]; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$f" "$DOTS_CONF/noctalia/"
        fi
    done
    for sub in templates hooks; do
        if [ -d "$REPO_ROOT/noctalia/$sub" ]; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$DOTS_CONF/noctalia/$sub"
            for tf in "$REPO_ROOT/noctalia/$sub/"*; do
                [ -f "$tf" ] || continue
                sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$tf" "$DOTS_CONF/noctalia/$sub/"
            done
        fi
    done
    sudo -u "$REAL_USER" env HOME="$USER_HOME" \
        sed -i "s#__HOME__#$USER_HOME#g" "$DOTS_CONF"/noctalia/*.toml "$DOTS_CONF"/noctalia/templates/* "$DOTS_CONF"/noctalia/hooks/* 2>/dev/null || true
    log "-> noctalia/*.toml + templates/ + hooks/ desplegado en $DOTS_CONF/noctalia/"
fi

if [ -d "$REPO_ROOT/systemd/user" ]; then
    for u in "$REPO_ROOT/systemd/user"/*; do
        [ -f "$u" ] || continue
        sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$u" "$DOTS_CONF/systemd/user/"
    done
    # linger para que el user-manager exista aunque el enable ocurra sin sesión.
    loginctl enable-linger "$REAL_USER" 2>/dev/null || true
    sudo -u "$REAL_USER" env HOME="$USER_HOME" systemctl --user daemon-reload 2>/dev/null || true
    # La zona horaria la gestiona el timer DE SISTEMA (90-services):
    # desactivar el user-timer legado para no duplicar detecciones.
    sudo -u "$REAL_USER" env HOME="$USER_HOME" systemctl --user stop auto-timezone.timer 2>/dev/null || true
    sudo -u "$REAL_USER" env HOME="$USER_HOME" systemctl --user disable auto-timezone.timer 2>/dev/null || true
    log "-> user-manager listo (linger); auto-timezone lo lleva el timer de sistema"
fi

if [ -f "$REPO_ROOT/foot.ini" ] && [ ! -f "$DOTS_CONF/foot/foot.ini" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$REPO_ROOT/foot.ini" "$DOTS_CONF/foot/foot.ini"
    log "-> foot.ini desplegado en $DOTS_CONF/foot/"
fi

HYPR_CONF="$DOTS_CONF/hypr/hyprland.conf"
if [ "$GPU_TYPE" = "nvidia" ] && [ -f "$HYPR_CONF" ]; then
    sed -i '/^# NVIDIA_ENV_BEGIN/,/^# NVIDIA_ENV_END/{s/^# env =/env =/;}' "$HYPR_CONF"
    log "-> hyprland.conf: variables NVIDIA activadas"
fi

WALLPAPER_DIR="${WALLPAPER_DIR:-$USER_HOME/Imágenes/wallpapers/wallpaper}"
[[ "$WALLPAPER_DIR" == /root/* ]] && WALLPAPER_DIR="$USER_HOME/Imágenes/wallpapers/wallpaper"
WALLPAPER_URL="${WALLPAPER_URL:-}"
if [ -n "$WALLPAPER_URL" ]; then
    sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$WALLPAPER_DIR"
    log "-> descargando wallpapers: $WALLPAPER_URL -> $WALLPAPER_DIR"
    if [[ "$WALLPAPER_URL" == *.zip ]]; then
        _tmpzip="/tmp/wallpapers-$(date +%s).zip"
        if sudo -u "$REAL_USER" env HOME="$USER_HOME" wget -q --show-progress --tries=5 --waitretry=3 --timeout=20 -O "$_tmpzip" "$WALLPAPER_URL"; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" unzip -o -q "$_tmpzip" -d "$WALLPAPER_DIR"
            rm -f "$_tmpzip"
        else
            log_warn "no se pudo descargar WALLPAPER_URL (zip). Revisa la URL."
        fi
    else
        _fname="$(basename "$WALLPAPER_URL")"
        [ -z "$_fname" ] && _fname="wallpaper.jpg"
        sudo -u "$REAL_USER" env HOME="$USER_HOME" wget -q --show-progress --tries=5 --waitretry=3 --timeout=20 -O "$WALLPAPER_DIR/$_fname" "$WALLPAPER_URL" \
            || log_warn "no se pudo descargar WALLPAPER_URL. Revisa la URL."
    fi
    if [ ! -f "$DOTS_CONF/hypr/wallpaper.jpg" ]; then
        _first="$(sudo -u "$REAL_USER" env HOME="$USER_HOME" bash -c "ls -1 \"$WALLPAPER_DIR\"/*.{jpg,jpeg,png,webp} 2>/dev/null | head -n1" || true)"
        if [ -n "$_first" ] && [ -f "$_first" ]; then
            sudo -u "$REAL_USER" env HOME="$USER_HOME" cp -f "$_first" "$DOTS_CONF/hypr/wallpaper.jpg"
            log "-> semilla hyprlock desde pack descargado"
        fi
    fi
    chown -R "$REAL_USER":"$REAL_USER" "$WALLPAPER_DIR" 2>/dev/null || true
else
    log "-> WALLPAPER_URL vacío: se omite descarga (crea $WALLPAPER_DIR o define URL en preset)"
    sudo -u "$REAL_USER" env HOME="$USER_HOME" mkdir -p "$WALLPAPER_DIR" || true
fi

chown -R "$REAL_USER":"$REAL_USER" "$DOTS_CONF"
restorecon -R "$DOTS_CONF" 2>/dev/null || true
find "$DOTS_CONF" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
log_ok "Dots OK (colores los aplica Noctalia al iniciar sesión: templates-apply)"
