pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root

    property var lastActive: null

    readonly property var player: {
        const values = Mpris.players.values;
        const lastKnown = root.lastActive !== null && values.indexOf(root.lastActive) !== -1 ? root.lastActive : null;
        if (lastKnown !== null && lastKnown.playbackState === MprisPlaybackState.Playing)
            return lastKnown;
        const playing = values.find(candidate => candidate.playbackState === MprisPlaybackState.Playing);
        if (playing !== undefined)
            return playing;
        return lastKnown !== null ? lastKnown : (values.length > 0 ? values[0] : null);
    }

    property Instantiator activeTracker: Instantiator {
        model: Mpris.players

        delegate: Connections {
            required property var modelData

            target: modelData

            function onTrackChanged() {
                root.lastActive = modelData;
            }

            function onPlaybackStateChanged() {
                root.lastActive = modelData;
            }
        }
    }
}
