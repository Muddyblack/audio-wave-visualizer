import QtQuick
import QtTest
import "../hyprland"
import "../hyprland/Configuration.js" as Configuration

TestCase {
    name: "HyprlandSettingsPage"
    when: windowShown
    visible: true
    width: 560
    height: 720
    SettingsPage {
        id: page
        anchors.fill: parent
        screenNames: ["DP-1", "HDMI-A-1"]
    }
    SignalSpy {
        id: applied
        target: page
        signalName: "apply"
    }
    SignalSpy {
        id: closed
        target: page
        signalName: "close"
    }
    SignalSpy {
        id: reset
        target: page
        signalName: "reset"
    }
    function initTestCase() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        page.draft = Object.assign(Configuration.defaults(request.responseText), {
            widgetWidth: 360,
            widgetHeight: 104,
            verticalPosition: 0.6,
            monitor: "",
            desktopLayer: true,
            pauseWhenCovered: true,
            waveColor: "#b4befe",
            textColor: "#cdd6f4"
        });
    }
    function test_draftChangesRequireApplyAndButtonsWork() {
        page.setValue("monitor", "all");
        page.setValue("sensitivity", 175);
        compare(applied.count, 0);
        mouseClick(findChild(page, "applySettings"));
        compare(applied.count, 1);
        compare(applied.signalArguments[0][0].monitor, "all");
        compare(applied.signalArguments[0][0].sensitivity, 175);
        mouseClick(findChild(page, "resetSettings"));
        compare(reset.count, 1);
        mouseClick(findChild(page, "closeSettings"));
        compare(closed.count, 1);
    }
    function test_tabsSwitchSections() {
        compare(page.currentTabIndex, 0);
        const tab1 = findChild(page, "tabButton_1");
        verify(tab1 !== null);
        mouseClick(tab1);
        compare(page.currentTabIndex, 1);

        const tab3 = findChild(page, "tabButton_3");
        verify(tab3 !== null);
        mouseClick(tab3);
        compare(page.currentTabIndex, 3);

        const tab0 = findChild(page, "tabButton_0");
        verify(tab0 !== null);
        mouseClick(tab0);
        compare(page.currentTabIndex, 0);
    }
}
