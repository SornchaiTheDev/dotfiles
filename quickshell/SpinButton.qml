import QtQuick

// Icon button whose icon spins while `spinning` (rescan / discover).
Item {
    id: btn
    property string icon: Theme.icon(0xF0450)   // nf-md-refresh
    property bool spinning: false
    signal clicked()

    width: 26; height: 26
    Text {
        id: glyph
        anchors.centerIn: parent
        text: btn.icon
        color: btn.spinning ? Theme.accent : Theme.subtext
        font { family: Theme.font; pixelSize: 16 }
        RotationAnimation on rotation {
            running: btn.spinning; loops: Animation.Infinite
            from: 0; to: 360; duration: 900
            onRunningChanged: if (!running) glyph.rotation = 0
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
