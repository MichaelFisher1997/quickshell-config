import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

Pill {
    id: root

    signal drawerRequested

    marginTop: 4
    marginBottom: 4
    marginLeft: 2
    marginRight: 2

    padLeft: 13
    padRight: 15
    spacing: 4

    radius: 14
    color: "transparent"

    readonly property alias currentDate: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Eww clock: bold cool-gray time, lilac date, faint separator
    // (eww.scss .clock_time_class / .clock_date_class / .separ).
    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: root.thText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        renderType: Text.NativeRendering
        font.bold: true
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "|"
        color: root.thFaint
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        renderType: Text.NativeRendering
        font.bold: true
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Qt.formatDateTime(clock.date, "dd/MM/yy")
        color: root.thAccentStrong
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            root.drawerRequested();
    }
}
