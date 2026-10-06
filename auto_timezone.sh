#!/bin/bash
# auto_timezone.sh — Detecta la zona horaria por IP y actualiza el sistema si cambió.
# Sin zonas hardcodeadas: la zona siempre sale de la geolocalización de la IP.
# Fuentes: ipwho.is (https) con fallback a ip-api.com (http).
# Se ejecuta como SERVICIO DE SISTEMA (/usr/local/bin/auto_timezone.sh via
# auto-timezone.service): timedatectl set-timezone requiere root y un
# timer --user jamás tendría permiso (por eso no va en systemd/user).

log_msg() {
  logger -t auto-timezone "$1" 2>/dev/null || true
  echo "auto_timezone: $1"
}

detect_tz() {
  local tz
  tz="$(curl -s --max-time 8 "https://ipwho.is/" | jq -r '.timezone.id // empty' 2>/dev/null)"
  if [ -n "$tz" ]; then
    printf '%s' "$tz"
    return 0
  fi
  tz="$(curl -s --max-time 8 "http://ip-api.com/json/" | jq -r '.timezone // empty' 2>/dev/null)"
  if [ -n "$tz" ]; then
    printf '%s' "$tz"
    return 0
  fi
  return 1
}

tz="$(detect_tz)" || { log_msg "sin zona detectada (sin red)"; exit 0; }
current="$(readlink -f /etc/localtime 2>/dev/null | sed 's|^.*/zoneinfo/||')"
[ -n "$current" ] || { log_msg "localtime no legible"; exit 0; }

if [ "$current" = "$tz" ]; then
  log_msg "zona actual ($current) coincide; sin cambios"
  exit 0
fi

log_msg "$current -> $tz"
if timedatectl set-timezone "$tz" 2>/dev/null; then
  # Noctalia lee la zona del sistema en vivo: basta con avisar.
  # notify-send es best-effort (desde el servicio de sistema puede no haber sesión).
  notify-send "Zona horaria" "Actualizada a $tz" -i clock 2>/dev/null || true
  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    _uh="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    sudo -u "$SUDO_USER" env HOME="$_uh" notify-send "Zona horaria" "Actualizada a $tz" -i clock 2>/dev/null || true
  fi
else
  log_msg "fallo al setear zona a $tz"
  notify-send "Zona horaria" "Detecté $tz pero no pude aplicar el cambio" 2>/dev/null || true
fi