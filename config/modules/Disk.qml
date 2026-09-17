import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 6
    marginBottom: 6
    marginLeft: 2
    marginRight: 8

    padLeft: 10
    padRight: 10

    radius: 12
    color: "transparent"

    property bool alt: false
    property real percent: 0
    property real usedBytes: 0
    property real totalBytes: 0

    function powFormat(bytes) {
        const units = ["", "k", "M", "G", "T", "P"];
        let fraction = bytes;
        let pow = 0;
        while (pow + 1 < units.length && fraction / 1024 >= 1) {
            fraction /= 1024;
            pow++;
        }
        return fraction.toFixed(1) + units[pow] + (pow > 0 ? "i" : "") + "B";
    }

    function update(text) {
        const lines = text.trim().split("\n");
        const fields = lines[lines.length - 1].trim().split(/\s+/);
        const total = Number(fields[1]);
        const used = Number(fields[2]);
        const available = Number(fields[3]);
        if (!isFinite(total) || total <= 0)
            return;
        root.totalBytes = total;
        root.usedBytes = used;
        root.percent = Math.floor(available * 100 / total);
    }

    // Eww disk widget: sage text (eww.scss .disk_text).
    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.alt ? "󰋊 " + root.powFormat(root.usedBytes) + "/" + root.powFormat(root.totalBytes) + " GiB" : "󰋊 " + root.percent + "%"
        color: "#afbea2"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
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
