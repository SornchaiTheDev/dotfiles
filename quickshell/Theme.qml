pragma Singleton
import QtQuick
import Quickshell

// Catppuccin Mocha palette.
Singleton {
    readonly property color barBg:    "#d911111b"   // rgba(17,17,27,0.85)
    readonly property color surface:  "#1e1e2e"
    readonly property color card:     "#fc1e1e2e"
    readonly property color mantle:   "#181825"
    readonly property color overlay:  "#313244"
    readonly property color border:   "#45475a"
    readonly property color text:     "#cdd6f4"
    readonly property color subtext:  "#a6adc8"
    readonly property color dim:      "#6c7086"
    readonly property color accent:   "#89b4fa"
    readonly property color accentBg: "#2689b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color red:      "#f38ba8"
    readonly property color yellow:   "#f9e2af"
    readonly property color green:    "#a6e3a1"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // bar geometry
    readonly property int barHeight: 34
    readonly property int barMargin: 6
    readonly property int barSide: 8
    readonly property int popupTop: barMargin + barHeight + 6

    readonly property string scripts: Qt.resolvedUrl("scripts").toString().replace(/^file:\/\//, "")

    function icon(cp) { return String.fromCodePoint(cp) }
}
