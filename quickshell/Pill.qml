import QtQuick

// One bar module: rounded surface background + optional label + extra children.
Rectangle {
    id: pill

    property string text: ""
    property color textColor: Theme.text
    property bool bold: false
    property bool plain: false              // no background (workspaces, title)
    default property alias content: row.data

    signal leftClicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int dir)                // +1 up, -1 down

    implicitWidth: row.implicitWidth + (plain ? 8 : 20)
    implicitHeight: 24
    radius: 8
    color: plain ? "transparent" : Theme.surface

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: pill.text !== ""
            text: pill.text
            color: pill.textColor
            font { family: Theme.font; pixelSize: Theme.fontSize; bold: pill.bold }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        property real acc: 0                 // touchpads send tiny deltas; add them up
        onClicked: m => m.button === Qt.RightButton ? pill.rightClicked()
                      : m.button === Qt.MiddleButton ? pill.middleClicked() : pill.leftClicked()
        onWheel: w => {
            acc += w.angleDelta.y
            while (Math.abs(acc) >= 120) { pill.scrolled(acc > 0 ? 1 : -1); acc -= acc > 0 ? 120 : -120 }
        }
    }
}
