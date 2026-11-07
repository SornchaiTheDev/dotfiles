//@ pragma UseQApplication
// Desktop shell: bar on every screen + Wi-Fi / Bluetooth popups.
// Run: qs        IPC: qs ipc call wifi toggle   |   qs ipc call bluetooth toggle
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    WifiPopup {}
    BluetoothPopup {}

    IpcHandler {
        target: "wifi"
        function toggle(): void { Popups.toggle("wifi", null) }
        function open(): void { Popups.screen = null; Popups.current = "wifi" }
        function close(): void { Popups.close() }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle(): void { Popups.toggle("bluetooth", null) }
        function open(): void { Popups.screen = null; Popups.current = "bluetooth" }
        function close(): void { Popups.close() }
    }
}
