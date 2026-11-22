import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_sortBy
    property string cfg_sortByDefault
    property bool cfg_sortDescending
    property bool cfg_sortDescendingDefault
    property bool cfg_groupByStatus
    property bool cfg_groupByStatusDefault

    readonly property var sortOptions: [
        { value: "default", text: "Default" },
        { value: "name", text: "Name" },
        { value: "battery", text: "Battery" }
    ]

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: "Order by:"

            QQC2.ComboBox {
                model: page.sortOptions
                textRole: "text"
                valueRole: "value"
                currentIndex: Math.max(0, page.sortOptions.findIndex(o => o.value === page.cfg_sortBy))
                onActivated: page.cfg_sortBy = currentValue
            }

            QQC2.ComboBox {
                enabled: page.cfg_sortBy !== "default"
                model: ["Ascending", "Descending"]
                currentIndex: page.cfg_sortDescending ? 1 : 0
                onActivated: page.cfg_sortDescending = currentIndex === 1
            }
        }

        QQC2.CheckBox {
            text: "Group by status"
            checked: page.cfg_groupByStatus
            onToggled: page.cfg_groupByStatus = checked
        }

        QQC2.Label {
            text: "Charging devices go first; the order above sorts within each group."
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }
    }
}
