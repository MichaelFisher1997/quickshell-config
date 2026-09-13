import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: 32

                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#1e1e2e"

                    Text {
                        anchors.centerIn: parent
                        color: "#cdd6f4"
                        font.family: "monospace"
                        text: Qt.formatDateTime(clock.date, "ddd dd MMM  hh:mm:ss")
                    }
                }
            }
        }
    }
}
