import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: page

    property string cfg_deviceNames
    property string cfg_deviceNamesDefault

    property var connected: []
    property bool loaded: false
    readonly property string command: "python3 -I '" + Qt.resolvedUrl("../code/device-batteries").toString().replace(/^file:\/\//, "") + "'"

    readonly property var names: {
        try {
            const parsed = JSON.parse(cfg_deviceNames);
            return parsed && typeof parsed === "object" ? parsed : {};
        } catch (e) {
            return {};
        }
    }

    property var entries: []

    function rename(original, value) {
        const updated = Object.assign({}, names);
        if (value.trim() === "") delete updated[original];
        else updated[original] = value.trim();
        cfg_deviceNames = JSON.stringify(updated);
    }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: [page.command]
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            let found = [];
            try {
                found = JSON.parse(data["stdout"]).map(d => d.name);
            } catch (e) {
            }
            const list = found.slice();
            for (const key of Object.keys(page.names)) {
                if (!list.includes(key)) list.push(key);
            }
            page.connected = found;
            page.entries = list;
            page.loaded = true;
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Repeater {
                model: page.entries

                RowLayout {
                    required property string modelData
                    Kirigami.FormData.label: modelData + ":"

                    QQC2.TextField {
                        text: page.names[modelData] ?? ""
                        placeholderText: modelData
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                        onTextEdited: page.rename(modelData, text)
                    }

                    QQC2.Label {
                        visible: !page.connected.includes(modelData)
                        text: "Not connected"
                        opacity: 0.7
                    }
                }
            }
        }

        QQC2.Label {
            visible: !page.loaded || page.entries.length === 0
            text: page.loaded ? "No devices found" : "Looking for devices…"
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: page.entries.length > 0
            text: "Leave a field empty to use the device's own name."
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
