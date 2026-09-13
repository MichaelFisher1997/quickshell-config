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

    padLeft: 10
    padRight: 10

    radius: 16
    minWidth: 24

    property string status: "idle"
    property string dictationText: ""
    property string dictationTooltip: ""

    readonly property color stateColor: {
        if (root.status === "recording" || root.status === "error") return "#f7768e";
        if (root.status === "transcribing") return "#e0af68";
        if (root.status === "done") return "#9ece6a";
        return "#e5809e";
    }

    readonly property color stateBackground: {
        if (root.status === "recording" || root.status === "error") return "#29f7768e";
        if (root.status === "transcribing") return "#24e0af68";
        if (root.status === "done") return "#1f9ece6a";
        return "#282828";
    }

    color: root.stateBackground

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.dictationText
        color: root.stateColor
        font.family: "Iosevka"
        font.pixelSize: 14
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
