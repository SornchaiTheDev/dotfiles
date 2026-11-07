import QtQuick

// Small outlined text button used at the end of popup rows (Disconnect, Forget…).
Rectangle {
    id: btn
    property string label: ""
    property bool danger: false               // red on hover
    readonly property bool hovered: area.containsMouse
    signal clicked()

    readonly property color hot: danger ? Theme.red : Theme.accent
    width: visible ? text.implicitWidth + 18 : 0
    height: 26; radius: 8
    color: area.containsMouse ? Qt.rgba(hot.r, hot.g, hot.b, 0.2) : "transparent"
    border { color: area.containsMouse ? hot : Theme.border; width: 1 }

    Text {
        id: text
        anchors.centerIn: parent
        text: btn.label
        color: area.containsMouse ? btn.hot : Theme.subtext
        font { family: Theme.font; pixelSize: 11 }
    }
    MouseArea {
        id: area; anchors.fill: parent
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
