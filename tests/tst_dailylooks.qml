import QtQuick
import QtTest
import "../package/contents/ui/studio" as Studio
import "../package/contents/ui/studio/Schema.js" as Schema

TestCase {
    name: "DailyLooks"
    property var defaults
    Component {
        id: scheduler
        Studio.DailyLookController {
            property int applications: 0
            onApply: next => {
                applications++;
                configuration = next;
            }
        }
    }
    function initTestCase() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        xhr.send();
        defaults = Schema.defaultsFromXml(xhr.responseText);
    }
    function test_dateSeedAndExchange() {
        const first = Schema.dailyLook("2026-09-16");
        compare(JSON.stringify(first), JSON.stringify(Schema.dailyLook("2026-09-16")));
        verify(JSON.stringify(first.s) !== JSON.stringify(Schema.dailyLook("2026-09-17").s));
        compare(Schema.localDay(new Date(2026, 0, 2, 23, 59)), "2026-01-02");
        const settings = Object.assign({}, defaults, first.s, {
            autoDailyLook: true,
            dailyLookApplied: "2026-09-16",
            favoritePresets: '["glass"]'
        });
        const decoded = Schema.importPreset(Schema.exportPreset("Daily", settings, defaults), defaults);
        compare(decoded.settings.autoDailyLook, undefined);
        compare(decoded.settings.dailyLookApplied, undefined);
        compare(decoded.settings.favoritePresets, undefined);
        compare(decoded.settings.customColor, first.s.customColor);
    }
    function test_onlyOnceAndPreservePreferences() {
        const current = Object.assign({}, defaults, {
            autoDailyLook: true,
            inputSource: "my-monitor",
            framerate: 27,
            sensitivity: 123,
            userPresets: '[{"name":"Saved","settings":{}}]',
            favoritePresets: '["glass"]',
            customVisualizers: "trusted.qml",
            verticalPosition: 0.3,
            widgetWidth: 700,
            monitor: "DP-2"
        });
        const next = Schema.dailyUpdate(defaults, current, "2026-09-16");
        for (const key of ["inputSource", "framerate", "sensitivity", "userPresets", "favoritePresets", "customVisualizers", "verticalPosition", "widgetWidth", "monitor"])
            compare(next[key], current[key], key);
        compare(next.dailyLookApplied, "2026-09-16");
        next.customColor = "#123456";
        compare(Schema.dailyUpdate(defaults, next, "2026-09-16"), null);
        const tomorrow = Schema.dailyUpdate(defaults, next, "2026-09-17");
        compare(tomorrow.dailyLookApplied, "2026-09-17");
        verify(tomorrow.customColor !== "#123456");
        next.autoDailyLook = false;
        compare(Schema.dailyUpdate(defaults, next, "2026-09-17"), null);
    }
    function test_schedulerPersistsDateAcrossRestart() {
        const first = createTemporaryObject(scheduler, this, {
            defaults: defaults,
            configuration: Object.assign({}, defaults, {
                autoDailyLook: true
            })
        });
        verify(first !== null);
        tryCompare(first, "applications", 1);
        first.check();
        compare(first.applications, 1);
        const restarted = createTemporaryObject(scheduler, this, {
            defaults: defaults,
            configuration: first.configuration
        });
        verify(restarted !== null);
        restarted.check();
        compare(restarted.applications, 0);
    }
    function test_schedulerLoadsPackagedDefaults() {
        const item = createTemporaryObject(scheduler, this, {
            configuration: Object.assign({}, defaults, {
                autoDailyLook: true
            })
        });
        verify(item !== null);
        tryCompare(item, "applications", 1);
        compare(item.defaults.showMpris, defaults.showMpris);
    }
}
