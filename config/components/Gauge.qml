import QtQuick

// Circular gauge used by the drawer's performance tab.
//
// Shows an honest 0..100 percentage arc with a caption and a detail line.
// The arc uses the metric color assigned by the page (Eww assigns CPU
// lilac, memory peach, disk sage) and shifts to yellow above 70 and red
// above 90, matching the state colors of the shared palette in Pill.qml.
Item {
    id: root

    // 0..100 percentage.
    property real value: 0
    property string caption: ""
    property string detail: ""
    // Metric color below the warn threshold.
    property color valueColor: "#d7beda"

    property int dialSize: 148
    property real ringWidth: 11

    // Theme literals kept in sync with the shared palette in Pill.qml
    // (Eww progress track: #38384d).
    readonly property color thWarn: "#e5c07b"
    readonly property color thBad: "#e06c75"
    readonly property color thText: "#bfc9db"
    readonly property color thMuted: "#6b7280"
    readonly property color thTrack: "#38384d"

    readonly property real clamped: Math.max(0, Math.min(100, root.value))
    // 270 degree sweep, starting at 135 degrees (lower left).
    readonly property real startAngle: 135
    readonly property real sweepAngle: 270

    implicitWidth: root.dialSize
    implicitHeight: root.dialSize + 44

    // The needle value eases toward the real value so live samples and the
    // initial fill-on-open both animate instead of jumping.
    property real animated: root.clamped
    onAnimatedChanged: dial.requestPaint()
    Behavior on animated {
        NumberAnimation {
            duration: 550
            easing.type: Easing.OutCubic
        }
    }

    Canvas {
        id: dial

        width: root.dialSize
        height: root.dialSize
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = this.getContext("2d");
            ctx.reset();
            const center = root.dialSize / 2;
            const radius = center - root.ringWidth / 2 - 3;
            if (radius <= 0)
                return;
            const start = (root.startAngle * Math.PI) / 180;
            const span = (root.sweepAngle * root.animated / 100 * Math.PI) / 180;

            // Track.
            ctx.lineWidth = root.ringWidth;
            ctx.lineCap = "round";
            ctx.strokeStyle = root.thTrack;
            ctx.beginPath();
            ctx.arc(center, center, radius, start, start + (root.sweepAngle * Math.PI) / 180, false);
            ctx.stroke();

            if (root.animated > 0.5) {
                const color = root.animated > 90 ? root.thBad : root.animated > 70 ? root.thWarn : root.valueColor;
                // Soft halo behind the value arc.
                ctx.strokeStyle = color;
                ctx.globalAlpha = 0.25;
                ctx.lineWidth = root.ringWidth + 5;
                ctx.beginPath();
                ctx.arc(center, center, radius, start, start + span, false);
                ctx.stroke();
                // Value arc.
                ctx.globalAlpha = 1;
                ctx.lineWidth = root.ringWidth;
                ctx.beginPath();
                ctx.arc(center, center, radius, start, start + span, false);
                ctx.stroke();
            }

            // Quarter tick dots.
            ctx.globalAlpha = 1;
            ctx.fillStyle = root.thTrack;
            for (let i = 0; i <= 4; i++) {
                const angle = start + (root.sweepAngle * i / 4) * Math.PI / 180;
                const x = center + Math.cos(angle) * (radius - root.ringWidth / 2 - 6);
                const y = center + Math.sin(angle) * (radius - root.ringWidth / 2 - 6);
                ctx.beginPath();
                ctx.arc(x, y, 1.6, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }

    Text {
        anchors.horizontalCenter: dial.horizontalCenter
        y: dial.y + root.dialSize / 2 - 30
        text: Math.round(root.animated) + "%"
        color: root.thText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 30
        font.bold: true
        renderType: Text.NativeRendering
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: dial.height + 8
        width: root.dialSize + 16
        horizontalAlignment: Text.AlignHCenter
        text: root.caption
        color: root.thText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.bold: true
        renderType: Text.NativeRendering
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: dial.height + 28
        width: root.dialSize + 16
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.detail
        color: root.thMuted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        renderType: Text.NativeRendering
    }
}
