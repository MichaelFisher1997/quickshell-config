import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 0
    marginBottom: 0
    marginLeft: 0
    marginRight: 0

    padLeft: 0
    padRight: 0

    property string weatherText: ""
    property string weatherTooltip: ""

    readonly property string emojiPart: {
        const index = root.weatherText.indexOf(" ");
        return index > 0 ? root.weatherText.slice(0, index) : "";
    }

    readonly property string temperaturePart: {
        const index = root.weatherText.indexOf(" ");
        return index > 0 ? root.weatherText.slice(index + 1) : root.weatherText;
    }

    visible: root.weatherText.length > 0

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: root.emojiPart.length > 0
        text: root.emojiPart
        font.family: "Noto Color Emoji"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: (root.emojiPart.length > 0 ? " " : "") + root.temperaturePart + " °"
        color: "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        rich: true
        text: root.weatherTooltip
    }

    Process {
        id: weatherProcess
        command: ["wttrbar", "--location", "Ashton-Under-Lyne"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.weatherText = data.text !== undefined ? data.text : "";
                    root.weatherTooltip = data.tooltip !== undefined ? data.tooltip : "";
                } catch (error) {
                    root.weatherText = "";
                    root.weatherTooltip = "";
                }
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }
}
