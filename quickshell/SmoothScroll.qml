import QtQuick

// Wheel/touchpad scrolling with momentum (keeps gliding after you stop) and a
// rubber-band overscroll, for any Flickable / ListView.
// Put it inside the flickable:  SmoothScroll { flick: myList }
Item {
    id: ss
    required property Flickable flick

    // ── tuning ──
    property real wheelStep: 1.6          // px per angleDelta unit (mouse: 120/notch ≈ 190px)
    property real touchpadSpeed: 2.6      // multiplier for pixelDelta (touchpads)
    property real momentum: 1.3           // how far it glides after you stop (0 = no glide)
    property real friction: 6             // how fast the glide slows down (higher = shorter)
    property real resistance: 0.35        // how much a push moves the list past the edge
    property real maxOverscroll: 90       // px

    width: 0; height: 0; visible: false

    readonly property real maxY: Math.max(0, flick.contentHeight - flick.height) + flick.originY
    readonly property real minY: flick.originY

    property real velocity: 0             // px/s, positive = content moves up (scrolling down)
    property real lastEventMs: 0
    property bool touchpadActive: false

    function outOfBounds(y) { return y < minY || y > maxY }

    // where contentY ends up after moving by d, with resistance past the edges
    function move(from, d) {
        let t = from + d
        if (from >= minY && from <= maxY) {
            if (t < minY) t = minY + (t - minY) * resistance
            else if (t > maxY) t = maxY + (t - maxY) * resistance
        } else if ((from < minY && d < 0) || (from > maxY && d > 0)) {
            t = from + d * resistance
        }
        return Math.max(minY - maxOverscroll, Math.min(maxY + maxOverscroll, t))
    }

    function springBack() {
        if (glide.running || touchpadActive) return
        const y = flick.contentY
        if (!outOfBounds(y)) return
        bounce.to = y < minY ? minY : maxY
        bounce.restart()
    }

    function startGlide() {
        bounce.stop()
        if (Math.abs(velocity) < 20) { velocity = 0; springBack(); return }
        if (!glide.running) glide.start()
    }

    function stopAll() { glide.stop(); bounce.stop(); velocity = 0 }

    Component.onCompleted: {
        flick.boundsBehavior = Flickable.DragAndOvershootBounds
        flick.flickDeceleration = 2200
        flick.maximumFlickVelocity = 5000
    }

    // a mouse drag takes over from any glide in progress
    Connections {
        target: ss.flick
        function onDraggingChanged() { if (ss.flick.dragging) ss.stopAll() }
    }

    // momentum loop: exponential slow-down, much stronger past the edges
    FrameAnimation {
        id: glide
        onTriggered: {
            const dt = Math.min(frameTime, 0.05)
            const y = ss.flick.contentY
            const out = ss.outOfBounds(y)
            ss.velocity *= Math.exp(-(out ? ss.friction * 4 : ss.friction) * dt)
            const ny = ss.move(y, ss.velocity * dt)
            ss.flick.contentY = ny
            const stuck = Math.abs(ny - y) < 0.01 && out
            if (Math.abs(ss.velocity) < 15 || stuck) {
                stop(); ss.velocity = 0; ss.springBack()
            }
        }
    }

    NumberAnimation {
        id: bounce
        target: ss.flick; property: "contentY"
        duration: 380; easing.type: Easing.OutCubic
    }

    // fingers lifted (touchpads don't always send an explicit end event)
    function endTouch() {
        touchEnd.stop()
        touchpadActive = false
        velocity *= momentum
        startGlide()
    }
    Timer { id: touchEnd; interval: 70; onTriggered: ss.endTouch() }

    WheelHandler {
        parent: ss.flick
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            e.accepted = true
            const now = Date.now()
            const dtMs = Math.max(8, now - ss.lastEventMs)
            ss.lastEventMs = now

            const touchpad = e.pixelDelta.x !== 0 || e.pixelDelta.y !== 0
            const d = touchpad ? -e.pixelDelta.y * ss.touchpadSpeed : -e.angleDelta.y * ss.wheelStep

            if (d === 0) {
                // end-of-gesture event from a touchpad -> glide
                if (ss.touchpadActive) ss.endTouch()
                return
            }

            if (touchpad) {
                // follow the fingers 1:1, track their speed for the glide
                glide.stop(); bounce.stop()
                ss.touchpadActive = true
                const inst = d / (dtMs / 1000)
                ss.velocity = dtMs > 100 ? inst : ss.velocity * 0.5 + inst * 0.5
                ss.flick.contentY = ss.move(ss.flick.contentY, d)
                touchEnd.restart()
            } else {
                // mouse notch: push the list; it travels ~momentum × d while slowing down
                if (Math.sign(d) !== Math.sign(ss.velocity)) ss.velocity = 0
                ss.velocity = Math.max(-9000, Math.min(9000,
                    ss.velocity + d * ss.friction * Math.max(1, ss.momentum)))
                ss.startGlide()
            }
        }
    }
}
