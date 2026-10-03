import QtQuick
import QtTest
import "../package/contents/ui" as UI

TestCase {
    name: "FittedFrame"
    when: windowShown
    visible: true
    width: 800
    height: 800

    UI.FittedFrame {
        id: frame
        property int clicks: 0
        MouseArea {
            id: button
            x: 100
            y: 200
            width: 50
            height: 30
            onClicked: frame.clicks++
        }
    }

    function init() {
        frame.fitContents = true;
        frame.contentRotation = 0;
    }
    function test_sidewaysContentAndInput_data() {
        return [
            {
                tag: "left",
                angle: -90
            },
            {
                tag: "right",
                angle: 90
            }
        ];
    }
    function test_sidewaysContentAndInput(data) {
        frame.designSize = Qt.size(250, 332);
        frame.contentRotation = data.angle;
        frame.width = 166;
        frame.height = 125;
        wait(0);
        compare(frame.implicitWidth, 332);
        compare(frame.implicitHeight, 250);
        compare(frame.fitScale, 0.5);
        const canvas = findChild(frame, "fittedCanvas");
        for (const point of [[0, 0], [250, 0], [0, 332], [250, 332]]) {
            const mapped = canvas.mapToItem(frame, point[0], point[1]);
            verify(mapped.x >= -0.01 && mapped.x <= frame.width + 0.01);
            verify(mapped.y >= -0.01 && mapped.y <= frame.height + 0.01, "Mapped y=" + mapped.y + "; canvas=" + canvas.x + "," + canvas.y + " " + canvas.width + "x" + canvas.height + "; rotation=" + canvas.rotation);
        }
        const target = button.mapToItem(frame, 25, 15);
        const before = frame.clicks;
        mouseClick(frame, target.x, target.y);
        compare(frame.clicks, before + 1);
    }
    function test_readingLayoutReflows() {
        frame.designSize = Qt.size(380, 320);
        frame.width = 500;
        frame.height = 180;
        frame.fitContents = false;
        const canvas = findChild(frame, "fittedCanvas");
        compare(canvas.width, 500);
        compare(canvas.height, 180);
        compare(frame.fitScale, 1, "Reading text must not shrink with the host height");
    }
    function test_preservesProportions_data() {
        return [
            {
                tag: "wide-host",
                w: 700,
                h: 400
            },
            {
                tag: "tall-host",
                w: 300,
                h: 700
            },
            {
                tag: "small-host",
                w: 160,
                h: 180
            }
        ];
    }

    function test_preservesProportions(data) {
        frame.width = data.w;
        frame.height = data.h;
        frame.designSize = Qt.size(250, 332);
        wait(0);
        const canvas = findChild(frame, "fittedCanvas");
        const start = canvas.mapToItem(frame, 0, 0);
        const end = canvas.mapToItem(frame, canvas.width, canvas.height);
        verify(start.x >= -0.01 && start.y >= -0.01);
        verify(end.x <= frame.width + 0.01 && end.y <= frame.height + 0.01);
        fuzzyCompare((end.x - start.x) / (end.y - start.y), 250 / 332, 0.0001);
        const target = button.mapToItem(frame, 25, 15);
        const before = frame.clicks;
        mouseClick(frame, target.x, target.y);
        compare(frame.clicks, before + 1);
        // Switching back to a horizontal preset uses the same stored host size.
        frame.designSize = Qt.size(360, 104);
        compare(frame.width, data.w);
        compare(frame.height, data.h);
        fuzzyCompare(frame.fitScale, Math.min(data.w / 360, data.h / 104), 0.0001);
    }
}
