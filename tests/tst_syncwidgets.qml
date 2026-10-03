import QtQuick
import QtTest
import "../package/contents/code/SyncWidgets.js" as SyncWidgets

TestCase {
    name: "SyncWidgets"
    function test_valuesSkipPlacementAndFlattenColours() {
        const result = SyncWidgets.values({
            monitor: 2,
            hAnchor: "left",
            bgColor: Qt.rgba(1, 0, 0, 1),
            numBars: 24,
            userPresets: ["a"]
        }, ["monitor", "hAnchor"]);
        compare(Object.keys(result).sort(), ["bgColor", "numBars", "userPresets"]);
        compare(typeof result.bgColor, "string");
    }
    function test_scriptTargetsOtherWidgetsOfThisPlugin() {
        const script = SyncWidgets.script("org.example.viz", 42, {
            title: "café \"x\"",
            n: 3
        });
        verify(script.indexOf('"org.example.viz"') !== -1);
        verify(script.indexOf("w.id===42") !== -1);
        verify(!/[^\x00-\x7f]/.test(script));
        verify(script.indexOf("\\u00e9") !== -1);
        verify(script.indexOf('{"title":"caf\\u00e9 \\"x\\"","n":3}') !== -1);
        console.log("SCRIPT:" + script);
    }
    function test_commandCarriesTheScriptAsBase64() {
        const command = SyncWidgets.command("p", 1, {
            a: 1
        });
        const encoded = /printf %s (\S+) \|/.exec(command)[1];
        compare(Qt.atob(encoded), SyncWidgets.script("p", 1, {
            a: 1
        }));
    }
}
