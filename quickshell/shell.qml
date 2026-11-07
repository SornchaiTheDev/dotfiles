//@ pragma UseQApplication
// Desktop shell: bar on every screen + Wi-Fi popup.
// Run: qs        IPC: qs ipc call wifi toggle
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    WifiPopup {}

    IpcHandler {
        target: "wifi"
        function toggle(): void { Popups.toggleWifi(null) }
        function open(): void { Popups.wifiScreen = null; Popups.wifiOpen = true }
        function close(): void { Popups.wifiOpen = false }
    }
}
