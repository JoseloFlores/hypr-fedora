#!/bin/bash
# upgrade.sh — corre DENTRO de foot (foot bash upgrade.sh).
# Pide la contraseña con sudo, instala dnf + flatpak y sale.
# Uso: upgrade.sh [--no-yes]
set -u

AUTO_YES=1
for arg in "$@"; do
    [ "$arg" = "--no-yes" ] && AUTO_YES=0
done

DNF_FLAGS=()
FLAT_FLAGS=()
if [ "$AUTO_YES" = "1" ]; then
    DNF_FLAGS+=(-y)
    FLAT_FLAGS+=(-y)
fi

LOG="$HOME/.cache/noctalia/updates-last.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "=== Actualizaciones $(date '+%F %T') ==="

RC=0
echo "--- DNF ---"
sudo dnf upgrade "${DNF_FLAGS[@]}" || RC=1

if command -v flatpak >/dev/null 2>&1; then
    echo "--- Flatpak ---"
    flatpak update "${FLAT_FLAGS[@]}" || RC=1
fi

echo
if [ "$RC" = "0" ]; then
    echo "Sistema al dia."
    notify-send "Actualizaciones" "Sistema al dia." 2>/dev/null || true
else
    echo "Termino con errores (codigo $RC). Revisa arriba."
    notify-send "Actualizaciones" "Termino con errores, revisa la terminal." 2>/dev/null || true
    sleep 8
fi

# Re-chequeo silencioso para que el widget se oculte en el siguiente tick.
sleep 2
exit "$RC"
