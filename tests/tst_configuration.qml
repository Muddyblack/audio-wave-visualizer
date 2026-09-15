import QtQuick
import QtTest
import "../hyprland/Configuration.js" as Configuration

TestCase {
    name: "HyprlandConfiguration"
    function test_displaySelectionAndUnplugFallback() {
        const outputs = [
            {
                name: "DP-1"
            },
            {
                name: "HDMI-A-1"
            }
        ];
        compare(Configuration.screens(outputs, "all"), outputs);
        compare(Configuration.screens(outputs, "HDMI-A-1"), [outputs[1]]);
        compare(Configuration.screens(outputs, ""), [outputs[0]]);
        compare(Configuration.screens([outputs[0]], "HDMI-A-1"), [outputs[0]]);
        compare(Configuration.screens([], "all"), []);
        compare(Configuration.screens([], "DP-1"), []);
    }
    function test_onlyChangedPreferencesOverrideNixDefaults() {
        const defaults = {
            monitor: "all",
            sensitivity: 130,
            showBg: false
        };
        const changed = Configuration.overrides(defaults, {
            monitor: "all",
            sensitivity: 175,
            showBg: false
        });
        compare(changed, {
            sensitivity: 175
        });
        compare(Object.assign({}, defaults, changed).monitor, "all");
        compare(Configuration.overrides(defaults, defaults), {});
    }
    function test_invalidPreferencesDoNotBecomeSettings() {
        for (const text of ["null", "[]", "false", "not json"]) {
            let failed = false;
            try {
                Configuration.parsePreferences(text);
            } catch (error) {
                failed = true;
            }
            verify(failed, text);
        }
        compare(Configuration.parsePreferences('{"monitor":"all"}'), {
            monitor: "all"
        });
    }
}
