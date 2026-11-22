# Device Batteries

Plasma 6 widget (system tray entry) that shows the battery of the user's wireless devices: Logitech G535 headset, MX Keys keyboard, G703 LS mouse.

## Layout

- `metadata.json`: package metadata. `X-Plasma-NotificationArea` makes it a system tray entry.
- `contents/ui/main.qml`: UI. Runs the data script every 60 s through the Plasma5Support `executable` engine.
- `contents/code/device-batteries`: Python script that prints a JSON list of devices (`name`, `kind`, `percent`, `level`, `state`, `minutes_left`).

## Install and reload

- `./install.sh` copies the package into `~/.local/share/plasma/plasmoids/local.devicebatteries`, replacing any installed version, then restarts plasmashell. `-s` symlinks this folder instead (current setup), `-r` uninstalls.
- Edits apply after a Plasma restart. Metadata changes (tray keys, id) only load on restart.
- plasmashell's unit allows 3 starts per minute; `install.sh` runs `systemctl --user reset-failed` before restarting so repeated runs don't leave the desktop without a panel.
- Lint QML: `qmllint -I /usr/lib/qt6/qml contents/ui/main.qml`.
- Run the data script alone: `python3 -I contents/code/device-batteries`.

## Data sources and known traps

- Headset: `headsetcontrol -b -o json` (package `headsetcontrol`). Its percentage is accurate.
- The kernel's `hid-logitech-hidpp` driver can read the G535 (HID++ 4.2, feature 0x1F20), but its voltage table is for the G935 and is wrong for the G535: it showed 46% while the headset was at 4%. The script ignores UPower headsets when `headsetcontrol` finds one. A udev rule that forced this binding was removed on 2026-11-19.
- Keyboard and mouse: kernel `/sys/class/power_supply/hidpp_battery_*`, with the kind (`keyboard`, `mouse`) taken from `upower --dump`.
- MX Keys exposes only `capacity_level` (HID++ feature 0x1000, no percentage). UPower's percentage for it is marked "should be ignored". After a reconnect the kernel can report `Unknown` until the next battery event; the keyboard itself answered 5% to a direct 0x1000 query on its hidraw (device index 1 on the Unifying receiver). When the kernel has no `capacity`, the script sends that query itself and prefers its percentage over `capacity_level`: HID++ short report on the battery's own hidraw (`/sys/class/power_supply/hidpp_battery_*/device/hidraw/`), root feature lookup for 0x1000, then function 0. The user has read/write access to these hidraw nodes through a uaccess ACL.
- The 8BitDo Pro 3 controller (2.4G receiver, XInput mode, `xpad` driver) has no readable battery on Linux. Bluetooth would work, but that mode is used by the user's other consoles.
- Never create virtual HID devices through `/dev/uhid` here: a uhid battery bridge was the prime suspect in a full system freeze on 2026-11-17.
