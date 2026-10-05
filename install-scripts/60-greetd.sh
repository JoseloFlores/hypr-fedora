#!/bin/bash
# 60-greetd.sh — Greetd + tuigreet en Fedora (login texto en tty1).
# En Debian existía GREETER=noctalia|tuigreet; en Fedora se usa siempre
# tuigreet (noctalia-greeter solo existe en Terra F44+, fuera de alcance).
# Usuario greeter: en Fedora el paquete greetd crea el usuario `greeter`
# (en Debian era `_greetd`).
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "60-greetd"

log "6/10 Configurando greetd + tuigreet..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] dnf greetd tuigreet + /etc/greetd/config.toml (tuigreet Hyprland) + usermod video/render/input + override Restart=always" | tee -a "$LOG"
    exit 0
fi

dnf_install_resilient greetd tuigreet || true

GREET_USER="greeter"
id "$GREET_USER" &>/dev/null || GREET_USER="_greetd"
if ! id "$GREET_USER" &>/dev/null; then
    log_warn "no existe usuario greeter ni _greetd (¿greetd sin instalar?). Se usa 'greeter' igual."
    GREET_USER="greeter"
fi

mkdir -p /etc/greetd
mkdir -p /var/cache/tuigreet
chown -R "$GREET_USER": /var/cache/tuigreet 2>/dev/null || chown -R greeter: /var/cache/tuigreet 2>/dev/null || true
chmod 0755 /var/cache/tuigreet || true

cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1
[default_session]
# Login texto con tuigreet (Hyprland capital H = sesión wayland de Fedora).
command = "/usr/bin/tuigreet --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions --cmd Hyprland"
user = "$GREET_USER"
EOF
cp -a /etc/greetd/config.toml /etc/greetd/config.toml.bak-tuigreet 2>/dev/null || true
log "-> tuigreet configurado (usuario $GREET_USER, sesión Hyprland)"

usermod -aG video,render,input "$GREET_USER" 2>/dev/null || usermod -aG video,input "$GREET_USER" || true
usermod -aG video,render,input,audio "$REAL_USER" || true
if [ "${INSTALL_INPUT_GROUP:-ON}" != "OFF" ]; then
    usermod -aG input "$REAL_USER" || true
fi

# SELinux: deja que greetd ejecute tuigreet y lea sesiones.
restorecon -Rv /etc/greetd /var/cache/tuigreet 2>/dev/null || true

mkdir -p /etc/systemd/system/greetd.service.d/
cat > /etc/systemd/system/greetd.service.d/override.conf <<EOF
[Service]
Restart=always
RestartSec=5
EOF
systemctl daemon-reload
log_ok "Greetd OK (tuigreet, usuario $GREET_USER)"
