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
    property real usage: 0
    property real frequency: 0
    property real lastTotal: 0
    property real lastIdle: 0

    function updateUsage(text) {
        const line = text.split("\n")[0].trim();
        if (!line.startsWith("cpu ")) return;
        const fields = line.split(/\s+/).slice(1).map(Number);
        const idle = fields[3] + (fields[4] || 0);
        let total = 0;
        for (let i = 0; i < 8 && i < fields.length; i++) total += fields[i];
        if (root.lastTotal > 0 && total > root.lastTotal) {
            const totalDelta = total - root.lastTotal;
            const idleDelta = idle - root.lastIdle;
            root.usage = Math.max(0, Math.min(100, (1 - idleDelta / totalDelta) * 100));
        }
        root.lastTotal = total;
        root.lastIdle = idle;
    }

    function updateFrequency(text) {
        const matches = text.match(/^cpu MHz\s*:\s*[\d.]+/gm);
        if (!matches || matches.length === 0) return;
        let sum = 0;
        for (const match of matches) sum += parseFloat(match.split(":")[1]);
        root.frequency = sum / matches.length / 1000;
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.alt ? "󰻠 " + root.frequency.toFixed(2) + " GHz" : "󰻠 " + Math.round(root.usage) + "%"
        color: "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: root.alt = !root.alt

    Process {
        id: statProcess
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: root.updateUsage(this.text)
        }
    }

    Process {
        id: freqProcess
        command: ["cat", "/proc/cpuinfo"]
        stdout: StdioCollector {
            onStreamFinished: root.updateFrequency(this.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statProcess.running = true;
            freqProcess.running = true;
        }
    }
}
