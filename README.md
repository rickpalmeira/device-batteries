# Device Batteries

A KDE Plasma 6 system tray widget that shows the battery levels of wireless peripherals: headsets, keyboards and mice.

The tray icon is a battery indicator that follows the device with the lowest charge. Click it to open a panel with each device's level, a progress bar and its status (discharging, charging, time left when the device reports it).

## Supported devices

It was built for and tested with:

- **Logitech G535** headset, read through [`headsetcontrol`](https://github.com/Sapd/HeadsetControl)
- **Logitech MX Keys** keyboard and **G703 LIGHTSPEED** mouse, read from the kernel's `hid-logitech-hidpp` driver (`/sys/class/power_supply/hidpp_battery_*`)

Other headsets supported by `headsetcontrol` and other Logitech HID++ devices should work too, but have not been tested.

When the kernel only reports a coarse level for a Logitech device (MX Keys reports "Normal", "Low" and so on), the widget asks the device for its percentage directly over its `/dev/hidraw*` node, using HID++ feature 0x1000. If that fails, it shows the kernel's level.

## Requirements

- KDE Plasma 6
- Python 3
- `upower`
- `headsetcontrol`, for headsets
- Read/write access to the device's `/dev/hidraw*` node for the direct keyboard query. Desktop sessions usually grant this through a `uaccess` ACL.

## Install

```sh
./install.sh
```

This copies the widget into `~/.local/share/plasma/plasmoids/local.devicebatteries`, replacing any installed version, and restarts plasmashell. Then add **Device Batteries** to the system tray from the tray's settings (System Tray Settings → Entries) if it is not shown already.

Other options:

- `./install.sh -s` symlinks this folder instead of copying it, so edits here apply after the next plasmashell restart.
- `./install.sh -r` uninstalls the widget.

## Settings

Right-click the tray icon and choose **Configure Device Batteries…**, or click the settings button in the panel's header.

The **General** page sets the panel's order: **Default** (as the devices are found), **Name** or **Battery**, ascending or descending. With **Battery**, devices without a reading and turned-off devices always go last. **Group by status** puts charging devices first and uses the chosen order within each group.

The **Devices** page lists each device with a field for its display name. Leave a field empty to use the device's own name. Renamed devices that are not connected stay in the list, so their names survive a disconnect.

## Development

- `contents/ui/main.qml`: the tray icon and the panel. It reloads the readings every 60 seconds and each time the panel opens.
- `contents/ui/configGeneral.qml`, `contents/ui/configDevices.qml` and `contents/config/`: the settings pages and their stored options (`sortBy`, `sortDescending`, `groupByStatus`, and `deviceNames`, a JSON map from each device's own name to its display name).
- `contents/code/device-batteries`: a Python script that prints the devices as JSON (`name`, `kind`, `percent`, `level`, `state`, `minutes_left`).

Run the data script on its own:

```sh
python3 -I contents/code/device-batteries
```

Lint the QML:

```sh
qmllint -I /usr/lib/qt6/qml contents/ui/main.qml
```
