import QtQuick
import QtTest
import "../package/contents/ui" as Shared

TestCase {
    id: testCase
    name: "KaraokeFill"
    when: windowShown
    visible: true
    width: 320
    height: 200
    Rectangle {
        id: surface
        width: 300
        height: 180
        color: "black"
        Text {
            id: verse
            width: 280
            text: "Hello world"
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font.pixelSize: 30
            lineHeight: 1.25
            color: "#333333"
        }
        Shared.KaraokeFill {
            id: fill
            textItem: verse
            words: [
                {
                    start: 0,
                    length: 11,
                    time: 1,
                    end: 3
                }
            ]
            position: 0
            highlight: "#00ff00"
        }
    }
    function greenPixels() {
        const shot = grabImage(surface);
        let count = 0;
        for (let y = 0; y < shot.height; y++)
            for (let x = 0; x < shot.width; x++)
                if (shot.green(x, y) > 100 && shot.red(x, y) < 50)
                    count++;
        return count;
    }
    function test_wipeAndSeek() {
        failOnWarning(/TypeError|ReferenceError|Unable|Binding loop/);
        wait(30);
        verify(fill.segments.length > 0);
        fill.position = 0;
        waitForRendering(surface);
        compare(greenPixels(), 0);
        fill.position = 2;
        waitForRendering(surface);
        const halfway = greenPixels();
        verify(halfway > 0);
        fill.position = 3;
        waitForRendering(surface);
        verify(greenPixels() > halfway * 1.3);
        fill.position = 0;
        waitForRendering(surface);
        compare(greenPixels(), 0, "Seeking backwards clears the fill immediately");
        verse.width = 100;
        wait(30);
        verify(fill.segments.length > 1, "A timed word range may cross wrapped rows");
        fill.reducedMotion = true;
        fill.position = 1.01;
        waitForRendering(surface);
        const reduced = greenPixels();
        fill.position = 3;
        waitForRendering(surface);
        compare(greenPixels(), reduced, "Reduced motion highlights the word without wiping");
    }
}
