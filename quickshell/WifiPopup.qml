import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi picker for iwd. Opened from the bar's network pill.
Scope {
    id: root

    readonly property bool open: Popups.current === "wifi"
    property bool powered: true
    property var networks: []        // [{connected, ssid, sec, dbm, known}]
    property var pendingNetworks: null   // update held back while the list is being dragged
    property bool scanning: false
    property string busySsid: ""
    property string expanded: ""
    property string message: ""
    property bool messageIsError: false

    readonly property string helper: Theme.scripts + "/iwd.sh"

    function signalIcon(dbm, secured) {
        const lvl = dbm >= -55 ? 3 : dbm >= -65 ? 2 : dbm >= -75 ? 1 : 0
        return Theme.icon([0xF091F, 0xF0922, 0xF0925, 0xF0928][lvl] + (secured ? 2 : 0))
    }
    function say(text, isError) { message = text; messageIsError = isError; msgTimer.restart() }
    function refresh() { if (!listProc.running) listProc.running = true }
    function rescan() {
        if (scanning || !powered) return
        scanning = true; scanProc.running = true
    }
    function parse(text) {
        const wasOff = !powered
        const nets = []
        for (const line of text.split("\n")) {
            const f = line.split("\x1f")
            if (f[0] === "P") powered = (f[1] === "on")
            else if (f[0] === "N")
                nets.push({ connected: f[1] === "1", ssid: f[2], sec: f[3],
                            dbm: parseInt(f[4]), known: f[5] === "1" })
        }
        nets.sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.dbm - a.dbm))
        setNetworks(nets)
        if (wasOff && powered && open) rescan()
    }
    // Only touch the model when something changed, and never mid-drag:
    // replacing it resets the ListView and makes it jump.
    function setNetworks(nets) {
        if (JSON.stringify(nets) === JSON.stringify(networks)) { pendingNetworks = null; return }
        if (netList.moving || netList.dragging) { pendingNetworks = nets; return }
        pendingNetworks = null
        networks = nets
    }
    function activate(net) {
        if (net.connected || busySsid !== "") return
        if (net.sec === "open" || net.known) connect(net.ssid, "")
        else if (net.sec === "psk") expanded = (expanded === net.ssid ? "" : net.ssid)
        else say(net.ssid + " uses " + net.sec + " — set it up with iwctl", true)
    }
    function connect(ssid, pass) {
        busySsid = ssid
        connectProc.environment = { "WIFI_PASS": pass }
        connectProc.command = ["bash", helper, "connect", ssid]
        connectProc.running = true
    }
    function run(args) {
        actionProc.command = ["bash", helper].concat(args)
        actionProc.running = true
    }

    onOpenChanged: {
        if (!open) return
        message = ""; expanded = ""
        refresh(); rescan()
    }

    Process {
        id: listProc
        command: ["bash", root.helper, "list"]
        stdout: StdioCollector { id: listOut; onStreamFinished: root.parse(listOut.text) }
    }
    Process {
        id: scanProc
        command: ["bash", root.helper, "scan"]
        onExited: scanDone.start()
    }
    Timer { id: scanDone; interval: 2500; onTriggered: { root.scanning = false; root.refresh() } }
    Process {
        id: connectProc
        stdout: StdioCollector {
            id: connectOut
            onStreamFinished: {
                const ssid = root.busySsid
                const res = connectOut.text.trim().split("\x1f")
                if (res[0] === "OK") { root.say("Connected to " + ssid, false); root.expanded = "" }
                else root.say(res[1] || "Couldn't connect to " + ssid, true)
                root.busySsid = ""
                root.refresh(); SysStatus.refreshNet()
            }
        }
    }
    Process {
        id: actionProc
        onExited: { root.refresh(); SysStatus.refreshNet() }
    }
    Timer { interval: 5000; repeat: true; running: root.open && root.busySsid === ""; onTriggered: root.refresh() }
    Timer { id: msgTimer; interval: 6000; onTriggered: root.message = "" }

    PopupPanel {
        name: "wifi"
        title: "Wi-Fi"
        headerItems: [
            SpinButton { visible: root.powered; spinning: root.scanning; onClicked: root.rescan() },
            Toggle { checked: root.powered; onToggled: root.run(["power", root.powered ? "off" : "on"]) }
        ]

        Text {
            width: parent.width
            visible: !root.powered || root.networks.length === 0
            horizontalAlignment: Text.AlignHCenter
            topPadding: 14; bottomPadding: 14
            text: !root.powered ? "Wi-Fi is off" : root.scanning ? "Scanning…" : "No networks found"
            color: Theme.dim
            font { family: Theme.font; pixelSize: 13 }
        }

        ListView {
            id: netList
            width: parent.width
            // exact height from the rows (46px + 2px spacing; expanded row +44px) —
            // ListView's own contentHeight is an estimate that shifts while overscrolling
            height: Math.min(root.networks.length * 48 - 2 + (root.expanded !== "" ? 44 : 0), 380)
            onMovementEnded: if (root.pendingNetworks) root.setNetworks(root.pendingNetworks)
            visible: root.powered && root.networks.length > 0
            clip: true
            spacing: 2
            model: root.networks

            SmoothScroll { flick: netList }

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool isExpanded: root.expanded === modelData.ssid
                readonly property bool isBusy: root.busySsid === modelData.ssid
                width: ListView.view.width
                height: isExpanded ? 90 : 46
                radius: 10
                clip: true
                color: modelData.connected ? Theme.accentBg
                     : ((rowArea.containsMouse && !ListView.view.moving) || isExpanded) ? Theme.overlay : "transparent"
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: row.modelData.connected ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.activate(row.modelData)
                }

                Item {
                    id: rowTop
                    width: parent.width; height: 46
                    Text {
                        id: sig
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        text: root.signalIcon(row.modelData.dbm, row.modelData.sec !== "open")
                        color: row.modelData.connected ? Theme.accent : Theme.text
                        font { family: Theme.font; pixelSize: 18 }
                    }
                    Column {
                        anchors {
                            left: sig.right; leftMargin: 12
                            right: trailing.left; rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: row.modelData.ssid
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13; bold: row.modelData.connected }
                        }
                        Text {
                            text: row.isBusy ? "Connecting…"
                                : row.modelData.connected ? "Connected"
                                : row.modelData.known ? "Saved"
                                : row.modelData.sec === "open" ? "Open" : "Secured"
                            color: row.isBusy || row.modelData.connected ? Theme.accent : Theme.dim
                            font { family: Theme.font; pixelSize: 11 }
                        }
                    }
                    RowButton {
                        id: trailing
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        visible: row.modelData.connected
                        label: "Disconnect"
                        danger: true
                        onClicked: root.run(["disconnect"])
                    }
                }

                Row {
                    visible: row.isExpanded
                    anchors { top: rowTop.bottom; left: parent.left; right: parent.right; margins: 10; topMargin: 0 }
                    spacing: 8

                    Rectangle {
                        width: parent.width - goBtn.width - parent.spacing
                        height: 32; radius: 8
                        color: Theme.mantle
                        border { color: pw.activeFocus ? Theme.accent : Theme.border; width: 1 }
                        TextInput {
                            id: pw
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.text; selectionColor: Theme.accent
                            font { family: Theme.font; pixelSize: 13 }
                            clip: true
                            onAccepted: if (text.length >= 8) root.connect(row.modelData.ssid, text)
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pw.text.length === 0
                                text: "Password"; color: Theme.dim
                                font: pw.font
                            }
                        }
                    }
                    Rectangle {
                        id: goBtn
                        width: 78; height: 32; radius: 8
                        readonly property bool ok: pw.text.length >= 8 && !row.isBusy
                        color: ok ? (goArea.containsMouse ? Theme.lavender : Theme.accent) : Theme.overlay
                        Text {
                            anchors.centerIn: parent
                            text: row.isBusy ? "…" : "Connect"
                            color: goBtn.ok ? Theme.surface : Theme.dim
                            font { family: Theme.font; pixelSize: 12; bold: true }
                        }
                        MouseArea {
                            id: goArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: goBtn.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (goBtn.ok) root.connect(row.modelData.ssid, pw.text)
                        }
                    }
                }
                onIsExpandedChanged: if (isExpanded) pw.forceActiveFocus(); else pw.text = ""
            }
        }

        Text {
            width: parent.width
            visible: root.message !== ""
            wrapMode: Text.Wrap
            text: root.message
            color: root.messageIsError ? Theme.red : Theme.green
            font { family: Theme.font; pixelSize: 11 }
        }
    }
}
