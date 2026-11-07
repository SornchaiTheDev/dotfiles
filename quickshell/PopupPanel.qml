import QtQuick
import Quickshell
import Quickshell.Wayland

// Card popup under the bar's right side. Click outside or Esc closes it.
// Children go below the header; header controls go in `headerItems`.
PanelWindow {
    id: panel

    required property string name           // key in Popups.current
    property string title: ""
    property int cardWidth: 340
    default property alias content: body.data
    property alias headerItems: headerRow.data
    readonly property bool shown: Popups.current === name

    visible: shown
    screen: Popups.screen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-" + name

    onShownChanged: if (shown) openAnim.restart()

    MouseArea { anchors.fill: parent; onClicked: Popups.close() }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Popups.close()

        Rectangle {
            id: card
            anchors { top: parent.top; right: parent.right; topMargin: Theme.popupTop; rightMargin: Theme.barSide }
            width: panel.cardWidth
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

            MouseArea { anchors.fill: parent }   // swallow clicks inside the card

            Column {
                id: body
                anchors { fill: parent; margins: 14 }
                spacing: 10

                Item {
                    width: parent.width; height: 26
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: panel.title; color: Theme.text
                        font { family: Theme.font; pixelSize: 15; bold: true }
                    }
                    Row {
                        id: headerRow
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 10
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.overlay }
            }
        }
    }
}
