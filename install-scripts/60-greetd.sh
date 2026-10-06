#!/bin/bash
# 60-greetd.sh — Greetd + tuigreet en Fedora (login texto en tty1).
# En Debian existía GREETER=noctalia|tuigreet; en Fedora se usa siempre
# tuigreet (noctalia-greeter solo existe en Terra F44+, fuera de alcance).
# Usuario greeter: en Fedora el paquete greetd lo crea vía sysusers como
# `greeter` (en Debian era `_greetd`). OJO: sysusers corre al arrancar, así
# que recién instalado el usuario puede no existir aún: se fuerza con
# systemd-sysusers y, si ni así, se crea a mano.
# Ruta tuigreet: en Fedora vive en /usr/sbin (no /usr/bin): se resuelve
# con `command -v` para no hardcodear una ruta que rompa el login.
set -eo pipefail
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
common_init "60-greetd"

log "6/10 Configurando greetd + tuigreet..."

if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY-RUN] dnf greetd tuigreet + sysusers greeter + /etc/greetd/config.toml (tuigreet ruta dinámica) + usermod video/render/input + override Restart=always" | tee -a "$LOG"
    exit 0
fi

dnf_install_resilient greetd tuigreet || true

# El usuario greeter lo declara el paquete vía sysusers: forzarlo ahora
# (recién instalado puede no existir hasta el próximo arranque).
systemd-sysusers 2>/dev/null || true

GREET_USER="greeter"
if ! id "$GREET_USER" &>/dev/null; then
    id "_greetd" &>/dev/null && GREET_USER="_greetd"
fi
if ! id "$GREET_USER" &>/dev/null; then
    log_warn "ni greeter ni _greetd existen tras systemd-sysusers: creando 'greeter' a mano."
    useradd --system --no-create-home --shell /usr/sbin/nologin \
        --groups video,input -c "greetd greeter" greeter 2>/dev/null || \
    useradd --system --no-create-home --shell /usr/sbin/nologin \
        -c "greetd greeter" greeter || true
fi
if ! id "$GREET_USER" &>/dev/null; then
    log_error "no se pudo asegurar el usuario $GREET_USER; greetd no podrá arrancar el greeter."
    exit 1
fi
log "-> usuario greeter: $GREET_USER ($(id -u "$GREET_USER"))"

# Ruta real de tuigreet (Fedora: /usr/sbin; Debian: /usr/bin).
TUIGREET_BIN="$(command -v tuigreet || true)"
[ -z "$TUIGREET_BIN" ] && TUIGREET_BIN="/usr/sbin/tuigreet"
if [ ! -x "$TUIGREET_BIN" ]; then
    log_error "tuigreet no ejecutable en $TUIGREET_BIN; greetd no mostrará login."
    exit 1
fi
log "-> tuigreet en $TUIGREET_BIN"

mkdir -p /etc/greetd
mkdir -p /var/cache/tuigreet
chown -R "$GREET_USER": /var/cache/tuigreet || true
chmod 0755 /var/cache/tuigreet || true

# Sesión Hyprland real: en Fedora el .desktop puede pedir `Hyprland` (H mayúscula)
# o `hyprland` según versión/COPR. Elegir un --cmd inexistente deja tuigreet
# en loop sin entrada gráfica: se valida antes de escribir config.toml.
HYPR_CMD="Hyprland"
if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ] && [ ! -f /usr/share/wayland-sessions/Hyprland.desktop ]; then
    log_warn "/usr/share/wayland-sessions/hyprland.desktop no existe aún (¿40-hypr pendiente?). Se usa --cmd Hyprland y 90-services no enmascarará tty1."
elif grep -qi '^Exec=.*Hyprland' /usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/Hyprland.desktop 2>/dev/null; then
    HYPR_CMD="Hyprland"
else
    # El .desktop existe pero su Exec es minúscula (p.ej. `Exec=hyprland`).
    HYPR_CMD="$(grep -h -m1 '^Exec=' /usr/share/wayland-sessions/hyprland.desktop 2>/dev/null | cut -d= -f2 | awk '{print $1}' | xargs basename 2>/dev/null || echo hyprland)"
    [ -z "$HYPR_CMD" ] && HYPR_CMD="hyprland"
fi
log "-> sesión Hyprland: --cmd $HYPR_CMD"

# Backup previo (no solo .bak-tuigreet post-escritura) para poder revertir.
[ -f /etc/greetd/config.toml ] && cp -a /etc/greetd/config.toml "/etc/greetd/config.toml.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1
[default_session]
# Login texto con tuigreet (sesión validada contra /usr/share/wayland-sessions).
command = "$TUIGREET_BIN --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions --cmd $HYPR_CMD"
user = "$GREET_USER"
EOF
cp -a /etc/greetd/config.toml /etc/greetd/config.toml.bak-tuigreet 2>/dev/null || true
log "-> tuigreet configurado ($TUIGREET_BIN, usuario $GREET_USER, sesión $HYPR_CMD)"

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
log_ok "Greetd OK (tuigreet $TUIGREET_BIN, usuario $GREET_USER)"
