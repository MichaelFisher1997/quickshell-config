import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

Pill {
    id: root

    marginTop: 0
    marginBottom: 0
    marginLeft: 0
    marginRight: 0

    padLeft: 0
    padRight: 0

    property string weatherText: ""
    property string weatherTooltip: ""

    readonly property string emojiPart: {
        const index = root.weatherText.indexOf(" ");
        return index > 0 ? root.weatherText.slice(0, index) : "";
    }

    readonly property string temperaturePart: {
        const index = root.weatherText.indexOf(" ");
        return index > 0 ? root.weatherText.slice(index + 1) : root.weatherText;
    }

    function withoutEmoji(text) {
        let result = "";
        for (const character of text) {
            const codePoint = character.codePointAt(0);
            const isEmoji =
                (codePoint >= 0x1f000 && codePoint <= 0x1faff) ||
                (codePoint >= 0x2300 && codePoint <= 0x23ff) ||
                (codePoint >= 0x2600 && codePoint <= 0x27bf) ||
                (codePoint >= 0x2b00 && codePoint <= 0x2bff) ||
                codePoint === 0x200d ||
                codePoint === 0xfe0e ||
                codePoint === 0xfe0f;
            if (!isEmoji) result += character;
        }
        return result.replace(/[ \t]{2,}/g, " ");
    }

    function iconFor(code) {
        const icons = {
            113: "☀️",
            116: "🌤️",
            119: "☁️",
            122: "🌥️",
            125: "🌫️",
            128: "🌫️",
            131: "💨",
            134: "🌪️",
            137: "🌪️",
            140: "🌪️",
            143: "🌫️",
            146: "🌫️",
            149: "🌫️",
            152: "🌫️",
            155: "🌫️",
            158: "🌫️",
            161: "🌫️",
            176: "🌦️",
            179: "🌧️",
            182: "🌧️",
            185: "🌧️",
            200: "🌩️",
            227: "❄️",
            230: "❄️",
            248: "🌫️",
            260: "🌫️",
            263: "🌧️",
            266: "🌧️",
            281: "🌦️",
            284: "🌦️",
            293: "🌧️",
            296: "🌧️",
            299: "🌧️",
            302: "🌧️",
            305: "🌧️",
            308: "🌧️",
            311: "🌧️",
            314: "🌧️",
            317: "🌧️",
            320: "🌨️",
            323: "🌨️",
            326: "🌨️",
            329: "🌨️",
            332: "🌨️",
            335: "🌨️",
            338: "🌨️",
            350: "🌨️",
            353: "🌧️",
            356: "🌧️",
            359: "🌧️",
            362: "🌨️",
            365: "🌨️",
            368: "🌨️",
            371: "🌨️",
            374: "🌨️",
            377: "🌨️",
            386: "🌩️",
            389: "🌨️",
            392: "🌨️",
            395: "🌨️",
            398: "🌨️",
            401: "🌨️",
            404: "🌨️",
            407: "🌨️",
            410: "🌨️",
            413: "🌨️",
            416: "🌨️",
            419: "🌨️",
            422: "🌨️",
            425: "🌨️",
            428: "🌨️",
            431: "🌨️"
        };
        return icons[Number(code)] || "";
    }

    function moonIcon(phase) {
        const icons = {
            "New Moon": "🌑",
            "Waxing Crescent": "🌒",
            "First Quarter": "🌓",
            "Waxing Gibbous": "🌔",
            "Full Moon": "🌕",
            "Waning Gibbous": "🌖",
            "Last Quarter": "🌗",
            "Waning Crescent": "🌘"
        };
        return icons[phase] || "🌑";
    }

    function to24h(time) {
        const match = /^(\d+):(\d+) (AM|PM)$/.exec(time);
        if (!match) return time;
        let hours = parseInt(match[1], 10) % 12;
        if (match[3] === "PM") hours += 12;
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
            if (value > 0) found.push([names[key], value]);
        }
        found.sort((a, b) => b[1] - a[1]);
        return found.map(entry => entry[0] + " " + entry[1] + "%").join(", ");
    }

    function buildTooltip(forecastData) {
        const current = forecastData.current_condition[0];
        const area = forecastData.nearest_area[0];
        const now = new Date();
        let tooltip = "<b>" + current.weatherDesc[0].value + "</b> " + current.temp_C + "°\n";
        tooltip += "Feels like: " + current.FeelsLikeC + "°\n";
        tooltip += "Wind: " + current.windspeedKmph + " km/h\n";
        tooltip += "Humidity: " + current.humidity + "%\n";
        const parts = [
            area.areaName[0].value,
            area.region[0].value,
            area.country[0].value
        ].filter(part => part.length > 0);
        tooltip += "Location: " + parts.join(", ") + "\n";

        const today = Qt.formatDate(now, "yyyy-MM-dd");
        const days = (forecastData.weather || []).filter(day => day.date >= today);
        for (let index = 0; index < days.length; index++) {
            const day = days[index];
            const dayDate = new Date(
                Number(day.date.slice(0, 4)),
                Number(day.date.slice(5, 7)) - 1,
                Number(day.date.slice(8, 10))
            );
            const label = index === 0 ? "Today, " : index === 1 ? "Tomorrow, " : "";
            tooltip += "\n<b>" + label + Qt.formatDate(dayDate, "yyyy-MM-dd") + "</b>\n";
            const astronomy = day.astronomy[0];
            tooltip += "⬆️ " + day.maxtempC + "° ⬇️ " + day.mintempC + "° 🌅 "
                + root.to24h(astronomy.sunrise) + " 🌇 " + root.to24h(astronomy.sunset)
                + " " + root.moonIcon(astronomy.moon_phase) + " " + astronomy.moon_illumination + "%\n";
            for (const hour of day.hourly) {
                const rawTime = String(hour.time);
                const hourValue = parseInt(rawTime.length >= 2 ? rawTime.slice(0, -2) : rawTime, 10);
                if (index === 0 && now.getHours() >= 2 && hourValue < now.getHours() - 2) continue;
                tooltip += ("0" + hourValue).slice(-2) + " " + root.iconFor(hour.weatherCode) + " "
                    + String(hour.FeelsLikeC).padStart(3) + "° " + hour.weatherDesc[0].value;
                const hourChances = root.chances(hour);
                if (hourChances.length > 0) tooltip += ", " + hourChances;
                tooltip += "\n";
            }
        }
        return tooltip;
    }

    visible: root.weatherText.length > 0

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: root.emojiPart.length > 0
        text: root.emojiPart
        font.family: "Noto Color Emoji"
        font.pixelSize: 14
        renderType: Text.QtRendering
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: (root.emojiPart.length > 0 ? " " : "") + root.temperaturePart + " °"
        color: "#f4d9e1"
        font.family: "Iosevka"
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }

    Tooltip {
        target: root
        shown: root.mouseArea.containsMouse
        rich: true
        text: root.weatherTooltip
    }

    Process {
        id: weatherProcess
        command: [
            "sh",
            "-c",
            "curl -sf --max-time 30 'https://wttr.in/Ashton-Under-Lyne?format=j1'"
            + " || curl -sf --max-time 30 'http://wttr.in/Ashton-Under-Lyne?format=j1'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const forecastData = JSON.parse(this.text);
                    const current = forecastData.current_condition[0];
                    root.weatherText = root.iconFor(current.weatherCode) + " " + current.temp_C;
                    root.weatherTooltip = root.withoutEmoji(root.buildTooltip(forecastData));
                } catch (error) {
                    root.weatherText = "";
                    root.weatherTooltip = "";
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
