import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    name: "StereoCapture"
    Component {
        id: component
        StereoCapture {
            active: true
            commandSourceComponent: Component {
                Item {
                    signal newData(string source, var data)
                }
            }
        }
    }
    function test_frameValidationAndHistory() {
        const capture = createTemporaryObject(component, this);
        const now = Date.now() / 1000;
        const frame = Array(32).fill("0.5:-0.5").join(";");
        capture.accept(frame, now);
        compare(capture.samples.length, 32);
        compare(capture.samples[0], [.5, -.5]);
        compare(capture.previous.length, 0);
        capture.accept(frame, now + .01);
        compare(capture.previous.length, 32);
        capture.accept(frame, now - 5);
        compare(capture.samples.length, 0);
        compare(capture.previous.length, 0);
        for (const invalid of ["NaN:0", "1.2:0", "0", "0:0:0", ""]) {
            capture.accept(Array(32).fill(invalid).join(";"), now + .02);
            compare(capture.samples.length, 0);
        }
        capture.accept(frame, now + .03);
        capture.active = false;
        compare(capture.samples.length, 0);
        capture.accept(frame, now + .04);
        compare(capture.samples.length, 0);
    }
}
