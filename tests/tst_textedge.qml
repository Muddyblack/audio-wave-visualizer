import QtQuick
import QtQuick.Layouts
import QtTest
import "../package/contents/ui" as Ui

TestCase {
    name: "TextEdge"
    when: windowShown
    visible: true
    width: 300
    height: 200

    Item {
        id: host
        anchors.fill: parent
        Ui.TextEdge {
            id: edge
            target: label
            mode: "shadow"
        }
        ColumnLayout {
            id: column
            x: 12
            y: 20
            spacing: 0
            RowLayout {
                Item {
                    implicitWidth: 30
                    implicitHeight: 10
                }
                Text {
                    id: label
                    text: "Someone"
                    opacity: 0.6
                }
            }
        }
    }

    function init() {
        edge.mode = "shadow";
        label.visible = true;
        column.x = 12;
    }

    // The edge sits behind the text wherever nested layouts put it.
    function test_followsTargetThroughLayouts() {
        compare(edge.x, label.mapToItem(host, 0, 0).x);
        compare(edge.y, label.mapToItem(host, 0, 0).y);
        compare(edge.width, label.width);
        compare(edge.height, label.height);
        compare(edge.opacity, 0.6);
        column.x = 40;
        compare(edge.x, label.mapToItem(host, 0, 0).x);
    }

    // It never touches the text, and builds nothing while it would not show.
    function test_activeOnlyWhenItDraws() {
        verify(edge.active);
        compare(label.style, Text.Normal);
        compare(label.layer.enabled, false);
        edge.mode = "none";
        verify(!edge.active);
        edge.mode = "outline";
        verify(edge.active);
        label.visible = false;
        verify(!edge.active);
    }
}
