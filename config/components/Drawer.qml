pragma ComponentBehavior: Bound

import QtQuick

// Drawer attached to the bottom edge of the top bar strip.
//
// The drawer unrolls from the frame: its top edge is flush with the bar
// (no gap, square top corners, matching frame color at the top of the
// gradient) and its bottom corners are large and rounded. Opening and
// closing animate the height while content is clipped, so the panel reads
// as if it slides out of the frame itself.
//
// The owner is responsible for:
//   * geometry inputs (viewport size, attach offset, side inset),
//   * the `opened` flag and the `activeTab` id,
//   * closing on `closeRequested` (close button or Escape),
//   * mirroring x/y/width/height/cornerRadius into the window input mask.
//
// Pages are the default children. Each page must expose `property string
// tabId`; pages whose tabId does not match `activeTab` are hidden. Each
// page's implicitHeight drives the drawer height for its tab.
Item {
    id: root

    // Geometry, in parent (window) coordinates.
    property int viewportWidth: 1920
    property int viewportHeight: 1080
    property int attachY: 40
    property int sideInset: 16
    property int preferredWidth: 720
    property int cornerRadius: 26
    // Keep the drawer clear of the decorative side frame borders.
    readonly property int frameWidth: 10

    // Tabs: [{ id, label, icon, width? }]. The optional per-tab width
    // overrides `preferredWidth` while that tab is active, so a wide
    // page (e.g. the dashboard mosaic) can enlarge the drawer without
    // affecting the other tabs.
    property var tabs: []
    property string activeTab: root.tabs.length > 0 ? root.tabs[0].id : ""
    property bool opened: false
    readonly property alias hovered: drawerHover.hovered

    HoverHandler {
        id: drawerHover
    }

    signal closeRequested

    default property alias pages: contentArea.data

    // Theme literals kept in sync with the shared palette in Pill.qml
    // and the frame color in Bar.qml (Eww popup surface: flat #0f0f17,
    // no outline).
    readonly property color thFrame: "#0f0f17"
    readonly property color thAccent: "#a1bdce"
    readonly property color thAccentStrong: "#d7beda"
    readonly property color thText: "#bfc9db"
    readonly property color thMuted: "#6b7280"
    readonly property color thTabActive: "#26d7beda"
    readonly property color thTabHover: "#0fffffff"

    readonly property int headerHeight: 48

    readonly property int activeTabWidth: {
        for (let i = 0; i < root.tabs.length; i++) {
            const tab = root.tabs[i];
            if (tab.id === root.activeTab && tab.width !== undefined)
                return tab.width;
        }
        return root.preferredWidth;
    }

    x: Math.round((root.viewportWidth - root.width) / 2)
    y: root.attachY
    width: Math.min(root.activeTabWidth, Math.max(0, root.viewportWidth - 2 * root.sideInset))
    visible: root.openProgress > 0.001
    clip: true

    // Tab switches animate the width (and, through the x binding above,
    // the re-centering) together with the height animation below.
    Behavior on width {
        NumberAnimation {
            duration: 220
            easing.type: Easing.InOutQuad
        }
    }

    // Height of the active page's content. Tracked declaratively so live
    // updates (weather refresh, gauge samples) resize the drawer smoothly.
    readonly property real contentHeight: {
        let height = 0;
        const kids = contentArea.children;
        for (let i = 0; i < kids.length; i++) {
            const child = kids[i];
            if (child && child.tabId !== undefined && child.tabId === root.activeTab)
                height = Math.max(height, child.implicitHeight);
        }
        return height;
    }

    // Eased copy of contentHeight so switching tabs animates the height
    // without fighting the open/close progress animation below.
    property real animatedContentHeight: 0
    onContentHeightChanged: root.animatedContentHeight = root.contentHeight
    Behavior on animatedContentHeight {
        NumberAnimation {
            duration: 220
            easing.type: Easing.InOutQuad
        }
    }

    property real openProgress: 0
    onOpenedChanged: {
        if (root.opened) {
            closeAnim.stop();
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }
    NumberAnimation {
        id: openAnim
        target: root
        property: "openProgress"
        to: 1
        duration: 300
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: closeAnim
        target: root
        property: "openProgress"
        to: 0
        duration: 220
        easing.type: Easing.InCubic
    }

    height: Math.min(Math.round((root.headerHeight + root.animatedContentHeight) * root.openProgress), root.viewportHeight - root.attachY - root.frameWidth)

    Component.onCompleted: {
        const kids = contentArea.children;
        for (let i = 0; i < kids.length; i++) {
            const child = kids[i];
            if (!child || child.tabId === undefined)
                continue;
            child.width = Qt.binding(() => contentArea.width);
            child.height = Qt.binding(() => child.implicitHeight);
            child.visible = Qt.binding(() => root.activeTab === child.tabId);
        }
        root.animatedContentHeight = root.contentHeight;
    }

    // Bar.qml manages compositor focus while the drawer is open.
    focus: root.opened
    Keys.onEscapePressed: root.closeRequested()
    Keys.onLeftPressed: root.cycleTab(-1)
    Keys.onRightPressed: root.cycleTab(1)

    function cycleTab(direction) {
        if (root.tabs.length < 2)
            return;
        let index = 0;
        for (let i = 0; i < root.tabs.length; i++) {
            if (root.tabs[i].id === root.activeTab) {
                index = i;
                break;
            }
        }
        index = (index + direction + root.tabs.length) % root.tabs.length;
        root.activeTab = root.tabs[index].id;
    }

    // Borderless background joins the frame with rounded bottom corners.
    Canvas {
        id: background

        anchors.fill: parent
        onWidthChanged: this.requestPaint()
        onHeightChanged: this.requestPaint()

        onPaint: {
            const ctx = this.getContext("2d");
            ctx.reset();
            const w = this.width;
            const h = this.height;
            const r = Math.max(0, Math.min(root.cornerRadius, w / 2, h / 2));

            // Flat Eww popup surface; joins the frame color at the top.
            ctx.fillStyle = "#ff0f0f17";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h - r);
            ctx.quadraticCurveTo(w, h, w - r, h);
            ctx.lineTo(r, h);
            ctx.quadraticCurveTo(0, h, 0, h - r);
            ctx.closePath();
            ctx.fill();
        }
    }

    Row {
        id: tabBar

        x: 16
        y: (root.headerHeight - height) / 2
        spacing: 4

        Repeater {
            model: root.tabs

            delegate: Rectangle {
                id: tabButton

                required property var modelData

                readonly property bool active: root.activeTab === tabButton.modelData.id

                width: tabRow.implicitWidth + 26
                height: 32
                radius: 11
                color: tabButton.active ? root.thTabActive : tabMouse.containsMouse ? root.thTabHover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Row {
                    id: tabRow

                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        text: tabButton.modelData.icon
                        color: tabButton.active ? root.thAccentStrong : root.thMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: tabButton.modelData.label
                        color: tabButton.active ? root.thAccentStrong : tabMouse.containsMouse ? root.thText : root.thMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        renderType: Text.NativeRendering

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                }

                MouseArea {
                    id: tabMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.activeTab = tabButton.modelData.id
                }
            }
        }
    }

    Rectangle {
        id: closeButton

        anchors.right: parent.right
        anchors.rightMargin: 14
        y: (root.headerHeight - height) / 2
        width: 30
        height: 30
        radius: 15
        color: closeMouse.containsMouse ? root.thTabHover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: closeMouse.containsMouse ? root.thText : root.thMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            renderType: Text.NativeRendering

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        MouseArea {
            id: closeMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.closeRequested()
        }
    }

    Item {
        id: contentArea

        y: root.headerHeight
        width: root.width
        height: root.contentHeight
        opacity: root.openProgress
    }
}
