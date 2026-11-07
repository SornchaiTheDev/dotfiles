pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Small polled / streamed system state: network, brightness, swaync.
Singleton {
    id: st

    // network
    property string netKind: "offline"     // wifi | ethernet | offline
    property string ssid: ""
    function refreshNet() { if (!netProc.running) netProc.running = true }

    // brightness (0-100, -1 = no backlight)
    property int brightness: -1
    function changeBrightness(delta) {
        Quickshell.execDetached(["brightnessctl", "-q", "set", delta > 0 ? "+5%" : "5%-"])
        brightness = Math.max(0, Math.min(100, brightness + (delta > 0 ? 5 : -5)))
        briDelay.restart()
    }

    // notifications
    property bool notifDnd: false
    property bool notifPending: false

    Process {
        id: netProc
        command: ["bash", Theme.scripts + "/iwd.sh", "status"]
        stdout: StdioCollector {
            id: netOut
            onStreamFinished: {
                const f = netOut.text.trim().split("\x1f")
                st.netKind = f[0] || "offline"
                st.ssid = f[1] || ""
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: st.refreshNet() }

    Process {
        id: briProc
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            id: briOut
            onStreamFinished: {
                const m = briOut.text.match(/,(\d+)%,/)
                st.brightness = m ? parseInt(m[1]) : -1
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: if (!briProc.running) briProc.running = true }
    Timer { id: briDelay; interval: 150; onTriggered: briProc.running = true }

    Process {
        id: swaync
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const alt = JSON.parse(data).alt || ""
                    st.notifDnd = alt.startsWith("dnd")
                    st.notifPending = alt.endsWith("notification")
                } catch (e) {}
            }
        }
        onExited: swayncRestart.start()
    }
    Timer { id: swayncRestart; interval: 2000; onTriggered: swaync.running = true }
}
