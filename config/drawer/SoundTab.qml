pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Quickshell
import Quickshell.Bluetooth

Item {
    id: root

    property string tabId: "sound"
    required property var volumeModule
    readonly property var knownDevices: Bluetooth.devices.values.filter(device => device.paired || device.trusted || device.connected)
    // Theme literals kept in sync with the shared palette in Pill.qml
    // (Eww audio box: eww.scss .audio-box / scale trough rules).
    readonly property color thText: "#bfc9db"
    readonly property color thMuted: "#6b7280"
    readonly property color thAccent: "#a1bdce"
    readonly property color thFaint: "#3e424f"

    implicitHeight: content.implicitHeight + 40

    component ActionButton: Controls.Button {
        id: button
        implicitHeight: 32
        implicitWidth: Math.max(88, implicitContentWidth + 24)
        opacity: enabled ? 1 : 0.45
        contentItem: Text {
            text: button.text
            color: root.thAccent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 10
            color: button.down ? "#14ffffff" : button.hovered ? "#0fffffff" : "#22242b"
        }
    }

    ColumnLayout {
        id: content
        x: 24
        y: 16
        width: root.width - 48
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: "DEFAULT OUTPUT"
                    color: root.thFaint
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
                Text {
                    Layout.fillWidth: true
                    text: !root.volumeModule.available ? "Audio unavailable" : root.volumeModule.description || "Output name unavailable"
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: root.thText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 17
                }
            }
            ActionButton {
                text: "Settings"
                onClicked: Quickshell.execDetached(["pavucontrol"])
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            ActionButton {
                text: root.volumeModule.muted ? "Unmute" : "Mute"
                enabled: root.volumeModule.available
                onClicked: root.volumeModule.toggleMute()
            }
            Controls.Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
                enabled: root.volumeModule.available
                implicitHeight: 32
                property real requestedVolume: value
                // Commit the final drag value, not every pointer movement.
                onPressedChanged: {
                    if (pressed)
                        requestedVolume = value;
                    else if (enabled)
                        root.volumeModule.setVolume(requestedVolume);
                }
                onMoved: {
                    requestedVolume = value;
                    if (!pressed)
                        root.volumeModule.setVolume(requestedVolume);
                }
                Binding {
                    target: volumeSlider
                    property: "value"
                    value: root.volumeModule.volume
                    when: !volumeSlider.pressed
                    restoreMode: Binding.RestoreNone
                }
                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: (volumeSlider.height - height) / 2
                    width: volumeSlider.availableWidth
                    height: 6
                    radius: 3
                    // Eww scale trough.
                    color: "#22242b"
                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        // Eww volume gradient: #afcee0 -> #77a5bf.
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0
                                color: "#afcee0"
                            }
                            GradientStop {
                                position: 1
                                color: "#77a5bf"
                            }
                        }
                        visible: !root.volumeModule.muted
                    }
                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        color: root.thMuted
                        visible: root.volumeModule.muted
                    }
                }
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: (volumeSlider.height - height) / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: "#a1bdce"
                }
            }
            Text {
                Layout.preferredWidth: 100
                text: !root.volumeModule.available ? "Unavailable" : Math.round(volumeSlider.pressed ? volumeSlider.value : root.volumeModule.volume) + "%" + (root.volumeModule.muted ? " / muted" : "")
                color: root.thText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }
        }

        Text {
            visible: root.volumeModule.commandError.length > 0
            text: root.volumeModule.commandError
            color: "#e06c75"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }

        Text {
            text: "KNOWN BLUETOOTH DEVICES"
            color: root.thFaint
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }

        Text {
            Layout.fillWidth: true
            text: Bluetooth.adapters.values.length === 0 ? "Bluetooth unavailable: no adapter or BlueZ service" : Bluetooth.adapters.values.map(adapter => adapter.name + ": " + BluetoothAdapterState.toString(adapter.state)).join("  /  ")
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            color: root.thMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }

        Text {
            visible: root.knownDevices.length === 0 && Bluetooth.adapters.values.length > 0
            text: "No known devices. Pair devices in your Bluetooth manager."
            color: root.thMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }

        ListView {
            id: devices
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(256, contentHeight)
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: root.knownDevices
            Controls.ScrollBar.vertical: Controls.ScrollBar {}

            delegate: Rectangle {
                id: deviceRow
                required property BluetoothDevice modelData
                readonly property bool pending: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                width: devices.width
                height: 64
                radius: 12
                color: "#22242b"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.name || deviceRow.modelData.address
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: root.thText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.fillWidth: true
                            text: BluetoothDeviceState.toString(deviceRow.modelData.state) + (deviceRow.modelData.blocked ? " / Blocked" : "") + (deviceRow.modelData.connected ? " / " + (deviceRow.modelData.batteryAvailable ? Math.round(deviceRow.modelData.battery * 100) + "% battery" : "Battery unavailable") : "")
                            elide: Text.ElideRight
                            color: deviceRow.modelData.connected ? root.thAccent : root.thMuted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                    }
                    ActionButton {
                        text: deviceRow.pending ? "Pending..." : deviceRow.modelData.connected ? "Disconnect" : "Connect"
                        enabled: !deviceRow.pending && !deviceRow.modelData.blocked && deviceRow.modelData.adapter !== null && deviceRow.modelData.adapter.state === BluetoothAdapterState.Enabled
                        onClicked: {
                            if (deviceRow.modelData.connected)
                                deviceRow.modelData.disconnect();
                            else
                                deviceRow.modelData.connect();
                        }
                    }
                }
            }
        }
    }
}
