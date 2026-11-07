import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth

PanelWindow {
    id: bar
    required property ShellScreen modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: Theme.barMargin; left: Theme.barSide; right: Theme.barSide }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    Rectangle { anchors.fill: parent; radius: 12; color: Theme.barBg }

    // ───────────── left: workspaces + window title ─────────────
    Row {
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 6

        Row {
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: Niri.workspacesOn(bar.screen.name)
                Pill {
                    required property var modelData
                    plain: true
                    implicitWidth: 24
                    text: modelData.is_active ? "●" : "○"
                    textColor: modelData.is_urgent ? Theme.red
                             : (modelData.is_active || modelData.is_focused) ? Theme.accent : Theme.subtext
                    onLeftClicked: Niri.focusWorkspace(modelData)
                }
            }
        }

        Pill {
            plain: true
            anchors.verticalCenter: parent.verticalCenter
            readonly property string full: Niri.titleOn(bar.screen.name)
            text: full.length > 60 ? full.slice(0, 59) + "…" : full
            textColor: Theme.subtext
        }
    }

    // ───────────── center: clock ─────────────
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Pill {
        id: clockPill
        anchors.centerIn: parent
        plain: true
        bold: true
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        onLeftClicked: calendar.toggle()
    }
    CalendarPopup { id: calendar; anchorItem: clockPill }

    // ───────────── right ─────────────
    Row {
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 6

        // tray
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            visible: SystemTray.items.values.length > 0
            Row {
                spacing: 8
                Repeater {
                    model: SystemTray.items
                    Item {
                        id: trayItem
                        required property SystemTrayItem modelData
                        width: 16; height: 16
                        IconImage {
                            id: trayIcon
                            anchors.fill: parent
                            source: {
                                let icon = trayItem.modelData.icon
                                if (icon.includes("?path=")) {
                                    const [name, path] = icon.split("?path=")
                                    icon = `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`
                                }
                                return icon
                            }
                        }
                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayItem.modelData.menu
                            anchor.item: trayIcon
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            anchor.margins.top: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: m => {
                                const it = trayItem.modelData
                                if (m.button === Qt.MiddleButton) it.secondaryActivate()
                                else if (m.button === Qt.RightButton || it.onlyMenu) { if (it.hasMenu) trayMenu.open() }
                                else it.activate()
                            }
                        }
                    }
                }
            }
        }

        // keyboard layout
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            visible: Niri.layoutNames.length > 1
            text: Niri.layoutShort
            onLeftClicked: Niri.switchLayout()
        }

        // volume
        Pill {
            id: vol
            anchors.verticalCenter: parent.verticalCenter
            readonly property PwNode sink: Pipewire.defaultAudioSink
            readonly property bool ready: sink !== null && sink.audio !== null
            readonly property real level: ready ? sink.audio.volume : 0
            readonly property bool headphones:
                ready && /head(phone|set)/i.test((sink.properties["device.icon-name"] || "") + " " + sink.description)
            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

            visible: ready
            text: !ready ? "" : sink.audio.muted ? "󰝟 muted"
                : (headphones ? "󰋋" : ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor(level * 3))])
                  + " " + Math.round(level * 100) + "%"
            textColor: ready && sink.audio.muted ? Theme.subtext : Theme.text
            onLeftClicked: bar.sh("pavucontrol")
            onRightClicked: if (ready) sink.audio.muted = !sink.audio.muted
            onScrolled: dir => { if (ready) sink.audio.volume = Math.max(0, Math.min(1, Math.round((level + dir * 0.05) * 20) / 20)) }
        }

        // brightness
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            visible: SysStatus.brightness >= 0
            text: "󰃠 " + SysStatus.brightness + "%"
            onScrolled: dir => SysStatus.changeBrightness(dir)
        }

        // network
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: SysStatus.netKind === "wifi" ? "󰖩 " + SysStatus.ssid
                : SysStatus.netKind === "ethernet" ? "󰈀 wired" : "󰖪 offline"
            textColor: SysStatus.netKind === "offline" ? Theme.subtext : Theme.text
            onLeftClicked: Popups.toggleWifi(bar.screen)
            onRightClicked: bar.sh("iwctl station wlan0 scan")
        }

        // bluetooth
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property int connected: adapter ? adapter.devices.values.filter(d => d.connected).length : 0
            visible: adapter !== null
            text: !adapter || !adapter.enabled ? "󰂲" : connected > 0 ? "󰂱 " + connected : "󰂯"
            textColor: adapter && adapter.enabled ? Theme.text : Theme.subtext
        }

        // battery
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            readonly property var dev: UPower.displayDevice
            readonly property int pct: dev ? Math.round(dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage) : 0
            readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging
                                                  || dev.state === UPowerDeviceState.FullyCharged
                                                  || dev.state === UPowerDeviceState.PendingCharge)
            visible: dev !== null && dev.isPresent
            text: (charging ? "󰂄" : ["󰁺", "󰁼", "󰁾", "󰂀", "󰁹"][Math.min(4, Math.floor(pct / 20))]) + " " + pct + "%"
            textColor: charging ? Theme.text : pct <= 10 ? Theme.red : pct <= 25 ? Theme.yellow : Theme.text
        }

        // notifications (swaync)
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: SysStatus.notifDnd ? "󰂛" : "󰂚"
            onLeftClicked: bar.sh("swaync-client -t -sw")
            onRightClicked: bar.sh("swaync-client -d -sw")
            Text {
                visible: SysStatus.notifPending
                y: -4
                text: "●"; color: Theme.red
                font { family: Theme.font; pixelSize: 8 }
            }
        }

        // power
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰐥"
            textColor: Theme.red
            onLeftClicked: bar.sh(Theme.scripts + "/power-menu.sh")
        }
    }
}
