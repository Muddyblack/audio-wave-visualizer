import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import "../hyprland/Configuration.js" as Configuration

TestCase {
    name: "LyricsSettings"
    // The live preview reads the host's applied capture settings, separately
    // from the cfg_* draft supplied to the settings page.
    property QtObject plasmoid: QtObject {
        property QtObject configuration: QtObject {
            property int numBars: 4
            property int framerate: 60
            property int sensitivity: 100
            property real noiseReduction: 0.77
            property string inputMethod: "auto"
            property string inputSource: "auto"
            property int visualizerType: 0
        }
    }
    property var defaults
    property var pageComponent
    function initTestCase() {
        pageComponent = Qt.createComponent(Qt.resolvedUrl("../package/contents/ui/configStudio.qml"));
        compare(pageComponent.status, Component.Ready, pageComponent.errorString());
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../package/contents/config/main.xml"), false);
        request.send();
        defaults = Configuration.defaults(request.responseText);
    }
    Component {
        id: pageRowComponent
        Kirigami.PageRow {
            width: 800
            height: 600
        }
    }
    function test_plasmaPageStack() {
        failOnWarning(/Setting initial properties failed|Value is null|Unable to assign|TypeError|ReferenceError/);
        const stack = createTemporaryObject(pageRowComponent, this);
        verify(stack !== null);
        const properties = {
            title: "General"
        };
        for (const key of Object.keys(defaults))
            properties["cfg_" + key] = defaults[key];
        const page = stack.push(pageComponent, properties);
        verify(page !== null);
        compare(stack.currentItem, page);
        compare(page.title, "General");
        verify(page.parent !== null);
        stack.clear();
    }

    function test_plasmaRoundTrip() {
        const properties = {
            title: "General"
        };
        for (const key of Object.keys(defaults)) {
            properties["cfg_" + key] = defaults[key];
            properties["cfg_" + key + "Default"] = defaults[key];
        }
        const page = createTemporaryObject(pageComponent, this, properties);
        verify(page !== null);
        compare(page.title, "General");
        compare(page.padding, 0);
        compare(Object.keys(page.draft).sort(), Object.keys(defaults).sort());
        for (const key of Object.keys(defaults)) {
            compare(page.draft[key], defaults[key], key + " draft");
            compare(page.defaults[key], defaults[key], key + " default");
        }
        page.cfg_glassBlurDefault = 0.5;
        compare(page.defaults.glassBlur, 0.5, "Plasma defaults remain reactive");
        page.cfg_glassBlurDefault = defaults.glassBlur;
        compare(page.cfg_glassBlur, 0.85);
        page.assign({
            glassBlur: 0.32
        });
        compare(page.cfg_glassBlur, 0.32);
        compare(page.draft.glassBlur, 0.32);
        compare(page.defaults.glassBlur, 0.85);
        verify(page.actions !== undefined, "Settings must expose the Kirigami page interface");
        page.assign({
            lyricsFontSize: 34,
            lyricsInlineFontSize: 16,
            lyricsFollow: false,
            lyricsHighlightColor: "#ff8800",
            lyricsOffset: -1.5
        });
        compare(page.cfg_lyricsFontSize, 34);
        compare(page.cfg_lyricsInlineFontSize, 16);
        compare(page.cfg_lyricsFollow, false);
        compare(page.cfg_lyricsOffset, -1.5);
        compare(page.cfg_lyricsHighlightColor, "#ff8800");
        compare(page.cfg_lyricsFontSizeDefault, defaults.lyricsFontSize);
        for (const key of Object.keys(defaults).filter(k => k.startsWith("lyrics")))
            verify(page["cfg_" + key] !== undefined, "Plasma setting must persist: " + key);
        verify(page.hasChanges, "Page must report unapplied changes");
        page.discard();
        compare(page.cfg_glassBlur, 0.85);
        compare(page.cfg_lyricsFontSize, defaults.lyricsFontSize);
        verify(!page.hasChanges, "Page must report no unapplied changes after discard");
        page.assign({
            glassBlur: 0.42,
            detailFields: ["player", "album"]
        });
        page.saveConfig();
        verify(!page.hasChanges, "Apply establishes the new saved settings");
        page.assign({
            glassBlur: 0.17,
            detailFields: ["title"]
        });
        const discardButton = findChild(page, "discardSettings");
        verify(discardButton !== null);
        verify(discardButton.enabled);
        discardButton.clicked(null);
        compare(page.cfg_glassBlur, 0.42);
        compare(page.cfg_detailFields, ["player", "album"]);
        verify(!page.hasChanges);
        verify(!discardButton.enabled);
        compare(page.title, "General", "Discard keeps the settings page available");
    }
}
