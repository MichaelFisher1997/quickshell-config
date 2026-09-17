import QtQuick
import QtQuick.Layouts

Item {
    id: root

    default property alias content: row.data
    readonly property alias mouseArea: pillMouse

    // Shared module palette, ported verbatim from the reference Eww bar
    // (eww.scss): near-black surfaces, cool gray/lilac text and the Eww
    // accent family. Drawer.qml, Tooltip.qml and the drawer pages keep
    // matching copies of the same literals.
    readonly property color thBg: "#0f0f17"
    readonly property color thSurface: "#0f0f17"
    readonly property color thSurfaceHover: "#0fffffff"
    readonly property color thHeroSurface: "#0f0f17"
    readonly property color thAccentSurface: "#22242b"
    readonly property color thFocusSurface: "transparent"
    readonly property color thUrgentSurface: "#26e06c75"
    readonly property color thHoverTint: "#0fffffff"
    // Eww inset ring rgba(255,255,255,0.08) used by weather cards.
    readonly property color thRing: "#14ffffff"
    readonly property color thAccent: "#a1bdce"
    readonly property color thAccentStrong: "#d7beda"
    readonly property color thText: "#bfc9db"
    readonly property color thMuted: "#6b7280"
    readonly property color thFaint: "#3e424f"
    readonly property color thPeach: "#e4c9af"
    readonly property color thGood: "#98c379"
    readonly property color thWarn: "#e5c07b"
    readonly property color thBad: "#e06c75"
    readonly property color thGoodBg: "#2698c379"
    readonly property color thWarnBg: "#26e5c07b"
    readonly property color thBadBg: "#26e06c75"

    property real marginTop: 6
    property real marginBottom: 6
    property real marginLeft: 2
    property real marginRight: 2

    property real padLeft: 10
    property real padRight: 10
    property real padTop: 0
    property real padBottom: 0

    property real radius: 12
    property color color: "transparent"
    // Optional hairline outline (Eww media strip: 1px rgba(255,255,255,0.06)).
    property real borderWidth: 0
    property color borderColor: "transparent"
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
        border.width: root.borderWidth
        border.color: root.borderColor

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Rectangle {
        id: hoverTint
        anchors.fill: bg
        radius: root.radius
        color: root.thHoverTint
        // Mirror the outline so ringed pills keep it while hovered.
        border.width: root.borderWidth
        border.color: root.borderColor
        opacity: pillMouse.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
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
        opacity: pillMouse.pressed ? 0.75 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 70
            }
        }
    }
}
