import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

Pill {
    id: root

    marginTop: 0
    marginBottom: 0
    marginLeft: 0
    marginRight: 0

    padLeft: 13
    padRight: 20

    radius: 24
    color: "#282828"

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "󰈸"
        color: "#e5809e"
        font.family: "Iosevka"
        font.pixelSize: 20
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            Quickshell.execDetached(["rofi", "-show", "drun"]);
        } else if (mouse.button === Qt.RightButton) {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/rofi/run.sh"]);
        }
    }
}
