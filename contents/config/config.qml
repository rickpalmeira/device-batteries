import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: "Devices"
        icon: "battery"
        source: "configDevices.qml"
    }
}
