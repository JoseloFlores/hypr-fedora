# Hyprland + Noctalia en Fedora Everything — listo para usar

> Tu escritorio Wayland, bonito y sin pelearte con la config.
> **Hyprland + Noctalia + Thunar** en una instalación limpia de **Fedora Everything** (mínima, sin DE previo), con barra, launcher, notificaciones, fondo automático y colores que combinan solos. Login texto con **tuigreet** en `tty1`.
> Port del proyecto `hypr` de Debian 13 a Fedora (`dnf`, RPM Fusion, COPR de respaldo).

![Fedora](https://img.shields.io/badge/Fedora-Everything-51A2DA?logo=fedora)
![Hyprland](https://img.shields.io/badge/Hyprland-dnf+COPR-00A8F4?logo=hyprland)
![Noctalia](https://img.shields.io/badge/Noctalia-v5-8DA68A)
![Portable](https://img.shields.io/badge/portable-%E2%9C%93-8DA68A)

Instalador **modular y seguro**: 12 pasitos re-ejecutables en `install-scripts/`, con presets, modo simulación (`dry-run`) y chequeo final.

## ✨ ¿Qué te llevas?

- **Hyprland** (repos Fedora; si falta, COPR `sdegler/hyprland`) con `hyprlock`, `hypridle`, `hyprpolkitagent` y `xdg-desktop-portal-hyprland`
- **Noctalia v5 como corazón del escritorio**: barra, launcher, notificaciones y centro de control. Se inicia sola con `exec-once = noctalia`. En Fedora 44+ viene de repos base (`dnf install noctalia`); en F42/F43 se usa el COPR `lionheartp/Hyprland` (`noctalia-git`)
- **Todo combina solo**: Noctalia saca la paleta de tu fondo y pinta GTK, bordes de Hyprland, Foot, wlogout, hyprlock y Neovim
- **Launcher único**: `SUPER + Espacio` (Noctalia)
- **Archivos y confort**: Thunar + automontaje (`udiskie`), keyring, polkit, Bluetooth (BlueZ), portapapeles persistente (`cliphist`)
- **Capturas y vídeo fáciles**: `grim + slurp | swappy` y `wf-recorder` con toggle, todo a `~/Pictures/Capturas`
- **Tu PC, detectado solo**: microcode (`microcode_ctl`), aceleración VA-API según tu GPU, firmware y brillo con `brightnessctl`. NVIDIA vía RPM Fusion `akmod-nvidia`
- **Login limpio**: `greetd + tuigreet` en texto (`tty1`), con `greeter.toml`-less (tuigreet recuerda tu última sesión)

## 📁 ¿Qué hay en este repo?

```
hypr-fedora/
├── install.sh               # instalador: --preset / --only / --skip / --dry-run / --check
├── preset.example.sh        # todo ON (uso normal)
├── preset.minimal.sh        # solo dots, para probar sin tocar el sistema
├── dry-run-build.sh         # simula los 12 módulos (PASS/FAIL por módulo)
├── uninstall-lite.sh        # revierte dots + timer (--full toca greetd/NM/udev)
├── install-scripts/         # un script por fase, re-ejecutables
│   ├── Global_functions.sh  # logs, dnf con reintentos, dry-run
│   ├── 10-repos.sh / 20-drivers.sh / 30-base.sh / 40-hypr.sh
│   ├── 50-fonts.sh / 60-greetd.sh / 70-dots.sh / 71-noctalia.sh
│   └── 80-pam-portals.sh / 90-services.sh / 95-grub.sh / 99-final-check.sh
├── hyprland.conf            # tu escritorio: atajos, reglas, autostart
├── noctalia/                # theming y shell
│   ├── templates/           # foot.ini, hyprlock.conf, wlogout.css, matugen-template.lua
│   ├── hooks/               # foot-apply.sh, sync-lock-wallpaper.sh
│   ├── capture-apply.sh     # plugin foto+video jo/capture (idempotente)
│   ├── updates-apply.sh     # plugin jo/updates-fedora (dnf+flatpak)
│   └── plugins/capture/     # plugin local foto+video (widget+service wf-recorder)
│   └── plugins/updates-fedora/  # contador dnf+flatpak (check-updates.sh/upgrade.sh)
│   └── plugins/updates-debian/  # legado del port Debian (no se usa aquí)
├── foot.ini / nvim/ / wlogout/ / systemd/user/  # igual que en Debian
└── NOCTALIA_COMANDOS.md     # chuleta de Noctalia
```

## ⚙️ Antes de empezar

- Fedora Everything mínima, sin entorno gráfico previo (sin `gdm`/`sddm`)
- Internet a `fedoraproject.org`, `rpmfusion.org`, `copr.fedorainfracloud.org`, `sudo` a mano
- El instalador añade **RPM Fusion free+nonfree** y, solo si hace falta, los COPR `sdegler/hyprland` (Hyprland) y `lionheartp/Hyprland` (Noctalia en F42/F43)

## 🚀 Instalación en 2 pasos

```bash
git clone <este-repo> hypr-fedora
cd hypr-fedora
sudo ./install.sh   # logs en ./install.log + Install-Logs/
sudo reboot
```

¿Quieres ir por partes o probar sin miedo?

```bash
sudo ./install.sh --preset preset.example.sh      # lo normal: todo
sudo ./install.sh --only 70-dots,99-final-check   # solo reponer mis configs + verificar
./install.sh --dry-run --only 70-dots             # simular sin root ni cambios
./install.sh --check                              # ver los módulos sin ejecutar nada
./dry-run-build.sh                                # chequeo PASS/FAIL de los 12 módulos
sudo ./install-scripts/70-dots.sh                 # un módulo suelto, cualquiera vale
```

| Módulo | ¿Qué hace por ti? |
|---|---|
| `10-repos` | RPM Fusion free+nonfree + COPR `sdegler/hyprland` solo si `hyprland` no está en base |
| `20-drivers` | `microcode_ctl`, Mesa/VA-API según tu GPU, `linux-firmware`+`sof-firmware`, NVIDIA con `akmod-nvidia` |
| `30-base` | Apps del día a día: Thunar, `imv` + `mpv`, Firefox, Foot+Alacritty, capturas, Bluetooth, sonido… |
| `40-hypr` | Hyprland + lock + idle + polkit + portales + greetd/tuigreet/uwsm (con reintento vía COPR) |
| `50-fonts` | Meslo Nerd Font + símbolos, en tu `~/.local/share/fonts` |
| `60-greetd` | Login texto tuigreet en `tty1` + usuario `greeter` + override `Restart=always` |
| `70-dots` | Copia mis configs a tu `~/.config` (sin pisar tu Noctalia/nvim si ya existen) |
| `71-noctalia` | Instala Noctalia (`dnf install noctalia`, si no COPR `lionheartp/Hyprland`) + plugin foto+video `jo/capture` + contador `jo/updates-fedora` |
| `80-pam-portals` | Keyring desbloqueado al entrar (`gnome-keyring-pam`) + diálogos de archivo GTK |
| `90-services` | Red con NetworkManager, Bluetooth y greetd activados |
| `95-grub` | Regenera GRUB con `grub2-mkconfig` |
| `99-final-check` | Te dice si quedó `COMPLETADA` o falta algo (`rpm -q`) |

Detalles del lote base (`30-base`, todo desactivable por preset):

- `thunar thunar-archive-plugin thunar-volman xarchiver tumbler ffmpegthumbnailer` (`INSTALL_THUNAR=OFF` lo salta) + `xdg-user-dirs-update --force`
- `imv mpv` (`INSTALL_MEDIA=OFF` lo salta), `firefox` (`INSTALL_FIREFOX=OFF` lo salta), `thunderbird` solo si `INSTALL_THUNDERBIRD=ON`
- `foot alacritty grim slurp swappy wf-recorder`, `wl-clipboard cliphist brightnessctl playerctl`, `nwg-look` (best-effort), `mako` (solo para que Bluetooth no arrastre GNOME; nunca se muestra, las notificaciones las da Noctalia)

> Al entrar, verifica: `hyprland --verify-config` → `config ok` y `noctalia config validate` → `✓ Config is valid`.

### Desinstalar sin drama

```bash
sudo ./uninstall-lite.sh          # quita mis dots (con backup fechado) + timer
sudo ./uninstall-lite.sh --full   # además apaga greetd y limpia overrides míos
```

No borra programas (si quieres: `sudo dnf autoremove hyprland noctalia`).

## 🖥️ Tu día a día

Igual que en Debian (ver `hyprland.conf` y `NOCTALIA_COMANDOS.md`): `SUPER+Return` terminal, `SUPER+Espacio` launcher, `SUPER+X` Thunar, `Print` capturas, `SHIFT+Print`/`CTRL+Print` grabar, etc.

### Zona horaria que viaja contigo

```bash
systemctl status auto-timezone.timer
sudo systemctl enable --now auto-timezone.timer   # si no estaba activo
```
El timer es **de sistema** (`/etc/systemd/system/auto-timezone.timer` → `/usr/local/bin/auto_timezone.sh`): `timedatectl set-timezone` requiere root y un timer `--user` jamás tendría permiso.

## 🔧 Hazlo tuyo

- **Monitores**: arranca con `monitor=,preferred,auto,1`. Para dual-monitor mira `hyprctl monitors`. La barra de Noctalia sale solo en la laptop (`noctalia/bar-monitors.toml`, ajusta el `match` a tu conector como `eDP-1`).
- **Rutas portables**: todo usa `$HOME`/`~`.
- **Presets**: copia `preset.example.sh`, pon `OFF` a lo que no quieras y lanza con `--preset`.
- **GPU NVIDIA**: se detecta sola (`NVIDIA_MODE=auto`; `OFF` la ignora). Con Secure Boot activado, firma el módulo: `sudo mokutil --import /etc/pki/akmods/certs/public_key.der` y verifica con `mokutil --list-enrolled`.

## 🩹 Si algo se tuerce

**El brillo dice `Permission denied`**
> ```bash
> sudo usermod -aG video,input $USER
> # la regla /etc/udev/rules.d/90-backlight.rules ya la pone 30-base; recarga:
> sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=backlight --action=add
> ```
> Entra de nuevo para que los grupos apliquen.

**Hyprland no aparece en tuigreet / COPR roto por Qt**
> El COPR `sdegler/hyprland` es el fork mantenido (solopasha se rompió con Qt 6.10 en F43). Si `dnf` se queja de `libQt6Core...Qt_6.9_PRIVATE_API`, quita el COPR viejo y pon el nuevo:
> ```bash
> sudo dnf copr remove -y solopasha/hyprland
> sudo dnf copr enable -y sdegler/hyprland
> sudo dnf clean all && sudo dnf upgrade --refresh
> ```

**Noctalia no está en repos (F42/F43)**
> Es normal: el paquete oficial `noctalia` está desde F44. El instalador usa el COPR `lionheartp/Hyprland` (`noctalia-git`) automáticamente. Reintento manual:
> ```bash
> sudo ./install.sh --only 71-noctalia,99-final-check
> ```

**Un módulo falló / quiero repetir solo una parte**
> ```bash
> ./dry-run-build.sh --only 70-dots,99-final-check
> sudo ./install.sh --only 70-dots,99-final-check
> cat Install-Logs/70-dots-*.log
> ```

## 📜 Licencia y diferencias con Debian

Dotfiles bajo MIT (ver `LICENSE`). Diferencias principales del port:

| Debian `hypr` | Fedora `hypr-fedora` |
|---|---|
| `apt-get` + backports | `dnf5` + RPM Fusion (+ COPR respaldo) |
| `firefox-esr`, `mako-notifier`, `fonts-jetbrains-mono` | `firefox`, `mako`, `jetbrains-mono-fonts` |
| `intel-microcode`, `firmware-linux-nonfree` | `microcode_ctl`, `linux-firmware`+`sof-firmware` |
| NVIDIA `.run`/debian | `akmod-nvidia` RPM Fusion |
| `noctalia-greeter` gráfico (+tuigreet fallback) | solo `tuigreet` |
| usuario login `_greetd` | usuario login `greeter` |
| `pam-auth-update`, `update-grub`, `locale-gen` | parche PAM directo, `grub2-mkconfig`, `glibc-langpack-es` |
| plugin `jo/updates-debian` (apt) | plugin `jo/updates-fedora` (dnf) |
