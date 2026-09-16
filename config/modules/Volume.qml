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

    property bool muted: false
    property int volume: 0
    property string description: ""

    readonly property string icon: root.volume < 33 ? "󰕿" : root.volume < 67 ? "󰖀" : "󰕾"

    function refresh() {
        if (!statusProcess.running) statusProcess.running = true;
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.muted ? "󰝟" : root.icon + " " + root.volume + "%"
        color: root.muted ? "#ff000d" : "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            muteProcess.running = true;
        } else if (mouse.button === Qt.RightButton) {
            Quickshell.execDetached(["pavucontrol"]);
        }
    }

    mouseArea.onWheel: (wheel) => {
        if (wheel.angleDelta.y > 0) upProcess.running = true;
        else downProcess.running = true;
        wheel.accepted = true;
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.description.length > 0 ? root.description + "\n" + (root.muted ? "Muted" : root.volume + "%") : ""
    }

    Process {
        id: statusProcess
        command: ["sh", "-c", "pamixer --get-volume-human && wpctl inspect @DEFAULT_AUDIO_SINK@ || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.split("\n")) {
                    const trimmed = line.trim();
                    if (trimmed === "muted") {
                        root.muted = true;
                    } else if (trimmed.endsWith("%")) {
                        root.muted = false;
                        root.volume = parseInt(trimmed, 10);
                    } else if (trimmed.indexOf("node.description = ") >= 0) {
                        root.description = trimmed.slice(trimmed.indexOf("node.description = ") + 19).replace(/"/g, "");
                    }
                }
            }
        }
    }

    Process {
        id: muteProcess
        command: ["pamixer", "--toggle-mute"]
        onRunningChanged: if (!running) root.refresh()
    }

    Process {
        id: upProcess
        command: ["pamixer", "--increase", "5"]
        onRunningChanged: if (!running) root.refresh()
    }

    Process {
        id: downProcess
        command: ["pamixer", "--decrease", "5"]
        onRunningChanged: if (!running) root.refresh()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
