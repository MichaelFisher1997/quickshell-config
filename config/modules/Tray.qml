import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"

Pill {
    id: root

    marginTop: 4
    marginBottom: 4
    marginLeft: 0
    marginRight: 0

    padLeft: 12
    padRight: 12

    radius: 14
    color: "transparent"
    spacing: 6

    readonly property int activeCount: SystemTray.items.values.filter(item => item.status !== Status.Passive).length

    visible: root.activeCount > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            visible: trayItem.modelData.status !== Status.Passive
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 24
            implicitHeight: 28

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: trayItem.modelData.icon
                mipmap: true
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
                // The anchor maps the icon into its window's coordinates,
                // including the bar's right alignment and monitor position.
                anchor.item: trayItem
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                        if (trayItem.modelData.hasMenu)
                            menuAnchor.open();
                    } else {
                        trayItem.modelData.activate();
                    }
                }
                onWheel: wheel => {
                    if (wheel.angleDelta.y !== 0)
                        trayItem.modelData.scroll(wheel.angleDelta.y, false);
                    if (wheel.angleDelta.x !== 0)
                        trayItem.modelData.scroll(wheel.angleDelta.x, true);
                }
            }

            Tooltip {
                target: trayItem
                shown: mouseArea.containsMouse && !menuAnchor.visible
                text: trayItem.modelData.tooltipTitle + (trayItem.modelData.tooltipDescription.length > 0 ? "\n" + trayItem.modelData.tooltipDescription : "")
            }
        }
    }
}
