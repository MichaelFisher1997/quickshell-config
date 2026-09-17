import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

Pill {
    id: root

    signal drawerRequested

    marginTop: 6
    marginBottom: 6
    marginLeft: 2
    marginRight: 2

    padLeft: 10
    padRight: 10

    radius: 12
    color: "transparent"

    property string weatherText: ""
    property string weatherJson: ""

    // Raw wttr.in payload shared with the drawer's weather tab, so the
    // drawer reuses this single poller instead of adding its own.
    readonly property var forecast: root.parsedForecast()

    function parsedForecast() {
        if (root.weatherJson.length === 0)
            return null;
        try {
            return JSON.parse(root.weatherJson);
        } catch (error) {
            return null;
        }
    }

    function refresh() {
        weatherProcess.running = true;
    }

    // wttr.in condition codes, not the reference Eww provider's WMO codes.
    // Cloud also represents fog/mist; frozen precipitation uses snow.
    function iconSource(code) {
        const icons = {
            113: "sun",
            116: "cloud-sun",
            119: "cloud",
            122: "cloud",
            125: "cloud",
            128: "cloud",
            131: "cloud",
            134: "cloud",
            137: "cloud",
            140: "cloud",
            143: "cloud",
            146: "cloud",
            149: "cloud",
            152: "cloud",
            155: "cloud",
            158: "cloud",
            161: "cloud",
            176: "rain",
            179: "snow",
            182: "snow",
            185: "rain",
            200: "storm",
            227: "snow",
            230: "snow",
            248: "cloud",
            260: "cloud",
            263: "rain",
            266: "rain",
            281: "rain",
            284: "rain",
            293: "rain",
            296: "rain",
            299: "rain",
            302: "rain",
            305: "rain",
            308: "rain",
            311: "rain",
            314: "rain",
            317: "snow",
            320: "snow",
            323: "snow",
            326: "snow",
            329: "snow",
            332: "snow",
            335: "snow",
            338: "snow",
            350: "snow",
            353: "rain",
            356: "rain",
            359: "rain",
            362: "snow",
            365: "snow",
            368: "snow",
            371: "snow",
            374: "snow",
            377: "snow",
            386: "storm",
            389: "storm",
            392: "storm",
            395: "storm",
            398: "snow",
            401: "snow",
            404: "snow",
            407: "snow",
            410: "snow",
            413: "snow",
            416: "snow",
            419: "snow",
            422: "snow",
            425: "snow",
            428: "snow",
            431: "snow"
        };
        return Qt.resolvedUrl("../assets/weather/" + (icons[Number(code)] || "cloud") + ".svg");
    }

    // Monochrome moon phase glyphs (Weather Icons moon set).
    function moonIcon(phase) {
        const icons = {
            "New Moon": "\uE38D",
            "Waxing Crescent": "\uE391",
            "First Quarter": "\uE394",
            "Waxing Gibbous": "\uE398",
            "Full Moon": "\uE39B",
            "Waning Gibbous": "\uE3A0",
            "Last Quarter": "\uE3A2",
            "Waning Crescent": "\uE3A6"
        };
        return icons[phase] || "\uE38D";
    }

    function to24h(time) {
        const match = /^(\d+):(\d+) (AM|PM)$/.exec(time);
        if (!match)
            return time;
        let hours = parseInt(match[1], 10) % 12;
        if (match[3] === "PM")
            hours += 12;
        return ("0" + hours).slice(-2) + ":" + match[2];
    }

    function chances(hour) {
        const names = {
            chanceoffog: "Fog",
            chanceoffrost: "Frost",
            chanceofovercast: "Overcast",
            chanceofrain: "Rain",
            chanceofsnow: "Snow",
            chanceofsunshine: "Sunshine",
            chanceofthunder: "Thunder",
            chanceofwindy: "Wind"
        };
        const found = [];
        for (const key in names) {
            const value = parseInt(hour[key], 10);
            if (value > 0)
                found.push([names[key], value]);
        }
        found.sort((a, b) => b[1] - a[1]);
        return found.map(entry => entry[0] + " " + entry[1] + "%").join(", ");
    }

    visible: root.weatherText.length > 0

    // Eww weather widget: peach SVG + peach bold temperature
    // (eww.scss .weather_temp).
    Image {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 17
        Layout.preferredHeight: 17
        width: 17
        height: 17
        source: root.iconSource(root.forecast ? root.forecast.current_condition[0].weatherCode : undefined)
        fillMode: Image.PreserveAspectFit
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: " " + root.weatherText + " °"
        color: root.thPeach
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        renderType: Text.NativeRendering
    }

    mouseArea.onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            root.drawerRequested();
    }

    Process {
        id: weatherProcess
        command: ["sh", "-c", "curl -sf --max-time 30 'https://wttr.in/Ashton-Under-Lyne?format=j1'" + " || curl -sf --max-time 30 'http://wttr.in/Ashton-Under-Lyne?format=j1'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const forecastData = JSON.parse(this.text);
                    const current = forecastData.current_condition[0];
                    root.weatherJson = this.text;
                    root.weatherText = current.temp_C;
                } catch (error) {
                    root.weatherJson = "";
                    root.weatherText = "";
                }
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }
}
