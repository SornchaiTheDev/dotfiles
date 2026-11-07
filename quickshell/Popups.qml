pragma Singleton
import QtQuick
import Quickshell

// Which popups are open, and on which screen.
Singleton {
    property bool wifiOpen: false
    property var wifiScreen: null

    function toggleWifi(screen) {
        if (wifiOpen) { wifiOpen = false; return }
        wifiScreen = screen
        wifiOpen = true
    }
}
