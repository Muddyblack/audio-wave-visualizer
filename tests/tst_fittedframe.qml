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
        UI.CrispCanvas {
            id: crisp
            width: 40
            height: 20
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.scale(pixelScale, pixelScale);
                ctx.fillStyle = "red";
                ctx.fillRect(0, 0, 20, 20);
                ctx.fillStyle = "blue";
                ctx.fillRect(20, 0, 20, 20);
            }
        }
        UI.VectorIcon {
            id: vectorIcon
            x: 50
            width: 24
            height: 24
            color: "#00ff00"
            path: "M4 2 L22 12 L4 22 Z"
        }
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

    function test_canvasRasterizesAtFittedScale() {
        frame.designSize = Qt.size(360, 104);
        frame.width = 360;
        frame.height = 104;
        compare(crisp.pixelScale, 1);
        compare(crisp.canvasSize, Qt.size(40, 20));
        frame.width = 720;
        frame.height = 208;
        fuzzyCompare(frame.fitScale, 2, 0.0001);
        compare(crisp.pixelScale, 2);
        compare(crisp.canvasSize, Qt.size(80, 40));
        // A shrunken card never rasterizes below its design size.
        frame.width = 180;
        frame.height = 52;
        compare(crisp.pixelScale, 1);
    }

    function test_scaledCanvasShowsWholeDrawing() {
        frame.designSize = Qt.size(360, 104);
        frame.width = 720;
        frame.height = 208;
        crisp.requestPaint();
        tryVerify(() => {
            const picture = grabImage(frame);
            const left = crisp.mapToItem(frame, 10, 10);
            const right = crisp.mapToItem(frame, 30, 10);
            const sx = Screen.devicePixelRatio;
            const sy = Screen.devicePixelRatio;
            return picture.red(Math.round(left.x * sx), Math.round(left.y * sy)) > 240 && picture.blue(Math.round(right.x * sx), Math.round(right.y * sy)) > 240;
        });
    }

    function test_vectorIconScalesAndChangesPath() {
        frame.designSize = Qt.size(360, 104);
        frame.width = 720;
        frame.height = 208;
        vectorIcon.path = "M4 2 L22 12 L4 22 Z";
        const point = vectorIcon.mapToItem(frame, 12, 12);
        tryVerify(() => {
            const picture = grabImage(frame);
            const x = Math.round(point.x * Screen.devicePixelRatio);
            const y = Math.round(point.y * Screen.devicePixelRatio);
            return picture.green(x, y) > 240 && picture.red(x, y) < 20;
        });
        vectorIcon.path = "M4 2 H9 V22 H4 Z M15 2 H20 V22 H15 Z";
        tryVerify(() => {
            const picture = grabImage(frame);
            return picture.red(Math.round(point.x * Screen.devicePixelRatio), Math.round(point.y * Screen.devicePixelRatio)) > 240;
        });
    }

    function test_canvasResolutionBudget() {
        frame.designSize = Qt.size(360, 104);
        frame.width = 3600;
        frame.height = 1040;
        compare(crisp.pixelScale, 4);
        crisp.width = 800;
        verify(crisp.canvasSize.width <= 2048);
        crisp.width = 40;
        frame.width = 361;
        frame.height = 104 * 361 / 360;
        compare(crisp.pixelScale, 1);
        frame.width = 450;
        frame.height = 130;
        compare(crisp.pixelScale, 1.25);
        crisp.maxPixelScale = 1.5;
        frame.width = 1080;
        frame.height = 312;
        compare(crisp.pixelScale, 1.5);
        crisp.maxPixelScale = 4;
    }
}
