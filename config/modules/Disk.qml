import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 5
    marginBottom: 5
    marginLeft: 5
    marginRight: 5

    padLeft: 10
    padRight: 10

    radius: 16
    color: "#282828"

    property bool alt: false
    property real percent: 0
    property real usedGiB: 0
    property real totalGiB: 0

    function update(text) {
        const lines = text.trim().split("\n");
        const fields = lines[lines.length - 1].trim().split(/\s+/);
        const total = Number(fields[1]);
        const used = Number(fields[2]);
        if (!isFinite(total) || total <= 0) return;
        root.usedGiB = used / 1073741824;
        root.totalGiB = total / 1073741824;
        root.percent = Math.round(used / total * 100);
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.alt ? "󰋊 " + root.usedGiB.toFixed(2) + "/" + root.totalGiB.toFixed(2) + " GiB" : "󰋊 " + root.percent + "%"
        color: "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: root.alt = !root.alt

    Process {
        id: diskProcess
        command: ["df", "-B1", "/"]
        stdout: StdioCollector {
            onStreamFinished: root.update(this.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProcess.running = true
    }
}
