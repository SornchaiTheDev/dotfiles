pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live niri state from `niri msg --json event-stream`.
Singleton {
    id: niri

    property var workspaces: []      // niri workspace objects
    property var windows: ({})       // id -> window object
    property var layoutNames: []
    property int layoutIdx: 0
    property var layoutCodes: []     // from niri config: layout "us,th"

    readonly property string layoutShort:
        layoutCodes[layoutIdx] ?? (layoutNames[layoutIdx] ?? "").slice(0, 2).toLowerCase()

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx)
    }
    function titleOn(output) {
        const ws = workspaces.find(w => w.output === output && w.is_active)
        const win = ws && ws.active_window_id != null ? windows[ws.active_window_id] : null
        return win ? (win.title || win.app_id || "") : "Desktop"
    }
    function focusWorkspace(ws) {
        Quickshell.execDetached(["sh", "-c",
            `niri msg action focus-monitor '${ws.output}' && niri msg action focus-workspace ${ws.idx}`])
    }
    function switchLayout() {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"])
    }

    function setWindows(fn) { const w = Object.assign({}, windows); fn(w); windows = w }

    function handle(ev) {
        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces
        } else if (ev.WorkspaceActivated) {
            const { id, focused } = ev.WorkspaceActivated
            const out = (workspaces.find(w => w.id === id) || {}).output
            workspaces = workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === out ? w.id === id : w.is_active,
                is_focused: focused ? w.id === id : w.is_focused,
            }))
        } else if (ev.WorkspaceActiveWindowChanged) {
            const e = ev.WorkspaceActiveWindowChanged
            workspaces = workspaces.map(w => w.id === e.workspace_id
                ? Object.assign({}, w, { active_window_id: e.active_window_id }) : w)
        } else if (ev.WorkspaceUrgencyChanged) {
            const e = ev.WorkspaceUrgencyChanged
            workspaces = workspaces.map(w => w.id === e.id ? Object.assign({}, w, { is_urgent: e.urgent }) : w)
        } else if (ev.WindowsChanged) {
            const w = {}
            for (const win of ev.WindowsChanged.windows) w[win.id] = win
            windows = w
        } else if (ev.WindowOpenedOrChanged) {
            const win = ev.WindowOpenedOrChanged.window
            setWindows(w => w[win.id] = win)
        } else if (ev.WindowClosed) {
            setWindows(w => delete w[ev.WindowClosed.id])
        } else if (ev.KeyboardLayoutsChanged) {
            layoutNames = ev.KeyboardLayoutsChanged.keyboard_layouts.names
            layoutIdx = ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx
        } else if (ev.KeyboardLayoutSwitched) {
            layoutIdx = ev.KeyboardLayoutSwitched.idx
        }
    }

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: data => { try { niri.handle(JSON.parse(data)) } catch (e) { console.warn("niri:", e) } }
        }
        onExited: restart.start()   // niri restarted / socket hiccup
    }
    Timer { id: restart; interval: 1000; onTriggered: stream.running = true }

    Process {
        running: true
        command: ["sh", "-c", "grep -hoE 'layout +\"[^\"]+\"' ~/.config/niri/*.kdl | head -1 | cut -d'\"' -f2"]
        stdout: StdioCollector {
            id: layoutOut
            onStreamFinished: niri.layoutCodes = layoutOut.text.trim().split(",").filter(s => s)
        }
    }
}
