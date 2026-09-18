pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../components"

Pill {
    id: root

    padLeft: 6
    padRight: 6
    spacing: 8

    color: "transparent"

    // Rainbow workspace colors ported verbatim from the Eww bar
    // (eww.scss .ws-N classes). 5 and 9 share cyan, 10 is gray.
    function wsColor(id) {
        const colors = {
            1: "#e06c75",
            2: "#d19a66",
            3: "#e5c07b",
            4: "#98c379",
            5: "#56b6c2",
            6: "#61afef",
            7: "#c678dd",
            8: "#ff79c6",
            9: "#56b6c2",
            10: "#abb2bf"
        };
        return colors[id] !== undefined ? colors[id] : "#abb2bf";
    }

    Repeater {
        model: Hyprland.workspaces.values.slice().sort((a, b) => a.id - b.id)

        delegate: Item {
            id: button

            required property var modelData

            readonly property color accent: root.wsColor(button.modelData.id)

            Layout.fillHeight: true
            implicitWidth: label.implicitWidth + 8

            // Eww workspace buttons: no surface, hover washes white 6%;
            // only urgency keeps a tinted highlight.
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: button.modelData.urgent ? root.thUrgentSurface : hover.containsMouse ? root.thSurfaceHover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            // Hollow circle for occupied, filled circle for focused
            // (Eww workspace script: \uF10C / \uF111 in the workspace color).
            Text {
                id: label
                anchors.centerIn: parent
                text: button.modelData.urgent ? "\uF06A" : button.modelData.focused ? "\uF111" : "\uF10C"
                color: button.modelData.urgent ? root.thBad : button.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: button.modelData.focused || button.modelData.urgent ? 17 : 15
                font.bold: button.modelData.focused || button.modelData.urgent
                renderType: Text.NativeRendering

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                // Hyprland lua config mode re-evaluates raw dispatches as Lua,
                // so modelData.activate()'s plain "workspace <id>" dispatch is
                // rejected; send the Lua focus expression instead.
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${button.modelData.id}" })`);
                onWheel: wheel => {
                    Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wheel.angleDelta.y > 0 ? "e-1" : "e+1"}" })`);
                    wheel.accepted = true;
                }
            }
        }
    }
}
