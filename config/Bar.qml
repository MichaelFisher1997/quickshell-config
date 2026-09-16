import QtQuick
import Quickshell
import "modules"

PanelWindow {
    id: root

    required property var modelData
    screen: root.modelData

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 20
        left: 20
        right: 20
    }

    implicitHeight: 38
    color: "transparent"
    readonly property real cornerRadius: Math.min(24, root.height / 2)

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: "#80000000"
    }

    Rectangle {
        x: root.cornerRadius
        width: root.width - root.cornerRadius * 2
        anchors.bottom: parent.bottom
        height: 1
        color: "#bf282828"
    }

    Row {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        Launcher {}
        Workspaces {}
        Backlight {}
        Battery {}
        PlayerControls {}
        PlayerLabel {}
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
        }

        Weather {}
        Clock {}
        Volume {}
    }

    Row {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        Dictation {}
        Cpu {}
        Memory {}
        Disk {}
        Tray {}
    }
}
