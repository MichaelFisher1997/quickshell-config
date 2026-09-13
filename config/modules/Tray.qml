import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"

Pill {
    id: root

    marginTop: 0
    marginBottom: 0
    marginLeft: 10
    marginRight: 0

    padLeft: 13
    padRight: 15

    radius: 24
    color: "#282828"
    spacing: 5

    readonly property int activeCount: SystemTray.items.values.filter(item => item.status !== Status.Passive).length

    visible: root.activeCount > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            visible: trayItem.modelData.status !== Status.Passive
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 16
            implicitHeight: 16

            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
                mipmap: true
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) trayItem.modelData.activate();
                    else trayItem.modelData.display(QsWindow.window, mouse.x, mouse.y);
                }
            }

            Tooltip {
                target: trayItem
                shown: mouseArea.containsMouse
                text: trayItem.modelData.tooltipTitle + (trayItem.modelData.tooltipDescription.length > 0 ? "\n" + trayItem.modelData.tooltipDescription : "")
            }
        }
    }
}
