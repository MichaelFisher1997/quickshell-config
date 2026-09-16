import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 5
    marginBottom: 5
    marginLeft: 5
    marginRight: 5

    padLeft: 5
    padRight: 5

    radius: 8

    property string device: "intel_backlight"
    property bool present: false
    property int brightness: 0
    property int maxBrightness: 0

    readonly property int percent: root.maxBrightness > 0 ? Math.round(root.brightness * 100 / root.maxBrightness) : 100

    readonly property var icons: [
        "", "", "", "", "",
        "", "", "", ""
    ]

    readonly property string icon: {
        const divisor = Math.max(1, Math.floor(100 / root.icons.length));
        const index = Math.min(root.icons.length - 1, Math.max(0, Math.floor(root.percent / divisor)));
        return root.icons[index];
    }

    visible: root.present

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.icon + " " + root.percent + "%"
        color: "#9ece6a"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    mouseArea.onWheel: (wheel) => {
        if (!root.present || root.maxBrightness <= 0) return;
        const step = Math.round(root.maxBrightness / 100);
        const delta = wheel.angleDelta.y > 0 ? step : -step;
        const target = Math.max(0, Math.min(root.maxBrightness, root.brightness + delta));
        root.brightness = target;
        Quickshell.execDetached([
            "sh",
            "-c",
            "printf '%s' " + target + " > /sys/class/backlight/" + root.device + "/brightness"
        ]);
        wheel.accepted = true;
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.percent + "%"
    }

    Process {
        id: statusProcess
        command: [
            "sh",
            "-c",
            "cat /sys/class/backlight/" + root.device + "/brightness"
            + " /sys/class/backlight/" + root.device + "/max_brightness 2>/dev/null || echo absent"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").map(line => line.trim()).filter(line => line.length > 0);
                if (lines.length < 2) {
                    root.present = false;
                    return;
                }
                root.present = true;
                root.brightness = parseInt(lines[0], 10);
                root.maxBrightness = parseInt(lines[1], 10);
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProcess.running = true
    }
}
