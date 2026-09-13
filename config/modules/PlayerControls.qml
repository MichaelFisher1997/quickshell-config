import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../components"

Pill {
    id: root

    marginTop: 5
    marginBottom: 5
    marginLeft: 0
    marginRight: 0

    padLeft: 15
    padRight: 14

    radius: 16
    color: "#282828"

    readonly property alias player: activePlayer.player

    ActivePlayer {
        id: activePlayer
    }
    readonly property bool playing: root.player !== null && root.player.playbackState === MprisPlaybackState.Playing
    readonly property bool active: root.playing || (root.player !== null && root.player.playbackState === MprisPlaybackState.Paused)
    readonly property color stateColor: root.playing ? "#E5B9C6" : "#928374"

    visible: root.active

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "󰒮 " + (root.playing ? "󰐌" : "󰏥") + " 󰒭"
        color: root.stateColor
        font.family: "Iosevka"
        font.pixelSize: 16
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: (mouse) => {
        if (!root.player) return;
        if (mouse.button === Qt.LeftButton) root.player.previous();
        else if (mouse.button === Qt.MiddleButton) root.player.togglePlaying();
        else root.player.next();
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.player ? root.player.identity + " : " + root.player.trackTitle : ""
    }
}
