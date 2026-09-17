import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"

Pill {
    id: root

    signal drawerRequested

    marginTop: 6
    marginBottom: 6
    marginLeft: 2
    marginRight: 0

    padLeft: 5
    padRight: 5

    radius: 12
    color: "transparent"

    property bool muted: false
    property int volume: 0
    property string description: ""
    property bool available: false
    property string commandError: ""
    property var pendingCommands: []
    property bool refreshPending: false

    readonly property string icon: root.volume < 33 ? "󰕿" : root.volume < 67 ? "󰖀" : "󰕾"

    function refresh() {
        if (statusProcess.running)
            root.refreshPending = true;
        else
            statusProcess.running = true;
    }

    function setVolume(value) {
        if (isFinite(value))
            root.enqueue(["pamixer", "--set-volume", String(Math.round(Math.max(0, Math.min(100, value))))]);
    }

    function toggleMute() {
        root.enqueue(["pamixer", "--toggle-mute"]);
    }

    // Serialize slider, wheel and mute commands so the final requested value wins.
    function enqueue(command) {
        root.pendingCommands.push(command);
        root.runNextCommand();
    }

    function runNextCommand() {
        if (commandProcess.running || root.pendingCommands.length === 0)
            return;
        commandProcess.command = root.pendingCommands.shift();
        commandProcess.running = true;
    }

    // Eww volume widget: green when normal, red when muted
    // (eww.scss .volume-normal / .volume-muted).
    Text {
        Layout.alignment: Qt.AlignVCenter
        text: !root.available ? "Sound" : root.muted ? "󰝟" : root.icon + " " + root.volume + "%"
        color: root.muted ? root.thBad : root.thGood
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            root.drawerRequested();
        } else if (mouse.button === Qt.MiddleButton) {
            root.toggleMute();
        } else if (mouse.button === Qt.RightButton) {
            Quickshell.execDetached(["pavucontrol"]);
        }
    }

    mouseArea.onWheel: wheel => {
        if (wheel.angleDelta.y > 0)
            root.enqueue(["pamixer", "--increase", "5"]);
        else if (wheel.angleDelta.y < 0)
            root.enqueue(["pamixer", "--decrease", "5"]);
        wheel.accepted = true;
    }

    Process {
        id: statusProcess
        command: ["sh", "-c", "volume=$(pamixer --get-volume) || exit 1; mute=$(pamixer --get-mute) || exit 1; printf '%s\\n%s\\n' \"$volume\" \"$mute\"; wpctl inspect @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                root.available = /^\d+$/.test(lines[0]) && (lines[1] === "true" || lines[1] === "false");
                root.description = "";
                if (root.available) {
                    root.volume = Number(lines[0]);
                    root.muted = lines[1] === "true";
                    const match = /node\.description\s*=\s*"([^"]+)"/.exec(this.text);
                    if (match)
                        root.description = match[1];
                }
            }
        }
        onExited: {
            if (root.refreshPending) {
                root.refreshPending = false;
                Qt.callLater(root.refresh);
            }
        }
    }

    Process {
        id: commandProcess
        onExited: (exitCode, exitStatus) => {
            root.commandError = exitCode === 0 && exitStatus === 0 ? "" : "Volume command failed";
            root.refresh();
            Qt.callLater(root.runNextCommand);
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
