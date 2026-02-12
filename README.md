# hypr-steam-tv-switch

Auto-switches Hyprland to your TV when a controller is connected, launches Steam Gamepad UI, and restores your main monitor when Steam Big Picture exits.

Tested on Omarchy/Hyprland with systemd user services.

## What it does

- Detects a controller USB connection via udev
- Enables your TV monitor and focuses it
- Launches Steam in Gamepad UI (Big Picture)
- Watches for Big Picture exit
- Restores your main monitor and disables the TV

## Requirements

- Hyprland + `hyprctl`
- Steam installed
- systemd user services enabled
- `python3`
- `usbutils` (for `lsusb`)

## Install

```bash
git clone https://github.com/Lesaloon/hypr-steam-tv-switch.git
cd hypr-steam-tv-switch
./install.sh
```

Defaults are prefilled for 8BitDo Ultimate 2 Wireless (2dc8:310b).
You can also autodetect:

```bash
./install.sh --auto
```

## Find controller USB IDs

1) Unplug the controller
2) Run:

```bash
lsusb
```

3) Plug the controller in and run `lsusb` again
4) Look for the new line like:

```
Bus 003 Device 005: ID 045e:02e0 Microsoft Corp. Xbox One Controller
```

Use `045e` as vendor and `02e0` as product.

Alternative (more detailed):

```bash
udevadm info --attribute-walk --name=/dev/bus/usb/003/005
```

## Customize

Edit `bin/steam-tv-switch` and change the defaults at the top:

- `MAIN_MONITOR` (default `DP-3`)
- `TV_MONITOR` (default `HDMI-A-1`)
- `TV_MODE` (default `auto`)
- `TV_SCALE` (default `auto`)
- `STEAM_MODE` (default `gamepadui`)

If you want to change values without editing the script, create a systemd override:

```bash
systemctl --user edit steam-tv-switch.service
```

Then add:

```
[Service]
Environment=MAIN_MONITOR=DP-3
Environment=TV_MONITOR=HDMI-1-1
Environment=TV_MODE=4096x2160@120
Environment=STEAM_MODE=gamepadui
```

## Uninstall

```bash
systemctl --user disable --now steam-tv-switch.path
rm -f ~/.config/systemd/user/steam-tv-switch.service
rm -f ~/.config/systemd/user/steam-tv-switch.path
rm -f ~/.local/bin/steam-tv-switch
sudo rm -f /etc/udev/rules.d/99-steam-tv-switch.rules
sudo udevadm control --reload-rules
```

## Notes

- The udev rule matches USB controllers only. Bluetooth controllers need a different trigger.
- If Steam is already running, the script switches to Gamepad UI and still restores when Big Picture closes.
