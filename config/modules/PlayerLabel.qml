import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../components"

Pill {
    id: root

    marginTop: 5
    marginBottom: 5
    marginLeft: 5
    marginRight: 5

    padLeft: 15
    padRight: 15

    radius: 16
    color: "#282828"

    readonly property alias player: activePlayer.player

    ActivePlayer {
        id: activePlayer
    }
    readonly property string label: {
        if (!root.player) return "";
        const artist = root.player.trackArtist;
        const title = root.player.trackTitle;
        const text = artist.length > 0 ? artist + " - " + title : title;
        return text.length > 48 ? text.slice(0, 45) + "..." : text;
    }

    visible: root.label.length > 0

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.label
        color: "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
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
