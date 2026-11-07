import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth popup: power, discovery, connect / disconnect / pair / forget.
Scope {
    id: root

    readonly property bool open: Popups.current === "bluetooth"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false

    readonly property var allDevices: adapter ? adapter.devices.values : []
    // Sorted by name only, so connect/disconnect doesn't rebuild the list.
    readonly property var paired: allDevices.filter(d => d.paired)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var available: allDevices
        .filter(d => !d.paired && d.deviceName !== "" && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
        .sort((a, b) => a.name.localeCompare(b.name))

    property string pendingPair: ""      // address we asked to pair; connect once paired
    property bool weStartedDiscovery: false
    property string message: ""
    property bool messageIsError: false

    function say(text, isError) { message = text; messageIsError = isError; msgTimer.restart() }
    function startDiscovery() {
        if (adapter && enabled && !adapter.discovering) { adapter.discovering = true; weStartedDiscovery = true }
    }
    function stopDiscovery() {
        if (adapter && weStartedDiscovery && adapter.discovering) adapter.discovering = false
        weStartedDiscovery = false
    }
    function deviceIcon(icon) {
        const i = icon || ""
        if (/headset|headphone/.test(i))      return Theme.icon(0xF02CB)  // headphones
        if (/audio|speaker|card/.test(i))     return Theme.icon(0xF04C3)  // speaker
        if (/mouse/.test(i))                  return Theme.icon(0xF037D)  // mouse
        if (/keyboard/.test(i))               return Theme.icon(0xF030C)  // keyboard
        if (/gaming|joystick/.test(i))        return Theme.icon(0xF0297)  // gamepad
        if (/phone/.test(i))                  return Theme.icon(0xF011C)  // cellphone
        if (/computer/.test(i))               return Theme.icon(0xF0322)  // laptop
        return Theme.icon(0xF00AF)                                        // bluetooth
    }
    function batteryText(d) {
        if (!d.batteryAvailable) return ""
        return " · " + Math.round(d.battery <= 1 ? d.battery * 100 : d.battery) + "%"
    }

    onOpenChanged: {
        if (open) { message = ""; startDiscovery() }
        else stopDiscovery()
    }
    onEnabledChanged: if (open && enabled) startDiscovery()

    Timer { id: msgTimer; interval: 6000; onTriggered: root.message = "" }

    // One device row. `pairedList` rows connect/disconnect; others pair.
    component DeviceRow: Rectangle {
        id: row
        required property var modelData
        readonly property var dev: modelData
        readonly property int st: dev.state
        readonly property bool connecting: st === BluetoothDeviceState.Connecting
        readonly property bool disconnecting: st === BluetoothDeviceState.Disconnecting
        readonly property bool pairing: dev.pairing
        property int prevState: -1

        width: parent ? parent.width : 0
        height: 46
        radius: 10
        color: dev.connected ? Theme.accentBg : area.containsMouse ? Theme.overlay : "transparent"

        Component.onCompleted: {
            prevState = st
            // finished pairing (row moved into "My devices"): trust + connect
            if (dev.paired && root.pendingPair === dev.address) {
                root.pendingPair = ""
                dev.trusted = true
                dev.connect()
            }
        }
        onStChanged: {
            if (prevState === BluetoothDeviceState.Connecting && st === BluetoothDeviceState.Disconnected)
                root.say("Couldn't connect to " + dev.name, true)
            else if (prevState === BluetoothDeviceState.Connecting && st === BluetoothDeviceState.Connected)
                root.say("Connected to " + dev.name, false)
            prevState = st
        }
        onPairingChanged: {
            if (!pairing && !dev.paired && root.pendingPair === dev.address) {
                root.pendingPair = ""
                root.say("Pairing with " + dev.name + " failed", true)
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.dev.connected ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: {
                const d = row.dev
                if (d.connected || row.connecting || row.pairing) return
                if (d.paired) d.connect()
                else { root.pendingPair = d.address; d.pair() }
            }
        }

        Text {
            id: ico
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text: root.deviceIcon(row.dev.icon)
            color: row.dev.connected ? Theme.accent : Theme.text
            font { family: Theme.font; pixelSize: 18 }
        }
        Column {
            anchors {
                left: ico.right; leftMargin: 12
                right: buttons.left; rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: row.dev.name
                color: Theme.text
                font { family: Theme.font; pixelSize: 13; bold: row.dev.connected }
            }
            Text {
                text: row.pairing ? "Pairing…"
                    : row.connecting ? "Connecting…"
                    : row.disconnecting ? "Disconnecting…"
                    : row.dev.connected ? "Connected" + root.batteryText(row.dev)
                    : row.dev.paired ? "Paired" : "Tap to pair"
                color: row.pairing || row.connecting || row.dev.connected ? Theme.accent : Theme.dim
                font { family: Theme.font; pixelSize: 11 }
            }
        }
        Row {
            id: buttons
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 6
            RowButton {
                visible: row.dev.connected
                label: "Disconnect"; danger: true
                onClicked: row.dev.disconnect()
            }
            RowButton {
                id: forgetBtn
                visible: row.dev.paired && !row.dev.connected && (area.containsMouse || forgetBtn.hovered)
                label: "Forget"; danger: true
                onClicked: { root.say("Forgot " + row.dev.name, false); row.dev.forget() }
            }
        }
    }

    component SectionLabel: Text {
        width: parent ? parent.width : 0
        leftPadding: 4; topPadding: 2
        color: Theme.dim
        font { family: Theme.font; pixelSize: 11; bold: true }
    }

    PopupPanel {
        name: "bluetooth"
        title: "Bluetooth"
        headerItems: [
            SpinButton {
                visible: root.enabled
                icon: Theme.icon(0xF0450)
                spinning: root.discovering
                onClicked: root.discovering ? root.stopDiscovery() : root.startDiscovery()
            },
            Toggle {
                checked: root.enabled
                onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }
        ]

        Text {
            width: parent.width
            visible: !root.adapter || !root.enabled
            horizontalAlignment: Text.AlignHCenter
            topPadding: 14; bottomPadding: 14
            text: !root.adapter ? "No Bluetooth adapter" : "Bluetooth is off"
            color: Theme.dim
            font { family: Theme.font; pixelSize: 13 }
        }

        Flickable {
            width: parent.width
            height: Math.min(contentHeight, 420)
            visible: root.enabled
            contentHeight: lists.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: lists
                width: parent.width
                spacing: 2

                SectionLabel { text: "MY DEVICES"; visible: root.paired.length > 0 }
                Repeater { model: root.paired; DeviceRow {} }

                Item { width: 1; height: 8; visible: root.paired.length > 0 }

                SectionLabel { text: root.discovering ? "AVAILABLE  ·  searching…" : "AVAILABLE" }
                Repeater { model: root.available; DeviceRow {} }
                Text {
                    width: parent.width
                    visible: root.available.length === 0
                    leftPadding: 4; topPadding: 6; bottomPadding: 6
                    text: root.discovering ? "Looking for devices…" : "Press  " + Theme.icon(0xF0450) + "  to search"
                    color: Theme.dim
                    font { family: Theme.font; pixelSize: 12 }
                }
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
