import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

Pill {
    id: root

    marginTop: 4
    marginBottom: 4
    marginLeft: 0
    marginRight: 8

    padLeft: 8
    padRight: 8

    radius: 8
    color: root.thAccentSurface

    // Eww app launcher button: apps glyph in red-pink on the sunken
    // chip surface (eww.scss .launcher_icon).
    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "\uF003B"
        color: "#e5809e"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            Quickshell.execDetached(["rofi", "-show", "drun"]);
        } else if (mouse.button === Qt.RightButton) {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/rofi/run.sh"]);
        }
    }
}
