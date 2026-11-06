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

    // Bundled artwork avoids malformed glyphs and font-dependent fallbacks.
    Image {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        source: Qt.resolvedUrl("../assets/apps.svg")
        fillMode: Image.PreserveAspectFit
    }

    mouseArea.onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            Quickshell.execDetached(["rofi", "-show", "drun"]);
        } else if (mouse.button === Qt.RightButton) {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/rofi/run.sh"]);
        }
    }
}
