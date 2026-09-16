pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Controls

// Shared interaction surface for every built-in linear progress style.
Item {
    id: root
    required property var clock
    property var chapters: []
    property color accentColor: "#b4befe"
    property color textColor: "white"
    property real wheelStep: 5
    property bool reducedMotion: false
    property bool hoverTips: true
    property bool gestures: true
    property real trackCenter: 5
    property real fraction: 0
    readonly property bool containsMouse: area.containsMouse
    property bool scrubbing: false
    property real speed: 1
    property real _lastX: 0
    property real _pressX: 0
    property real _pressY: 0
    property bool _dragged: false
    property real _clickFraction: 0
    property real jumpOpacity: 0
    property real jumpDirection: 0
    readonly property real targetSeconds: fraction * clock.lengthValue / clock.unitsPerSecond
    readonly property real deltaSeconds: targetSeconds - clock.displayedPosition / clock.unitsPerSecond
    readonly property string speedText: speed === 1 ? "1×" : speed === .5 ? "½×" : speed === .25 ? "¼×" : "fine"
    readonly property string chapterTitle: {
        let title = "";
        for (const c of chapters) {
            if (c.start > targetSeconds)
                break;
            title = c.title;
        }
        return title;
    }
    readonly property string hoverText: clock.formatTime(Math.floor(targetSeconds)) + "  " + (deltaSeconds >= 0 ? "+" : "−") + clock.formatTime(Math.round(Math.abs(deltaSeconds))) + (scrubbing ? "  ·  " + speedText : "") + (chapterTitle ? "\n" + chapterTitle : "")
    function clamp(value) {
        return Math.max(0, Math.min(1, value));
    }
    function clickTarget(f) {
        let start = -1;
        const seconds = f * clock.lengthValue / clock.unitsPerSecond;
        for (const chapter of chapters) {
            if (chapter.start > seconds)
                break;
            start = chapter.start;
        }
        return start >= 0 ? start * clock.unitsPerSecond / clock.lengthValue : f;
    }
    function cancel() {
        clickDelay.stop();
        scrubbing = false;
        _dragged = false;
        jumpOpacity = 0;
    }
    function move(x, y) {
        if (!scrubbing) {
            fraction = clamp(x / Math.max(1, width));
            return;
        }
        const distance = Math.abs(y - trackCenter);
        speed = distance > 140 ? .1 : distance > 80 ? .25 : distance > 35 ? .5 : 1;
        if (Math.hypot(x - _pressX, y - _pressY) > 3)
            _dragged = true;
        fraction = clamp(fraction + (x - _lastX) / Math.max(1, width) * speed);
        _lastX = x;
    }
    function jump(seconds) {
        clickDelay.stop();
        if (clock.seekRelative(seconds)) {
            jumpDirection = seconds;
            jumpOpacity = 1;
            feedback.restart();
        }
    }
    onVisibleChanged: {
        if (!visible)
            cancel();
    }
    Connections {
        target: root.clock
        function onTrackChanged() {
            root.cancel();
        }
        function onPlayerChanged() {
            root.cancel();
        }
    }
    Timer {
        id: clickDelay
        interval: 400
        onTriggered: root.clock.seekToFraction(root._clickFraction)
    }
    NumberAnimation {
        id: feedback
        target: root
        property: "jumpOpacity"
        to: 0
        duration: root.reducedMotion ? 1 : 550
    }
    Rectangle {
        objectName: "ghostPlayhead"
        visible: (area.containsMouse || root.scrubbing) && root.clock.canSeek
        x: root.fraction * root.width - .5
        y: root.trackCenter - 6
        width: 1
        height: 12
        color: root.textColor
        opacity: .45
    }
    Rectangle {
        objectName: "seekTooltip"
        z: 20
        visible: opacity > 0
        opacity: (root.scrubbing || (root.hoverTips && area.containsMouse)) && root.clock.canSeek ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.reducedMotion ? 0 : 100
            }
        }
        width: Math.min(root.width, label.implicitWidth + 18)
        height: label.implicitHeight + 10
        x: Math.max(0, Math.min(root.width - width, root.fraction * root.width - width / 2))
        y: -height - 5
        radius: 10
        color: "#e6202330"
        border.color: "#50ffffff"
        Text {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 12)
            textFormat: Text.PlainText
            text: root.hoverText
            color: root.textColor
            font.pixelSize: 10
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }
    Rectangle {
        visible: root.jumpOpacity > 0
        opacity: root.jumpOpacity * .4
        x: root.jumpDirection > 0 ? root.width * .67 : 0
        width: root.width / 3
        height: 16
        radius: 8
        color: root.accentColor
        Text {
            anchors.centerIn: parent
            text: root.jumpDirection > 0 ? "+10s  ››" : "‹‹  −10s"
            color: root.textColor
            font.pixelSize: 9
        }
    }
    Rectangle {
        visible: root.clock.validLoop
        x: root.clock.loopStart * root.width
        width: (root.clock.loopEnd - root.clock.loopStart) * root.width
        y: root.trackCenter - 3
        height: 6
        radius: 3
        color: root.accentColor
        opacity: root.clock.loopEnabled ? .35 : .12
    }
    MouseArea {
        id: area
        objectName: "pbArea"
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: root.enabled && root.visible && root.clock.canSeek
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.fraction = root.clamp(mouse.x / Math.max(1, width));
            if (mouse.button === Qt.RightButton) {
                clickDelay.stop();
                menu.popup();
                return;
            }
            root._lastX = mouse.x;
            root._pressX = mouse.x;
            root._pressY = mouse.y;
            root._dragged = false;
            root.speed = 1;
            root.scrubbing = true;
        }
        onPositionChanged: mouse => root.move(mouse.x, mouse.y)
        onReleased: mouse => {
            if (mouse.button !== Qt.LeftButton)
                return;
            root.scrubbing = false;
            if (root._dragged) {
                clickDelay.stop();
                root.clock.seekToFraction(root.fraction);
            }
        }
        onCanceled: root.cancel()
        onClicked: mouse => {
            if (mouse.button !== Qt.LeftButton || root._dragged)
                return;
            root._clickFraction = root.clickTarget(root.fraction);
            if (root.gestures && (root.fraction < 1 / 3 || root.fraction > 2 / 3))
                clickDelay.restart();
            else
                root.clock.seekToFraction(root._clickFraction);
        }
        onDoubleClicked: mouse => {
            clickDelay.stop();
            if (root.gestures && mouse.button === Qt.LeftButton && (mouse.x < width / 3 || mouse.x > width * 2 / 3))
                root.jump(mouse.x < width / 3 ? -10 : 10);
        }
        onWheel: wheel => {
            if (!root.gestures || root.wheelStep <= 0) {
                wheel.accepted = false;
                return;
            }
            const steps = wheel.angleDelta.y ? wheel.angleDelta.y / 120 : wheel.pixelDelta.y / 40;
            clickDelay.stop();
            wheel.accepted = root.clock.seekRelative(steps * root.wheelStep);
        }
    }
    Repeater {
        model: root.chapters
        Rectangle {
            id: chapterTick
            required property var modelData
            x: root.clock.totalSeconds > 0 ? modelData.start * root.clock.unitsPerSecond / root.clock.lengthValue * root.width - 1 : 0
            y: root.trackCenter - 4
            width: 2
            height: 8
            color: root.textColor
            opacity: .65
            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                enabled: root.enabled && root.visible && root.clock.canSeek
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    clickDelay.stop();
                    root.clock.seekToFraction(chapterTick.modelData.start * root.clock.unitsPerSecond / root.clock.lengthValue);
                }
            }
        }
    }
    Repeater {
        model: root.clock.validLoop ? 2 : root.clock.loopStart >= 0 ? 1 : 0
        Rectangle {
            required property int index
            objectName: index ? "loopB" : "loopA"
            x: (index ? root.clock.loopEnd : root.clock.loopStart) * root.width - 5
            y: root.trackCenter - 11
            width: 10
            height: 13
            radius: 2
            color: root.accentColor
            Text {
                anchors.centerIn: parent
                text: parent.index ? "B" : "A"
                color: "#14151c"
                font.pixelSize: 8
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.enabled && root.visible && root.clock.canSeek
                preventStealing: true
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const f = root.clamp(mapToItem(root, mouse.x, 0).x / Math.max(1, root.width));
                    const gap = Math.min(1, root.clock.unitsPerSecond / root.clock.lengthValue);
                    if (parent.index)
                        root.clock.loopEnd = Math.max(root.clock.loopStart + gap, f);
                    else
                        root.clock.loopStart = Math.min(root.clock.loopEnd >= 0 ? root.clock.loopEnd - gap : 1 - gap, f);
                }
            }
        }
    }
    Controls.Menu {
        id: menu
        Controls.MenuItem {
            text: "Set loop start (A)"
            onTriggered: {
                root.clock.clearLoop();
                root.clock.loopStart = root.fraction;
            }
        }
        Controls.MenuItem {
            text: "Set loop end (B)"
            enabled: root.clock.loopStart >= 0 && root.fraction > root.clock.loopStart + root.clock.unitsPerSecond / root.clock.lengthValue
            onTriggered: {
                root.clock.loopEnd = root.fraction;
                root.clock.loopEnabled = true;
            }
        }
        Controls.MenuItem {
            text: root.clock.loopEnabled ? "Pause A–B loop" : "Enable A–B loop"
            enabled: root.clock.validLoop
            onTriggered: root.clock.loopEnabled = !root.clock.loopEnabled
        }
        Controls.MenuItem {
            text: "Clear A–B loop"
            enabled: root.clock.loopStart >= 0
            onTriggered: root.clock.clearLoop()
        }
    }
}
