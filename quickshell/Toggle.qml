import QtQuick

// On/off switch.
Rectangle {
    id: sw
    property bool checked: false
    signal toggled()

    width: 40; height: 22; radius: 11
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: checked ? Theme.accent : Theme.overlay
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 16; height: 16; radius: 8
        y: 3; x: sw.checked ? sw.width - width - 3 : 3
        color: sw.checked ? Theme.surface : Theme.subtext
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled() }
}
