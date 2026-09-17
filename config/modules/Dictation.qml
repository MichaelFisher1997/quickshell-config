import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 6
    marginBottom: 6
    marginLeft: 0
    marginRight: 2

    padLeft: 10
    padRight: 10

    radius: 12
    minWidth: 24

    property string status: "idle"
    property string dictationText: ""
    property string dictationTooltip: ""

    readonly property color stateColor: {
        if (root.status === "recording" || root.status === "error")
            return root.thBad;
        if (root.status === "transcribing")
            return root.thWarn;
        if (root.status === "done")
            return root.thGood;
        return root.thAccent;
    }

    readonly property color stateBackground: {
        if (root.status === "recording" || root.status === "error")
            return root.thBadBg;
        if (root.status === "transcribing")
            return root.thWarnBg;
        if (root.status === "done")
            return root.thGoodBg;
        return root.thSurface;
    }

    color: root.stateBackground

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.dictationText
        color: root.stateColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        font.weight: Font.Black
    }

    mouseArea.onClicked: Quickshell.execDetached(["nix-tts", "toggle"])

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.dictationTooltip
    }

    Process {
        id: statusProcess
        command: ["nix-tts", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.status = data.class !== undefined ? data.class : "idle";
                    root.dictationText = data.text !== undefined ? data.text : "";
                    root.dictationTooltip = data.tooltip !== undefined ? data.tooltip : "";
                } catch (error) {
                    root.status = "idle";
                    root.dictationText = "";
                    root.dictationTooltip = "";
                }
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
