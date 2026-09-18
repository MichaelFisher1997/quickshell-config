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

    // Separate left-clickable transport icons, one per action (like the
    // Eww media strip buttons). Dimmed when the player reports no support.
    component MediaButton: Item {
        id: btn

        property string icon
        property bool supported: true
        signal activated()

        Layout.fillHeight: true
        implicitWidth: label.implicitWidth + 12

        opacity: root.player === null ? 0.4 : supported ? 1 : 0.4
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: hover.containsMouse ? root.thSurfaceHover : "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: btn.icon
            color: root.stateColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            renderType: Text.NativeRendering
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.activated()
        }
    }

    MediaButton {
        icon: "󰒮"
        supported: root.player !== null && root.player.canGoPrevious
        onActivated: if (root.player) root.player.previous()
    }

    MediaButton {
        icon: root.playing ? "󰐌" : "󰏥"
        supported: root.player !== null && root.player.canPause
        onActivated: if (root.player) root.player.togglePlaying()
    }

    MediaButton {
        icon: "󰒭"
        supported: root.player !== null && root.player.canGoNext
        onActivated: if (root.player) root.player.next()
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.player ? root.player.identity + " : " + root.player.trackTitle : ""
    }
}
