pragma Singleton
import QtQuick
import Quickshell

// Which popup is open ("" = none), and on which screen. Only one at a time.
Singleton {
    property string current: ""
    property var screen: null

    function toggle(name, scr) {
        if (current === name) { current = ""; return }
        screen = scr
        current = name
    }
    function close() { current = "" }
}
