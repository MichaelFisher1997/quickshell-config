pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Monday-first month grid with today marking, day selection, and month
// navigation. The date reference comes from the Clock bar module (no
// extra poller). Styling follows the reference Eww calendar:
//
//   * weekday columns colored Mon..Sun (blue, green, yellow, orange,
//     red, violet, pink — eww.scss .cal-mon .. .cal-sun),
//   * every day sits in a thin circular outline tinted with its
//     weekday color at 35% (eww .cal-day ring),
//   * today is filled with its weekday color and dark text
//     (eww .cal-today.cal-<dow>),
//   * adjacent-month days are muted faint gray with a barely visible
//     ring (eww .cal-day.cal-other),
//   * month navigation uses small violet pills, the today reset a
//     blue-gray pill (eww .cal-nav-btn / .cal-nav-yr).
//
// Two variants share this single implementation: compact (embedded in
// the dashboard card mosaic: no big clock header, tighter cells and
// paddings) and full (standalone page with a large seconds clock and a
// selected-day line).
Item {
    id: root

    property string tabId: "calendar"
    required property var clockModule
    property bool compact: false

    // Theme literals kept in sync with the shared palette in Pill.qml.
    readonly property color thAccentStrong: "#d7beda"
    readonly property color thText: "#bfc9db"
    readonly property color thMuted: "#6b7280"
    readonly property color thFaint: "#3e424f"
    readonly property color thHover: "#0fffffff"

    // Weekday column colors, Mon-first (eww.scss .cal-mon .. .cal-sun).
    readonly property var dowColors: ["#61afef", "#98c379", "#e5c07b", "#d19a66", "#e06c75", "#c678dd", "#ff79c6"]

    readonly property date today: root.clockModule.currentDate
    property date selectedDate: root.today
    property date viewMonth: {
        const date = root.today;
        return new Date(date.getFullYear(), date.getMonth(), 1);
    }

    readonly property int sidePad: root.compact ? 18 : 26
    readonly property int verticalPad: root.compact ? 14 : 16
    readonly property real gridWidth: Math.min(root.width - 2 * root.sidePad, 462)
    readonly property real cellSize: Math.floor(root.gridWidth / 7)
    readonly property var weekdayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    // Grid cells: { date, other } — adjacent-month days carry real
    // dates so they can render muted numbers (Eww .cal-other).
    readonly property var cells: {
        const year = root.viewMonth.getFullYear();
        const month = root.viewMonth.getMonth();
        const first = new Date(year, month, 1);
        const lead = (first.getDay() + 6) % 7;
        const days = new Date(year, month + 1, 0).getDate();
        const prevDays = new Date(year, month, 0).getDate();
        const cells = [];
        for (let i = lead - 1; i >= 0; i--)
            cells.push({
                "date": new Date(year, month - 1, prevDays - i),
                "other": true
            });
        for (let day = 1; day <= days; day++)
            cells.push({
                "date": new Date(year, month, day),
                "other": false
            });
        let next = 1;
        while (cells.length % 7 !== 0)
            cells.push({
                "date": new Date(year, month + 1, next++),
                "other": true
            });
        return cells;
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function shiftMonth(direction) {
        root.viewMonth = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() + direction, 1);
    }

    function selectToday() {
        root.selectedDate = root.today;
        root.viewMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1);
    }

    implicitHeight: Math.round(column.implicitHeight + 2 * root.verticalPad)

    SystemClock {
        id: secondsClock

        // The compact variant shows no time at all (the dashboard has
        // its own clock card), so it never needs seconds precision.
        precision: root.compact ? SystemClock.Minutes : SystemClock.Seconds
    }

    Column {
        id: column

        x: root.sidePad
        y: root.verticalPad
        width: root.width - 2 * root.sidePad
        spacing: root.compact ? 8 : 12

        // Big clock on the left, selected date on the right.
        Item {
            visible: !root.compact
            width: parent.width
            height: 56

            Text {
                id: timeLabel

                anchors.left: parent.left
                anchors.baseline: parent.bottom
                text: Qt.formatTime(secondsClock.date, "HH:mm")
                color: root.thText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 50
                font.bold: true
                renderType: Text.NativeRendering
            }

            Text {
                anchors.left: timeLabel.right
                anchors.leftMargin: 4
                anchors.baseline: parent.bottom
                text: Qt.formatTime(secondsClock.date, ":ss")
                color: root.thAccentStrong
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                renderType: Text.NativeRendering
            }

            Column {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 3

                Text {
                    anchors.right: parent.right
                    text: Qt.formatDate(root.selectedDate, "dddd, d MMMM yyyy")
                    color: root.thText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.right: parent.right
                    text: root.sameDay(root.selectedDate, root.today) ? "selected: today" : "selected day"
                    color: root.thMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        Rectangle {
            visible: !root.compact
            width: parent.width
            height: 1
            color: "#14ffffff"
        }

        // Month navigation row: violet month pills, blue-gray Today.
        Item {
            width: parent.width
            height: root.compact ? 28 : 34

            Row {
                id: monthNav

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: root.compact ? 26 : 30
                    height: root.compact ? 22 : 24
                    radius: 6
                    color: prevMouse.containsMouse ? "#c678dd" : "#26c678dd"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "<"
                        color: prevMouse.containsMouse ? "#0f0f17" : "#c678dd"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: root.compact ? 13 : 14
                        font.bold: true
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: prevMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.shiftMonth(-1)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.max(0, column.width - todayButton.width - 2 * (root.compact ? 26 : 30) - 3 * monthNav.spacing))
                    elide: Text.ElideRight
                    text: Qt.formatDate(root.viewMonth, "MMMM yyyy")
                    color: root.thAccentStrong
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.compact ? 14 : 16
                    font.bold: true
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    width: root.compact ? 26 : 30
                    height: root.compact ? 22 : 24
                    radius: 6
                    color: nextMouse.containsMouse ? "#c678dd" : "#26c678dd"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ">"
                        color: nextMouse.containsMouse ? "#0f0f17" : "#c678dd"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: root.compact ? 13 : 14
                        font.bold: true
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.shiftMonth(1)
                    }
                }
            }

            Rectangle {
                id: todayButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: todayLabel.implicitWidth + (root.compact ? 16 : 22)
                height: root.compact ? 22 : 24
                radius: 6
                color: todayMouse.containsMouse ? "#a1bdce" : "#1fa1bdce"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: "Today"
                    color: todayMouse.containsMouse ? "#0f0f17" : "#a1bdce"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.compact ? 11 : 12
                    font.bold: true
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: todayMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.selectToday()
                }
            }
        }

        Row {
            width: root.gridWidth
            height: root.compact ? 18 : 20

            Repeater {
                model: root.weekdayNames

                delegate: Text {
                    id: dowHeader

                    required property string modelData
                    required property int index

                    width: root.cellSize
                    horizontalAlignment: Text.AlignHCenter
                    text: dowHeader.modelData
                    color: root.dowColors[dowHeader.index]
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.compact ? 11 : 12
                    font.bold: true
                    renderType: Text.NativeRendering
                }
            }
        }

        Grid {
            width: root.gridWidth
            columns: 7
            rowSpacing: 2

            Repeater {
                model: root.cells

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    readonly property date day: cell.modelData.date
                    readonly property bool other: cell.modelData.other
                    readonly property color dow: root.dowColors[cell.index % 7]
                    readonly property bool isToday: !cell.other && root.sameDay(cell.day, root.today)
                    readonly property bool isSelected: !cell.other && root.sameDay(cell.day, root.selectedDate)

                    width: root.cellSize
                    height: root.cellSize * (root.compact ? 0.66 : 0.74)

                    // Thin circular outline tinted with the weekday
                    // color; today is filled solid with dark text.
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize * (root.compact ? 0.66 : 0.72)
                        height: width
                        radius: width / 2
                        color: cell.isToday ? cell.dow : cellMouse.containsMouse && !cell.other ? root.thHover : "transparent"
                        border.width: 1
                        border.color: cell.isToday || (cell.isSelected && !cell.other) ? cell.dow : cell.other ? "#08ffffff" : Qt.rgba(cell.dow.r, cell.dow.g, cell.dow.b, 0.35)

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        color: cell.isToday ? "#0f0f17" : cell.other ? root.thFaint : cell.dow
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: cell.isToday || cell.isSelected
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: cellMouse

                        anchors.fill: parent
                        enabled: !cell.other
                        hoverEnabled: true
                        onClicked: {
                            if (!cell.other)
                                root.selectedDate = cell.day;
                        }
                    }
                }
            }
        }
    }
}
