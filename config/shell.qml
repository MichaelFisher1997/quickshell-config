//@ pragma Env QT_NO_XDG_DESKTOP_PORTAL=1

import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {}
        }
    }
}
