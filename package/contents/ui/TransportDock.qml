import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Effects

Item {
    id: root

    required property var configuration
    property var player: null
    property bool isPlaying: false
    property color controlColor: "#ffffff"

    implicitWidth: 88
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        // Darker, cleaner glass: a deeper translucent base reads as
        // a single calm surface against busy album art, instead of
        // the milky look a light tint gives over a bright cover.
        color: root.configuration.useSystemDockBg ? Qt.rgba(0, 0, 0, 0.28) : root.configuration.customDockBgColor
        border.color: Qt.rgba(1, 1, 1, 0.16)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowOpacity: 0.35
            shadowBlur: 0.25
            shadowVerticalOffset: 1
        }

        // Soft top highlight — the glassy sheen catching light.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            anchors.topMargin: 1
            height: 1
            radius: 0.5
            color: Qt.rgba(1, 1, 1, 0.18)
        }
    }

    RowLayout {
        id: controlRow
        anchors.centerIn: parent
        spacing: 2

        // Previous Button
        Item {
            id: prevBtn
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            scale: prevArea.pressed ? 0.94 : (prevArea.containsMouse ? 1.07 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }

            Canvas {
                id: prevIcon
                anchors.centerIn: parent
                width: 12
                height: 12
                opacity: prevArea.containsMouse ? 1.0 : 0.78
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = root.controlColor;
                    ctx.beginPath();
                    ctx.moveTo(10, 1.5);
                    ctx.lineTo(1.5, 6);
                    ctx.lineTo(10, 10.5);
                    ctx.closePath();
                    ctx.fill();
                }
                Connections {
                    target: root
                    function onControlColorChanged() {
                        prevIcon.requestPaint();
                    }
                }
            }
            MouseArea {
                id: prevArea
                objectName: "prevArea"
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const p = root.player;
                    if (!p || p.canGoPrevious === false)
                        return;
                    if (p.previous)
                        p.previous();
                    else if (p.Previous)
                        p.Previous();
                }
            }
        }

        // Play/Pause Button
        Item {
            id: playBtn
            Layout.preferredWidth: 26
            Layout.preferredHeight: 22
            scale: playArea.pressed ? 0.94 : (playArea.containsMouse ? 1.06 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }

            Canvas {
                id: playIcon
                anchors.centerIn: parent
                width: 12
                height: 12
                opacity: playArea.containsMouse ? 1.0 : 0.86
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = root.controlColor;
                    if (root.isPlaying) {
                        // Draw two vertical pause bars
                        ctx.fillRect(2, 1, 3.5, 10);
                        ctx.fillRect(6.5, 1, 3.5, 10);
                    } else {
                        // Draw play triangle
                        ctx.beginPath();
                        ctx.moveTo(2.5, 1);
                        ctx.lineTo(10.5, 6);
                        ctx.lineTo(2.5, 11);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
                Connections {
                    target: root
                    function onIsPlayingChanged() {
                        playIcon.requestPaint();
                    }
                    function onControlColorChanged() {
                        playIcon.requestPaint();
                    }
                }
            }
            MouseArea {
                id: playArea
                objectName: "playArea"
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const p = root.player;
                    if (!p || p.canTogglePlaying === false)
                        return;
                    if (p.togglePlaying)
                        p.togglePlaying();
                    else if (p.playPause)
                        p.playPause();
                    else if (p.PlayPause)
                        p.PlayPause();
                    else if (root.isPlaying)
                        (p.pause || p.Pause || function () {})();
                    else
                        (p.play || p.Play || function () {})();
                }
            }
        }

        // Next Button
        Item {
            id: nextBtn
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            scale: nextArea.pressed ? 0.94 : (nextArea.containsMouse ? 1.07 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }

            Canvas {
                id: nextIcon
                anchors.centerIn: parent
                width: 12
                height: 12
                opacity: nextArea.containsMouse ? 1.0 : 0.78
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = root.controlColor;
                    ctx.beginPath();
                    ctx.moveTo(2, 1.5);
                    ctx.lineTo(10.5, 6);
                    ctx.lineTo(2, 10.5);
                    ctx.closePath();
                    ctx.fill();
                }
                Connections {
                    target: root
                    function onControlColorChanged() {
                        nextIcon.requestPaint();
                    }
                }
            }
            MouseArea {
                id: nextArea
                objectName: "nextArea"
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const p = root.player;
                    if (!p || p.canGoNext === false)
                        return;
                    if (p.next)
                        p.next();
                    else if (p.Next)
                        p.Next();
                }
            }
        }
    }
}
