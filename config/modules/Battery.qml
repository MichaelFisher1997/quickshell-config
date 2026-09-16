import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 5
    marginBottom: 5
    marginLeft: 5
    marginRight: 5

    padLeft: 5
    padRight: 5

    radius: 8

    property bool present: false
    property bool alt: false
    property int capacity: 0
    property string status: "Unknown"
    property real timeRemaining: 0

    readonly property bool charging: root.status === "Charging"
    readonly property bool full: root.status === "Full"
    readonly property string stateClass: root.capacity <= 15 ? "critical" : root.capacity <= 30 ? "warning" : root.capacity <= 95 ? "good" : ""

    readonly property bool greenState: root.charging || root.full || root.stateClass === "good"
    readonly property bool warningState: root.stateClass === "warning" && !root.charging
    readonly property bool criticalState: root.stateClass === "critical" && !root.charging

    readonly property color textColor: root.greenState ? "#9ece6a" : root.warningState ? "#e0af68" : root.criticalState ? "#f7768e" : "#f4d9e1"
    readonly property color pillColor: root.greenState ? "#1f9ece6a" : root.warningState ? "#24e0af68" : root.criticalState ? "#29f7768e" : "transparent"

    readonly property var icons: ["", "", "", "", ""]

    readonly property string icon: {
        const divisor = Math.max(1, Math.floor(100 / root.icons.length));
        const index = Math.min(root.icons.length - 1, Math.max(0, Math.floor(root.capacity / divisor)));
        return root.icons[index];
    }

    readonly property string timeText: {
        const hours = Math.abs(root.timeRemaining);
        const fullHours = Math.floor(hours);
        const minutes = Math.floor(60 * (hours - fullHours));
        if (fullHours === 0 && minutes === 0) return "";
        return fullHours + " h " + minutes + " min";
    }

    readonly property string tooltipText: root.timeRemaining !== 0
        ? (root.timeRemaining > 0 ? "Empty in " : "Full in ") + root.timeText
        : root.status

    function number(value) {
        const parsed = Number(value);
        return isFinite(parsed) ? parsed : null;
    }

    function capacityOf(battery) {
        if (battery.capacity !== undefined) return Number(battery.capacity);
        const chargeNow = root.number(battery.charge_now);
        const chargeFull = root.number(battery.charge_full);
        if (chargeNow !== null && chargeFull !== null && chargeFull !== 0) return Math.floor(100 * chargeNow / chargeFull);
        const energyNow = root.number(battery.energy_now);
        const energyFull = root.number(battery.energy_full);
        if (energyNow !== null && energyFull !== null && energyFull !== 0) return Math.floor(100 * energyNow / energyFull);
        return 0;
    }

    function energyOf(battery, key) {
        const energy = root.number(battery[key === "now" ? "energy_now" : "energy_full"]);
        if (energy !== null) return energy / 1000000;
        const charge = root.number(battery[key === "now" ? "charge_now" : "charge_full"]);
        const voltage = root.number(battery.voltage_now);
        if (charge !== null && voltage !== null) return charge * voltage / 1000000000000;
        return null;
    }

    function powerOf(battery) {
        const powerNow = root.number(battery.power_now);
        if (powerNow !== null) return Math.abs(powerNow) / 1000000;
        const current = root.number(battery.current_now);
        const voltage = root.number(battery.voltage_now);
        if (current !== null && voltage !== null) return Math.abs(current * voltage) / 1000000000000;
        return null;
    }

    function update(text) {
        const devices = {};
        for (const line of text.split("\n")) {
            const trimmed = line.trim();
            if (trimmed.length === 0) continue;
            const parts = trimmed.split(/\s+/);
            if (parts.length < 3) continue;
            if (!devices[parts[0]]) devices[parts[0]] = {};
            devices[parts[0]][parts[1]] = parts.slice(2).join(" ");
        }

        let adapter = null;
        const batteries = [];
        for (const name in devices) {
            const device = devices[name];
            if (device.type === "Battery" && device.scope !== "device") batteries.push(device);
            else if (device.online !== undefined) adapter = device;
        }

        root.present = batteries.length > 0;
        if (!root.present) return;

        const rank = { Charging: 0, Discharging: 1, "Not charging": 2, Full: 3 };
        let status = "Unknown";
        let sumCapacity = 0;
        let energyNow = 0;
        let energyFull = 0;
        let power = 0;
        let timeToEmpty = 0;
        let timeToFull = 0;
        let haveEnergy = false;
        let havePower = false;

        for (const battery of batteries) {
            sumCapacity += root.capacityOf(battery);
            const now = root.energyOf(battery, "now");
            const full = root.energyOf(battery, "full");
            if (now !== null && full !== null) {
                energyNow += now;
                energyFull += full;
                haveEnergy = true;
            }
            const watts = root.powerOf(battery);
            if (watts !== null) {
                power += watts;
                havePower = true;
            }
            const batteryStatus = battery.status !== undefined ? battery.status : "Unknown";
            const batteryRank = rank[batteryStatus] !== undefined ? rank[batteryStatus] : 4;
            const currentRank = rank[status] !== undefined ? rank[status] : 4;
            if (batteryRank < currentRank) status = batteryStatus;
            timeToEmpty += Number(battery.time_to_empty_now || 0);
            timeToFull += Number(battery.time_to_full_now || 0);
        }

        root.capacity = Math.round(sumCapacity / batteries.length);

        if ((status === "Discharging" || status === "Not charging") && adapter !== null) {
            if (adapter.online === "1" && adapter.status !== "Discharging") status = "Plugged";
        }
        if (root.capacity === 100 && status === "Charging") status = "Full";
        root.status = status;

        let remaining = 0;
        if (status === "Discharging") {
            if (timeToEmpty > 0) remaining = timeToEmpty / 3600;
            else if (haveEnergy && havePower && power !== 0) remaining = energyNow / power;
        } else if (status === "Charging") {
            if (timeToFull > 0) remaining = -timeToFull / 3600;
            else if (haveEnergy && havePower && power !== 0) remaining = -(energyFull - energyNow) / power;
            if (remaining > 0) remaining = 0;
        }
        root.timeRemaining = remaining;
    }

    color: root.pillColor
    visible: root.present

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.alt
            ? root.icon + " " + root.timeText
            : root.charging
                ? root.capacity + "% "
                : root.status === "Plugged"
                    ? root.capacity + "% "
                    : root.icon + "  " + root.capacity + "%"
        color: root.textColor
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: root.alt = !root.alt

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        text: root.tooltipText
    }

    Process {
        id: statusProcess
        command: [
            "sh",
            "-c",
            "for d in /sys/class/power_supply/*/; do n=${d%/}; n=${n##*/};"
            + " for f in type scope status capacity energy_now energy_full power_now"
            + " charge_now charge_full current_now voltage_now time_to_empty_now"
            + " time_to_full_now online; do if [ -r \"$d$f\" ]; then"
            + " printf '%s %s %s\\n' \"$n\" \"$f\" \"$(cat \"$d$f\")\"; fi; done; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.update(this.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProcess.running = true
    }
}
