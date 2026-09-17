import QtQuick
import "../components"

// Performance page of the drawer: three circular gauges driven directly
// by the CPU, Memory and Disk bar modules (single set of pollers). The
// labels are honest about what is measured: aggregate CPU usage and
// average clock, used memory, and used space on the root filesystem.
// There is no GPU telemetry in this config, so no GPU gauge is shown.
Item {
    id: root

    property string tabId: "performance"
    required property var cpuModule
    required property var memoryModule
    required property var diskModule

    // Theme literals kept in sync with the shared palette in Pill.qml
    // (Eww metric colors: CPU lilac, memory peach, disk sage).
    readonly property color thMuted: "#6b7280"
    readonly property color thText: "#bfc9db"

    readonly property real diskUsedPercent: root.diskModule.totalBytes > 0 ? root.diskModule.usedBytes / root.diskModule.totalBytes * 100 : 0

    // Shrink the gauges on narrow monitors instead of overflowing.
    readonly property int gaugeSize: Math.max(32, Math.min(148, Math.floor((root.width - 80) / 3) - 24))

    implicitHeight: note.y + note.implicitHeight + 24

    Row {
        id: gauges

        anchors.horizontalCenter: parent.horizontalCenter
        y: 22
        spacing: root.width > 560 ? 30 : 12

        Gauge {
            dialSize: root.gaugeSize
            value: root.cpuModule.usage
            valueColor: "#d7beda"
            caption: "CPU usage"
            detail: root.cpuModule.frequency > 0 ? root.cpuModule.frequency.toFixed(2) + " GHz avg clock" : "clock not sampled"
        }

        Gauge {
            dialSize: root.gaugeSize
            value: root.memoryModule.percent
            valueColor: "#e0b089"
            caption: "Memory used"
            detail: root.memoryModule.usedGiB.toFixed(1) + " / " + root.memoryModule.totalGiB.toFixed(1) + " GiB"
        }

        Gauge {
            dialSize: root.gaugeSize
            value: root.diskUsedPercent
            valueColor: "#afbea2"
            caption: "Disk used  /"
            detail: root.diskModule.powFormat(root.diskModule.usedBytes) + " / " + root.diskModule.powFormat(root.diskModule.totalBytes)
        }
    }

    Text {
        id: note

        anchors.horizontalCenter: parent.horizontalCenter
        y: gauges.y + gauges.height + 14
        text: "live from /proc/stat, /proc/cpuinfo, /proc/meminfo and df — sampled every 5 s"
        color: root.thMuted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        renderType: Text.NativeRendering
    }
}
