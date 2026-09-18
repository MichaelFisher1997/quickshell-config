import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../components"

Pill {
    id: root

    marginTop: 4
    marginBottom: 4
    marginLeft: 0
    marginRight: 0

    padLeft: 12
    padRight: 10

    radius: 12
    color: "#0f0f17"
    // Eww media strip: hairline inset ring rgba(255,255,255,0.06).
    borderWidth: 1
    borderColor: "#0fffffff"

    readonly property alias player: activePlayer.player

    ActivePlayer {
        id: activePlayer
    }
    readonly property bool playing: root.player !== null && root.player.playbackState === MprisPlaybackState.Playing
    readonly property bool active: root.playing || (root.player !== null && root.player.playbackState === MprisPlaybackState.Paused)
    // Eww media buttons: cool gray idle, blue-gray while playing
    // (eww.scss .media_btn / .song_btn_play).
    readonly property color stateColor: root.playing ? root.thAccent : root.thText

    visible: root.active

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "󰒮 " + (root.playing ? "󰐌" : "󰏥") + " 󰒭"
        color: root.stateColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
        renderType: Text.NativeRendering
    }

    // Left-click toggles playback; prev/next live on middle/right and fall
    // back to toggling when the player reports no support (e.g. Spotify's
    // canGoPrevious = false), so a click never silently does nothing.
    mouseArea.onClicked: mouse => {
        if (!root.player)
            return;
        if (mouse.button === Qt.MiddleButton) {
            if (root.player.canGoPrevious)
                root.player.previous();
            else
                root.player.togglePlaying();
        } else if (mouse.button === Qt.RightButton) {
            if (root.player.canGoNext)
                root.player.next();
            else
                root.player.togglePlaying();
        } else {
            root.player.togglePlaying();
        }
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.player ? root.player.identity + " : " + root.player.trackTitle : ""
    }
}
