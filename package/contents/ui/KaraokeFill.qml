pragma ComponentBehavior: Bound
import QtQuick

// Paint timed ranges over the original shaped text: wrapping, kerning and
// ligatures remain those of the full verse, not separately laid out words.
Item {
    id: root
    objectName: "karaokeFill"
    required property var textItem
    property var words: []
    property real position: 0
    property color highlight: "white"
    property bool reducedMotion: false
    property var segments: []
    anchors.fill: parent

    // TextEdit exposes shaped cursor geometry; Text does not. Keep a hidden,
    // non-interactive document with the same font, width and wrap policy.
    TextEdit {
        id: geometry
        visible: false
        width: root.textItem.width
        text: root.textItem.text
        textFormat: TextEdit.PlainText
        font: root.textItem.font
        wrapMode: TextEdit.Wrap
        horizontalAlignment: root.textItem.horizontalAlignment
        textMargin: 0
        padding: 0
        readOnly: true
        onContentHeightChanged: refresh.restart()
    }
    FontMetrics {
        id: metrics
        font: root.textItem.font
    }

    function rebuild() {
        const result = [];
        for (const word of words) {
            let segment = null;
            const pieces = [];
            for (let i = word.start; i < word.start + word.length; i++) {
                const a = geometry.positionToRectangle(i);
                const b = geometry.positionToRectangle(i + 1);
                if (Math.abs(a.y - b.y) > 1) {
                    b.x = a.x + metrics.advanceWidth(textItem.text.slice(i, i + 1));
                    b.y = a.y;
                }
                a.y *= textItem.lineHeight;
                b.y *= textItem.lineHeight;
                const left = Math.min(a.x, b.x);
                const right = Math.max(a.x, b.x);
                if (!segment || Math.abs(segment.y - a.y) > 1) {
                    segment = {
                        x: left,
                        y: a.y,
                        width: right - left,
                        height: a.height
                    };
                    pieces.push(segment);
                } else {
                    const edge = Math.max(segment.x + segment.width, right);
                    segment.x = Math.min(segment.x, left);
                    segment.width = edge - segment.x;
                }
            }
            const total = pieces.reduce((sum, piece) => sum + piece.width, 0);
            let covered = 0;
            for (const piece of pieces) {
                piece.time = word.time;
                piece.end = word.end;
                piece.from = total > 0 ? covered / total : 0;
                piece.span = total > 0 ? piece.width / total : 1;
                covered += piece.width;
                result.push(piece);
            }
        }
        segments = result;
    }
    onWordsChanged: refresh.restart()
    onWidthChanged: refresh.restart()
    onHeightChanged: refresh.restart()
    Component.onCompleted: refresh.restart()
    Connections {
        target: root.textItem
        function onContentWidthChanged() {
            refresh.restart();
        }
        function onContentHeightChanged() {
            refresh.restart();
        }
        function onFontChanged() {
            refresh.restart();
        }
        function onHorizontalAlignmentChanged() {
            refresh.restart();
        }
    }
    Timer {
        id: refresh
        interval: 0
        onTriggered: root.rebuild()
    }
    Repeater {
        model: root.segments
        delegate: Item {
            id: segment
            required property var modelData
            readonly property real wordProgress: root.position < modelData.time ? 0 : root.reducedMotion || modelData.end <= modelData.time ? 1 : Math.min(1, (root.position - modelData.time) / (modelData.end - modelData.time))
            readonly property real progress: Math.max(0, Math.min(1, (wordProgress - modelData.from) / Math.max(0.001, modelData.span)))
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
            visible: progress > 0 && width > 0
            Item {
                width: GraphicsInfo.api === GraphicsInfo.Software ? segment.width * segment.progress : segment.width
                height: segment.height
                clip: true
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: ShaderEffect {
                    property var source
                    property real progress: segment.progress
                    property vector2d pixelStep: Qt.vector2d(1 / Math.max(1, segment.width), 1 / Math.max(1, segment.height))
                    fragmentShader: Qt.resolvedUrl("../shaders/karaoke_fill.frag.qsb")
                }
                Text {
                    x: -segment.x
                    y: -segment.y
                    width: root.textItem.width
                    text: root.textItem.text
                    textFormat: Text.PlainText
                    wrapMode: root.textItem.wrapMode
                    horizontalAlignment: root.textItem.horizontalAlignment
                    font: root.textItem.font
                    lineHeight: root.textItem.lineHeight
                    renderType: root.textItem.renderType
                    color: root.highlight
                }
            }
        }
    }
}
