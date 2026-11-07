import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Wi-Fi picker for iwd. Opened from the bar's network pill (Popups.toggleWifi).
Scope {
    id: root

    readonly property bool open: Popups.wifiOpen
    property bool powered: true
    property var networks: []        // [{connected, ssid, sec, dbm, known}]
    property bool scanning: false
    property string busySsid: ""
    property string expanded: ""
    property string message: ""
    property bool messageIsError: false

    readonly property string helper: Theme.scripts + "/iwd.sh"

    function close() { Popups.wifiOpen = false }
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
        networks = nets
        if (wasOff && powered && open) rescan()
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
        openAnim.restart()
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

    PanelWindow {
        visible: root.open
        screen: Popups.wifiScreen
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-wifi"

        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()

            Rectangle {
                id: card
                anchors { top: parent.top; right: parent.right; topMargin: Theme.popupTop; rightMargin: Theme.barSide }
                width: 340
                height: body.implicitHeight + 28
                radius: 14
                color: Theme.card
                border { color: Theme.border; width: 1 }
                transformOrigin: Item.TopRight

                ParallelAnimation {
                    id: openAnim
                    NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 140 }
                    NumberAnimation { target: card; property: "scale"; from: 0.96; to: 1; duration: 180; easing.type: Easing.OutCubic }
                }

                MouseArea { anchors.fill: parent }

                Column {
                    id: body
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    Item {
                        width: parent.width; height: 26
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Wi-Fi"; color: Theme.text
                            font { family: Theme.font; pixelSize: 15; bold: true }
                        }
                        Row {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 10

                            Rectangle {
                                width: 26; height: 26; radius: 8
                                visible: root.powered
                                color: "transparent"
                                Text {
                                    id: rescanIcon
                                    anchors.centerIn: parent
                                    text: Theme.icon(0xF0450)
                                    color: root.scanning ? Theme.accent : Theme.subtext
                                    font { family: Theme.font; pixelSize: 16 }
                                    RotationAnimation on rotation {
                                        running: root.scanning; loops: Animation.Infinite
                                        from: 0; to: 360; duration: 900
                                        onRunningChanged: if (!running) rescanIcon.rotation = 0
                                    }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.rescan() }
                            }

                            Rectangle {
                                width: 40; height: 22; radius: 11
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.powered ? Theme.accent : Theme.overlay
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Rectangle {
                                    width: 16; height: 16; radius: 8
                                    y: 3; x: root.powered ? parent.width - width - 3 : 3
                                    color: root.powered ? Theme.surface : Theme.subtext
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.run(["power", root.powered ? "off" : "on"])
                                }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.overlay }

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
                        width: parent.width
                        height: Math.min(contentHeight, 380)
                        visible: root.powered && root.networks.length > 0
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.networks

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
                                 : (rowArea.containsMouse || isExpanded) ? Theme.overlay : "transparent"
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
                                Rectangle {
                                    id: trailing
                                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    visible: row.modelData.connected
                                    width: visible ? discText.implicitWidth + 18 : 0; height: 26; radius: 8
                                    color: discArea.containsMouse ? "#33f38ba8" : "transparent"
                                    border { color: discArea.containsMouse ? Theme.red : Theme.border; width: 1 }
                                    Text {
                                        id: discText; anchors.centerIn: parent
                                        text: "Disconnect"; color: discArea.containsMouse ? Theme.red : Theme.subtext
                                        font { family: Theme.font; pixelSize: 11 }
                                    }
                                    MouseArea {
                                        id: discArea; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.run(["disconnect"])
                                    }
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
        }
    }
}
