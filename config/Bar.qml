pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"
import "drawer"
import "modules"

PanelWindow {
    id: root

    required property var modelData
    screen: root.modelData
    readonly property int barHeight: 40
    readonly property int frameWidth: 10
    readonly property int innerRadius: 24
    // Eww bar surface color (eww.scss .bar_class background).
    readonly property color frameColor: "#0f0f17"

    // Drawer state. The section id lives in the drawer; the bar owns the
    // open flag and routes module signals to it.
    property bool drawerOpen: false

    function openDrawer(section) {
        drawer.activeTab = section;
        root.drawerOpen = true;
    }

    function closeDrawer() {
        root.drawerOpen = false;
    }

    // Clicking a trigger for the section already shown closes the drawer;
    // any other trigger switches its tab without closing first.
    function toggleDrawer(section) {
        if (root.drawerOpen && drawer.activeTab === section)
            root.closeDrawer();
        else
            root.openDrawer(section);
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Draw at the physical screen edges, independently of other panels' reservations.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-frame"
    color: "transparent"

    // Keyboard focus and the dismissal grab are released when the drawer closes.
    WlrLayershell.keyboardFocus: root.drawerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The compositor dismisses the grab on outside clicks, without a desktop overlay.
    HyprlandFocusGrab {
        windows: [root]
        active: root.drawerOpen
        onCleared: root.closeDrawer()
    }

    Timer {
        interval: 3000
        running: root.drawerOpen && !drawer.hovered && !controlsHover.hovered
        onTriggered: root.closeDrawer()
    }

    // Only the top controls and the visible part of the animated drawer
    // accept input. The desktop and decorative frame pass it through.
    // The nested regions combine; the drawer region's rounded bottom
    // corners stay click-through and update live during the animation.
    mask: Region {
        Region {
            width: root.width
            height: root.barHeight
        }
        Region {
            x: drawer.x
            y: drawer.y
            width: drawer.width
            height: drawer.height
            bottomLeftRadius: drawer.cornerRadius
            bottomRightRadius: drawer.cornerRadius
        }
    }

    Canvas {
        id: frame
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = root.frameColor;
            ctx.fillRect(0, 0, width, height);

            const l = root.frameWidth;
            const t = root.barHeight;
            const r = width - root.frameWidth;
            const b = height - root.frameWidth;
            const radius = Math.max(0, Math.min(root.innerRadius, (r - l) / 2, (b - t) / 2));
            ctx.beginPath();
            ctx.moveTo(l + radius, t);
            ctx.lineTo(r - radius, t);
            ctx.quadraticCurveTo(r, t, r, t + radius);
            ctx.lineTo(r, b - radius);
            ctx.quadraticCurveTo(r, b, r - radius, b);
            ctx.lineTo(l + radius, b);
            ctx.quadraticCurveTo(l, b, l, b - radius);
            ctx.lineTo(l, t + radius);
            ctx.quadraticCurveTo(l, t, l + radius, t);
            ctx.closePath();
            ctx.globalCompositeOperation = "destination-out";
            ctx.fill();
        }
    }

    // A four-anchor window cannot reserve space. Separate input-transparent surfaces
    // keep tiled/maximized windows inside the frame without compositor configuration.
    Variants {
        model: ["top", "left", "right", "bottom"]
        delegate: Component {
            PanelWindow {
                required property string modelData
                screen: root.screen
                color: "transparent"
                mask: Region {}
                WlrLayershell.namespace: "quickshell-frame-reservation"
                anchors.top: modelData !== "bottom"
                anchors.bottom: modelData !== "top"
                anchors.left: modelData !== "right"
                anchors.right: modelData !== "left"
                implicitWidth: root.frameWidth
                implicitHeight: modelData === "top" ? root.barHeight : root.frameWidth
                exclusiveZone: modelData === "top" ? root.barHeight : root.frameWidth
            }
        }
    }

    Row {
        anchors {
            left: parent.left
            leftMargin: 12
            top: parent.top
        }
        height: root.barHeight

        Launcher {}
        Workspaces {}
        Backlight {}
        Battery {}
        PlayerControls {}
        PlayerLabel {}
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }
        height: root.barHeight

        Weather {
            id: weatherModule
            onDrawerRequested: root.toggleDrawer("weather")
        }
        Clock {
            id: clockModule
            onDrawerRequested: root.toggleDrawer("dashboard")
        }
        Volume {
            id: volumeModule
            onDrawerRequested: root.toggleDrawer("sound")
        }

        HoverHandler {
            id: controlsHover
        }
    }

    Row {
        anchors {
            right: parent.right
            rightMargin: 12
            top: parent.top
        }
        height: root.barHeight

        Dictation {}
        Cpu {
            id: cpuModule
        }
        Memory {
            id: memoryModule
        }
        Disk {
            id: diskModule
        }
        Tray {}
    }

    // Drawer attached seamlessly under the top bar strip. It shares the
    // window with the bar, so the modules above are the single data
    // source for every tab (no duplicate pollers).
    Drawer {
        id: drawer

        viewportWidth: root.width
        viewportHeight: root.height
        attachY: root.barHeight
        sideInset: root.frameWidth + 8
        preferredWidth: 720

        tabs: [
            {
                "id": "dashboard",
                "label": "Dashboard",
                "icon": "󰕮",
                "width": 920
            },
            {
                "id": "weather",
                "label": "Weather",
                "icon": "󰖕"
            },
            {
                "id": "sound",
                "label": "Sound",
                "icon": "󰕾"
            },
            {
                "id": "performance",
                "label": "Performance",
                "icon": "󰓅"
            }
        ]

        opened: root.drawerOpen
        onCloseRequested: root.closeDrawer()

        DashboardTab {
            clockModule: clockModule
            weatherModule: weatherModule
            cpuModule: cpuModule
            memoryModule: memoryModule
            diskModule: diskModule
            drawerOpen: root.drawerOpen
            onWeatherTabRequested: drawer.activeTab = "weather"
        }

        WeatherTab {
            weatherModule: weatherModule
        }

        PerformanceTab {
            cpuModule: cpuModule
            memoryModule: memoryModule
            diskModule: diskModule
        }

        SoundTab {
            volumeModule: volumeModule
        }
    }
}
