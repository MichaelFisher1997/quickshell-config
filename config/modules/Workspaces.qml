import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../components"

Pill {
    id: root

    padLeft: 5
    padRight: 5

    color: "#282828"

    Repeater {
        model: Hyprland.workspaces.values.slice().sort((a, b) => a.id - b.id)

        delegate: Item {
            id: button

            required property var modelData

            Layout.fillHeight: true
            implicitWidth: label.implicitWidth + 10

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: hover.containsMouse ? "#e6b9c6" : "transparent"
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: button.modelData.urgent ? "" : button.modelData.focused ? "" : "󰧞"
                color: hover.containsMouse ? "#000000" : button.modelData.focused ? "#f4d9e1" : "#928374"
                font.family: "Iosevka"
                font.pixelSize: 14
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: button.modelData.activate()
                onWheel: (wheel) => {
                    Hyprland.dispatch("workspace " + (wheel.angleDelta.y > 0 ? "-1" : "+1"));
                    wheel.accepted = true;
                }
            }
        }
    }
}
