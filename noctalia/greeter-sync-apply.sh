#!/bin/bash
# greeter-sync-apply.sh — Primer Sync del login Noctalia Greeter con tu
# wallpaper/paleta/monitores actuales. Idempotente.
#
# Hace:
#   1. `noctalia msg greeter-sync` (deja staged en $XDG_RUNTIME_DIR/noctalia-greeter-sync)
#   2. `pkexec noctalia-greeter-apply-appearance --sync <staging>` (pide clave
#      salvo passwordless-sync habilitado por 60-greetd.sh)
#   3. Muestra el scheme aplicado (esperado: "Synced")
#
# Uso (tras el primer login en Hyprland, con Noctalia corriendo):
#   ./noctalia/greeter-sync-apply.sh         # desde el repo
#   ~/.config/hypr/greeter-sync-apply.sh      # copia desplegada
#
# Auto-sync permanente: Noctalia Settings → Security → Noctalia Greeter →
# activar "Auto-Sync Greeter" (a partir de ahí cada cambio de fondo
# actualiza el login solo).
set -eo pipefail

if ! command -v noctalia >/dev/null 2>&1; then
    echo "[ERROR] noctalia no instalado" >&2
    exit 1
fi
if ! command -v noctalia-greeter-apply-appearance >/dev/null 2>&1; then
    echo "[ERROR] noctalia-greeter no instalado (re-ejecuta: sudo ./install.sh --only 60-greetd)" >&2
    exit 1
fi

echo "-> staged sync (noctalia msg greeter-sync)..."
noctalia msg greeter-sync

STAGING="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/noctalia-greeter-sync"
if [ ! -d "$STAGING" ]; then
    echo "[ERROR] sin staging en $STAGING (¿Noctalia corriendo?)" >&2
    exit 1
fi

echo "-> aplicando al login (pkexec)..."
pkexec /usr/bin/noctalia-greeter-apply-appearance --sync "$STAGING"

echo "-> login sincronizado. Verifica con logout (deberías ver tu wallpaper)."
