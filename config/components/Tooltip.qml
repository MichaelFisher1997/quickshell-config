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
            const pos = root.target.QsWindow.contentItem.mapFromItem(root.target, root.target.width / 2 - root.width / 2, root.target.height + 5);
            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
        }
    }

    // Theme literals kept in sync with the shared palette in Pill.qml
    // (Eww tooltip: #0f0f17 surface, #bfc9db text, 10px radius).
    Rectangle {
        id: content
        color: "#f20f0f17"
        radius: 10
        border.width: 1
        border.color: "#14ffffff"
        implicitWidth: label.implicitWidth + 26
        implicitHeight: label.implicitHeight + 12

        Text {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 720)
            wrapMode: Text.Wrap
            text: root.rich ? root.text.replace(/\n/g, "<br/>") : root.text
            textFormat: root.rich ? Text.RichText : Text.PlainText
            color: "#bfc9db"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            renderType: root.rich ? Text.QtRendering : Text.NativeRendering
        }
    }
}
