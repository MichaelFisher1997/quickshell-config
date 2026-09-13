import QtQuick
import QtQuick.Layouts

Item {
    id: root

    default property alias content: row.data
    readonly property alias mouseArea: pillMouse

    property real marginTop: 5
    property real marginBottom: 5
    property real marginLeft: 5
    property real marginRight: 5

    property real padLeft: 10
    property real padRight: 10
    property real padTop: 0
    property real padBottom: 0

    property real radius: 16
    property color color: "transparent"
    property real spacing: 0
    property real minWidth: 0

    property real barHeight: root.parent ? root.parent.height : 38

    implicitWidth: Math.max(root.minWidth, row.implicitWidth + root.padLeft + root.padRight + root.marginLeft + root.marginRight)
    implicitHeight: root.barHeight

    Rectangle {
        id: bg
        x: root.marginLeft
        y: root.marginTop
        width: root.width - root.marginLeft - root.marginRight
        height: root.height - root.marginTop - root.marginBottom
        radius: root.radius
        color: root.color
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
    }

    RowLayout {
        id: row
        anchors.left: bg.left
        anchors.leftMargin: root.padLeft
        anchors.right: bg.right
        anchors.rightMargin: root.padRight
        anchors.top: bg.top
        anchors.topMargin: root.padTop
        anchors.bottom: bg.bottom
        anchors.bottomMargin: root.padBottom
        spacing: root.spacing
    }
}
