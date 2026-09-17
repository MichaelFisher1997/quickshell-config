pragma ComponentBehavior: Bound

import QtQuick

// Weather page of the drawer. All data comes from the Weather bar module
// (single wttr.in poller): current conditions, a daily forecast laid out
// as ringed cards after the reference Eww weather popup (today tinted
// blue with a solid ring, following days green/yellow/..., peach
// monochrome SVGs, colored highs, muted lows, cyan rainfall), sun
// times and moon phase, and a horizontally scrollable hourly strip.
Item {
    id: root

    property string tabId: "weather"
    required property var weatherModule

    // Theme literals kept in sync with the shared palette in Pill.qml
    // (Eww weather popup: eww.scss .wp-* rules).
    readonly property color thText: "#bfc9db"
    readonly property color thMuted: "#6b7280"
    readonly property color thFaint: "#3e424f"
    readonly property color thPeach: "#e4c9af"
    readonly property color thBlueGray: "#a1bdce"
    readonly property color thLilac: "#d7beda"
    readonly property color thRain: "#56b6c2"
    readonly property color thHover: "#0dffffff"
    readonly property color thEdge: "#14ffffff"

    // Eww forecast card palette: today blue, then green, yellow,
    // orange, red (eww.scss .wp-blue .. .wp-red).
    readonly property var cardColors: ["#61afef", "#98c379", "#e5c07b", "#d19a66", "#e06c75"]

    readonly property var forecast: root.weatherModule.forecast
    readonly property var current: root.forecast && root.forecast.current_condition ? root.forecast.current_condition[0] : null
    readonly property var area: root.forecast && root.forecast.nearest_area ? root.forecast.nearest_area[0] : null
    readonly property var days: root.forecast && root.forecast.weather ? root.forecast.weather : []

    // Today's remaining hours, filtered the same way as the bar tooltip.
    readonly property var todayHours: {
        if (root.days.length === 0)
            return [];
        const now = new Date();
        const hours = [];
        for (const hour of root.days[0].hourly) {
            const raw = String(hour.time);
            const value = parseInt(raw.length >= 2 ? raw.slice(0, -2) : raw, 10);
            if (value < now.getHours() - 2)
                continue;
            hours.push(hour);
        }
        return hours;
    }

    function dayLabel(index, date) {
        if (index === 0)
            return "Today";
        if (index === 1)
            return "Tomorrow";
        return Qt.formatDate(date, "ddd");
    }

    function parseDate(value) {
        return new Date(Number(value.slice(0, 4)), Number(value.slice(5, 7)) - 1, Number(value.slice(8, 10)));
    }

    // Daily precipitation total in mm (Eww cards show precipitation_sum).
    function dayRainMm(day) {
        let sum = 0;
        for (const hour of day.hourly)
            sum += parseFloat(hour.precipMM) || 0;
        return Math.round(sum * 10) / 10;
    }

    function hourLabel(hour) {
        const raw = String(hour.time);
        const value = parseInt(raw.length >= 2 ? raw.slice(0, -2) : raw, 10);
        return ("0" + value).slice(-2) + ":00";
    }

    function locationText() {
        if (!root.area)
            return "";
        const parts = [root.area.areaName[0].value, root.area.region[0].value, root.area.country[0].value].filter(part => part.length > 0);
        return parts.join(", ");
    }

    implicitHeight: root.current ? column.implicitHeight + 32 : 160

    // Data not fetched yet (or the request failed): the module retries
    // hourly; the button forces a retry immediately.
    Item {
        visible: !root.current
        anchors.centerIn: parent
        width: placeholder.implicitWidth
        height: placeholder.implicitHeight + 40

        Text {
            id: placeholder

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Weather data unavailable"
            color: root.thMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            renderType: Text.NativeRendering
        }

        Rectangle {
            anchors.top: placeholder.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: retryLabel.implicitWidth + 22
            height: 28
            radius: 14
            border.width: 1
            border.color: retryMouse.containsMouse ? "#61afef" : "#3361afef"
            color: retryMouse.containsMouse ? "#2661afef" : "transparent"

            Text {
                id: retryLabel

                anchors.centerIn: parent
                text: "󰐐  Retry now"
                color: retryMouse.containsMouse ? root.thText : root.thMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: retryMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.weatherModule.refresh()
            }
        }
    }

    Column {
        id: column

        visible: root.current
        x: 26
        y: 16
        width: root.width - 52
        spacing: 12

        // Current conditions.
        Item {
            width: parent.width
            height: 62

            Image {
                id: currentGlyph

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 52
                source: root.current ? root.weatherModule.iconSource(root.current.weatherCode) : ""
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.left: currentGlyph.right
                anchors.leftMargin: 14
                anchors.baseline: parent.bottom
                text: root.current ? root.current.temp_C + "°" : ""
                color: root.thText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 46
                font.bold: true
                renderType: Text.NativeRendering
            }

            Column {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 3

                Text {
                    anchors.right: parent.right
                    text: root.current ? root.current.weatherDesc[0].value : ""
                    color: root.thBlueGray
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.right: parent.right
                    text: "󰍍 " + root.locationText()
                    color: root.thLilac
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    renderType: Text.NativeRendering
                }
            }
        }

        // Feels like / wind / humidity, peach glyph + cool-gray text.
        Row {
            spacing: 22

            Row {
                spacing: 6
                Text {
                    text: "\uE350"
                    color: root.thPeach
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "feels like " + (root.current ? root.current.FeelsLikeC : "–") + "°"
                    color: root.thText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    renderType: Text.NativeRendering
                }
            }

            Row {
                spacing: 6
                Text {
                    text: "\uE34B"
                    color: root.thPeach
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "wind " + (root.current ? root.current.windspeedKmph : "–") + " km/h" + (root.current && root.current.winddir16Point ? " " + root.current.winddir16Point : "")
                    color: root.thText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    renderType: Text.NativeRendering
                }
            }

            Row {
                spacing: 6
                Text {
                    text: "\uE373"
                    color: root.thPeach
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "humidity " + (root.current ? root.current.humidity : "–") + "%"
                    color: root.thText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    renderType: Text.NativeRendering
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.thEdge
        }

        Text {
            text: "DAILY FORECAST"
            color: root.thFaint
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            renderType: Text.NativeRendering
        }

        // Forecast cards after the Eww weather popup: thin colored
        // outline per day, today tinted blue with a solid ring.
        Row {
            id: forecastRow

            width: parent.width
            spacing: 8

            Repeater {
                id: forecastCards

                model: Math.min(root.days.length, root.cardColors.length)

                delegate: Rectangle {
                    id: card

                    required property int index

                    readonly property var day: root.days[card.index]
                    readonly property color accent: root.cardColors[card.index]
                    readonly property bool isToday: card.index === 0

                    width: Math.max(0, (forecastRow.width - forecastRow.spacing * (forecastCards.count - 1)) / Math.max(1, forecastCards.count))
                    height: 140
                    radius: 10
                    color: card.isToday ? "#2661afef" : "transparent"
                    border.width: card.isToday ? 2 : 1
                    border.color: card.isToday ? "#61afef" : Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.35)

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.dayLabel(card.index, root.parseDate(card.day.date))
                            color: card.isToday ? "#61afef" : root.thText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: true
                            renderType: Text.NativeRendering
                        }

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 26
                            height: 26
                            source: root.weatherModule.iconSource(card.day.hourly[4].weatherCode)
                            fillMode: Image.PreserveAspectFit
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.day.maxtempC + "°"
                            color: card.isToday ? root.thText : card.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.day.mintempC + "°"
                            color: root.thMuted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.dayRainMm(card.day) + "mm"
                            color: root.thRain
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }

        // Sun times and moon phase per forecast day.
        Column {
            spacing: 4
            width: parent.width

            Repeater {
                model: Math.min(root.days.length, root.cardColors.length)

                delegate: Row {
                    id: astroRow

                    required property int index

                    readonly property var day: root.days[astroRow.index]
                    readonly property color accent: root.cardColors[astroRow.index]

                    spacing: 10

                    Text {
                        width: 76
                        text: root.dayLabel(astroRow.index, root.parseDate(astroRow.day.date))
                        color: astroRow.index === 0 ? "#61afef" : root.thText
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: astroRow.index === 0
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: "\uE34C " + root.weatherModule.to24h(astroRow.day.astronomy[0].sunrise) + "   \uE34D " + root.weatherModule.to24h(astroRow.day.astronomy[0].sunset)
                        color: root.thMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: root.weatherModule.moonIcon(astroRow.day.astronomy[0].moon_phase)
                        color: root.thPeach
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: astroRow.day.astronomy[0].moon_illumination + "%"
                        color: root.thMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Text {
            text: "HOURLY — TODAY"
            color: root.thFaint
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            renderType: Text.NativeRendering
        }

        // Scrollable hourly strip; keeps the tooltip's rich detail
        // (feels-like and per-hour chances) available inside the drawer.
        Flickable {
            id: hourStrip

            width: parent.width
            height: 108
            contentWidth: hourRow.width
            contentHeight: height
            clip: true
            flickDeceleration: 8000
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentWidth > width

            Row {
                id: hourRow

                spacing: 8

                Repeater {
                    model: root.todayHours

                    delegate: Rectangle {
                        id: hourCard

                        required property var modelData

                        width: 92
                        height: 104
                        radius: 10
                        color: hourMouse.containsMouse ? root.thHover : "transparent"
                        border.width: 1
                        border.color: root.thEdge

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.hourLabel(hourCard.modelData)
                                color: root.thMuted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                renderType: Text.NativeRendering
                            }

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 20
                                height: 20
                                source: root.weatherModule.iconSource(hourCard.modelData.weatherCode)
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: hourCard.modelData.FeelsLikeC + "°"
                                color: root.thText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                font.bold: true
                                renderType: Text.NativeRendering
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: {
                                    const chances = root.weatherModule.chances(hourCard.modelData);
                                    return chances.length > 0 ? chances : hourCard.modelData.weatherDesc[0].value;
                                }
                                color: root.thMuted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                renderType: Text.NativeRendering
                            }
                        }

                        MouseArea {
                            id: hourMouse

                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
