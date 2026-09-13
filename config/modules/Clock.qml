import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

Pill {
    id: root

    marginTop: 0
    marginBottom: 0
    marginLeft: 10
    marginRight: 0

    padLeft: 13
    padRight: 15

    radius: 24
    color: "#282828"

    readonly property string calendar: root.calendarText(clock.date)

    function calendarText(date) {
        const start = (new Date(date.getFullYear(), date.getMonth(), 1).getDay() + 6) % 7;
        const days = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
        const header = "Mo Tu We Th Fr Sa Su";
        let rows = [];
        let row = [];
        for (let i = 0; i < start; i++) row.push("  ");
        for (let day = 1; day <= days; day++) {
            row.push(String(day).padStart(2, " "));
            if (row.length === 7) {
                rows.push(row.join(" "));
                row = [];
            }
        }
        if (row.length > 0) rows.push(row.join(" ").replace(/\s+$/, ""));
        return header + "\n" + rows.join("\n");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: " " + Qt.formatDateTime(clock.date, "HH:mm | dd/MM/yy")
        color: "#e6b9c6"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
        font.bold: true
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: Qt.formatDateTime(clock.date, "yyyy MMMM") + "\n" + root.calendar
    }
}
