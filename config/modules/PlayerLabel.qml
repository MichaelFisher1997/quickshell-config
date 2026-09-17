import QtQuick
import QtQuick.Layouts
import "../components"

Pill {
    id: root

    marginTop: 4
    marginBottom: 4
    marginLeft: 0
    marginRight: 0

    padLeft: 10
    padRight: 12

    radius: 12
    color: "#0f0f17"
    // Eww media strip: hairline inset ring rgba(255,255,255,0.06),
    // cool-gray track title (eww.scss .media_title).
    borderWidth: 1
    borderColor: "#0fffffff"

    readonly property alias player: activePlayer.player

    ActivePlayer {
        id: activePlayer
    }
    readonly property string label: {
        if (!root.player)
            return "";
        const artist = root.player.trackArtist;
        const title = root.player.trackTitle;
        const text = artist.length > 0 ? artist + " - " + title : title;
        return text.length > 48 ? text.slice(0, 45) + "..." : text;
    }

    visible: root.label.length > 0

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.label
        color: root.thText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: mouse => {
        if (!root.player)
            return;
        if (mouse.button === Qt.LeftButton)
            root.player.previous();
        else if (mouse.button === Qt.MiddleButton)
            root.player.togglePlaying();
        else
            root.player.next();
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.player ? root.player.identity + " : " + root.player.trackTitle : ""
    }
}
