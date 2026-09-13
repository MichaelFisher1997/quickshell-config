import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool rich: false
    property bool shown: false

    visible: root.shown && root.text.length > 0
    color: "transparent"
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    anchor {
        window: root.target.QsWindow.window
        adjustment: PopupAdjustment.None
        gravity: Edges.Bottom | Edges.Right

        onAnchoring: {
            const pos = root.target.QsWindow.contentItem.mapFromItem(
                root.target,
                root.target.width / 2 - root.width / 2,
                root.target.height + 5
            );
            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
        }
    }

    Rectangle {
        id: content
        color: "#282828"
        radius: 8
        implicitWidth: label.implicitWidth + 24
        implicitHeight: label.implicitHeight + 10

        Text {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 720)
            wrapMode: Text.Wrap
            text: root.rich ? root.text.replace(/\n/g, "<br/>") : root.text
            textFormat: root.rich ? Text.RichText : Text.PlainText
            color: "#f4d9e1"
            font.family: "Iosevka"
            font.pixelSize: 13
            renderType: Text.NativeRendering
        }
    }
}
