import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    property var devices: []
    property date updatedAt
    readonly property string command: "python3 -I '" + Qt.resolvedUrl("../code/device-batteries").toString().replace(/^file:\/\//, "") + "'"

    function iconFor(kind) {
        switch (kind) {
        case "headset": return "audio-headset";
        case "keyboard": return "input-keyboard";
        case "mouse": return "input-mouse";
        case "gaming-input": return "input-gamepad";
        default: return "battery";
        }
    }

    function valueText(d) {
        if (d.state === "off") return "off";
        if (d.percent !== null) return d.percent + "%";
        return d.level || "?";
    }

    function isLow(d) {
        if (d.percent !== null) return d.percent <= 15;
        return d.level === "Low" || d.level === "Critical";
    }

    function valueColor(d) {
        if (d.state === "charging") return Kirigami.Theme.positiveTextColor;
        if (d.state !== "off" && isLow(d)) return Kirigami.Theme.negativeTextColor;
        return Kirigami.Theme.textColor;
    }

    function barValue(d) {
        if (d.percent !== null) return d.percent;
        switch (d.level) {
        case "Full": return 100;
        case "High": return 80;
        case "Normal": return 55;
        case "Low": return 15;
        case "Critical": return 5;
        default: return -1;
        }
    }

    function detailText(d) {
        if (d.state === "off") return "Turned off";
        if (d.state === "charging") return "Charging";
        if (d.state === "full") return "Fully charged";
        if (d.minutes_left) return Math.floor(d.minutes_left / 60) + " h " + (d.minutes_left % 60) + " min left";
        return "Discharging";
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            try {
                root.devices = JSON.parse(data["stdout"]);
            } catch (e) {
                root.devices = [];
            }
            root.updatedAt = new Date();
        }
    }

    function refresh() {
        executable.connectSource(root.command);
    }

    onExpandedChanged: if (root.expanded) root.refresh()

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    toolTipMainText: ""
    toolTipSubText: ""

    readonly property var lowest: {
        let best = null;
        for (const d of devices) {
            if (d.state === "off" || barValue(d) < 0) continue;
            if (best === null || barValue(d) < barValue(best)) best = d;
        }
        return best;
    }

    function trayIcon(d) {
        if (!d) return "battery-missing-symbolic";
        const step = String(Math.round(barValue(d) / 10) * 10).padStart(3, "0");
        return "battery-" + step + (d.state === "charging" ? "-charging" : "") + "-symbolic";
    }

    Plasmoid.icon: trayIcon(lowest)
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    compactRepresentation: MouseArea {
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: root.devices

            ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Separator {
                    visible: index > 0
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: root.iconFor(modelData.kind)
                        opacity: modelData.state === "off" ? 0.4 : 1
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        Layout.alignment: Qt.AlignTop
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true

                            PlasmaComponents3.Label {
                                text: modelData.name
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: root.valueText(modelData)
                                color: root.valueColor(modelData)
                                font.bold: true
                            }
                        }

                        PlasmaComponents3.ProgressBar {
                            visible: modelData.state !== "off" && root.barValue(modelData) >= 0
                            from: 0
                            to: 100
                            value: Math.max(0, root.barValue(modelData))
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.Label {
                            text: root.detailText(modelData)
                            opacity: 0.7
                            font: Kirigami.Theme.smallFont
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        PlasmaComponents3.Label {
            visible: root.devices.length === 0
            text: "No devices found"
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
        }

        Item {
            Layout.fillHeight: true
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: isNaN(root.updatedAt.getTime()) ? "Not updated yet" : "Updated " + Qt.formatTime(root.updatedAt, "hh:mm")
                opacity: 0.7
                font: Kirigami.Theme.smallFont
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: "Refresh"
                onClicked: root.refresh()
            }
        }
    }
}
