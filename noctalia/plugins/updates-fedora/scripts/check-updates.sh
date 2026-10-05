#!/bin/bash
# check-updates.sh — cuenta actualizaciones dnf y flatpak, sin sudo interactivo.
# Uso: check-updates.sh [--no-flatpak] [interval_minutes]
# Imprime una sola linea: "DNF FLAT TOTAL"
set -uo pipefail

NO_FLATPAK=0
for arg in "$@"; do
    [ "$arg" = "--no-flatpak" ] && NO_FLATPAK=1
done

# Gancho de prueba: si existe ~/.cache/noctalia/updates-debug con "DNF FLAT",
# se usa tal cual (para verificar el widget sin instalar nada).
DBG_FILE="$HOME/.cache/noctalia/updates-debug"
if [ -f "$DBG_FILE" ]; then
    read -r D F _ < "$DBG_FILE" || true
    [[ "$D" =~ ^[0-9]+$ ]] || D=0
    [[ "$F" =~ ^[0-9]+$ ]] || F=0
    echo "$D $F $((D + F))"
    exit 0
fi

count_dnf() {
    # dnf check-update sale con rc=100 cuando hay updates: se cuenta igual.
    dnf check-update -q 2>/dev/null | grep -cvE '^(Last metadata|Obsoleting|$)' || true
}

DNF=$(count_dnf)

FLAT=0
if [ "$NO_FLATPAK" = "0" ] && command -v flatpak >/dev/null 2>&1; then
    FLAT=$(timeout 60 flatpak remote-ls --updates --columns=application 2>/dev/null | grep -c . || true)
fi

# Normaliza a enteros por si algo raro llega vacio.
DNF=${DNF:-0}; FLAT=${FLAT:-0}
[[ "$DNF" =~ ^[0-9]+$ ]] || DNF=0
[[ "$FLAT" =~ ^[0-9]+$ ]] || FLAT=0

echo "$DNF $FLAT $((DNF + FLAT))"
