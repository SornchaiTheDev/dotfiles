import QtQuick
import Quickshell

// Month calendar shown under the clock.
PopupWindow {
    id: cal
    required property Item anchorItem

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
    implicitWidth: 268
    implicitHeight: body.implicitHeight + 28
    color: "transparent"
    grabFocus: true
    visible: false

    property int year: 0
    property int month: 0
    function toggle() {
        if (visible) { visible = false; return }
        const now = new Date(); year = now.getFullYear(); month = now.getMonth()
        visible = true
    }
    function shift(n) {
        const d = new Date(year, month + n, 1); year = d.getFullYear(); month = d.getMonth()
    }
    readonly property var cells: {
        const first = new Date(year, month, 1)
        const offset = (first.getDay() + 6) % 7          // Monday first
        const today = new Date().toDateString()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - offset + i)
            out.push({ day: d.getDate(), inMonth: d.getMonth() === month, today: d.toDateString() === today })
        }
        return out
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.card
        border { color: Theme.border; width: 1 }

        Column {
            id: body
            anchors { fill: parent; margins: 14 }
            spacing: 8

            Item {
                width: parent.width; height: 24
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(cal.year, cal.month, 1), "MMMM yyyy")
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 14; bold: true }
                }
                Repeater {
                    model: [{ dir: -1, glyph: "󰅁" }, { dir: 1, glyph: "󰅂" }]
                    Text {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        x: modelData.dir < 0 ? 4 : parent.width - width - 4
                        text: modelData.glyph; color: Theme.subtext
                        font { family: Theme.font; pixelSize: 16 }
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: cal.shift(parent.modelData.dir) }
                    }
                }
            }

            Grid {
                columns: 7
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        required property string modelData
                        width: 34; height: 22
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        text: modelData; color: Theme.dim
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }
                Repeater {
                    model: cal.cells
                    Rectangle {
                        required property var modelData
                        width: 34; height: 30; radius: 8
                        color: modelData.today ? Theme.accent : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.day
                            color: parent.modelData.today ? Theme.surface
                                 : parent.modelData.inMonth ? Theme.text : Theme.border
                            font { family: Theme.font; pixelSize: 12; bold: parent.modelData.today }
                        }
                    }
                }
            }
        }
    }
}
