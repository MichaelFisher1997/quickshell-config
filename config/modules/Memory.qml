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
        const values = {};
        for (const line of text.split("\n")) {
            const index = line.indexOf(":");
            if (index < 0) continue;
            values[line.slice(0, index)] = parseFloat(line.slice(index + 1));
        }
        const total = values["MemTotal"] || 0;
        const available = values["MemAvailable"] || ((values["MemFree"] || 0) + (values["Buffers"] || 0) + (values["Cached"] || 0));
        if (total <= 0) return;
        root.usedGiB = (total - available) / 1048576;
        root.totalGiB = total / 1048576;
        root.percent = Math.round((total - available) / total * 100);
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.alt ? "󰍛 " + root.usedGiB.toFixed(2) + "/" + root.totalGiB.toFixed(2) + " GiB" : "󰍛 " + root.percent + "%"
        color: "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: root.alt = !root.alt

    Process {
        id: memProcess
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.update(this.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memProcess.running = true
    }
}
