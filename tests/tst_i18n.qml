import QtQuick
import QtTest
import org.kde.plasma.plasma5support
import "../package/contents/ui" as Shared
import "../package/contents/ui/text"
import "../package/contents/ui/studio/Schema.js" as Schema

TestCase {
    name: "I18n"

    QtObject {
        id: label
        property string shown: I18n.i18n("Apply")
    }

    Component {
        id: loaderComponent
        Shared.CatalogLoader {
            translateDir: "/translate"
            commandSourceComponent: Component {
                Shared.PlasmaCommandSource {}
            }
        }
    }

    function cleanup() {
        I18n.load("");
        I18n.available = [];
        Commands.calls = [];
    }

    function test_englishFillsPlaceholders() {
        compare(I18n.i18n("%1 bars", 5), "5 bars");
    }
    function test_emptyStaysEmpty() {
        compare(I18n.i18n(""), "");
        compare(I18n.i18n(undefined), "");
    }
    function test_candidatesAreRealLanguageTags() {
        compare(I18n.candidates("tr_TR.UTF-8"), ["tr_TR", "tr"]);
        compare(I18n.candidates("C"), []);
        compare(I18n.candidates("tr'; touch /tmp/x; '"), []);
    }
    function test_bindingFollowsLoadedCatalog() {
        compare(label.shown, "Apply");
        I18n.load('msgid ""\nmsgstr ""\n\nmsgid "Apply"\nmsgstr "Uygula"\n');
        compare(label.shown, "Uygula");
        I18n.load("");
        compare(label.shown, "Apply");
    }
    function loaderFor(language) {
        return createTemporaryObject(loaderComponent, this, {
            language: language
        });
    }
    function answer(loader, stdout) {
        loader.children[loader.children.length - 1].item.newData(loader.command, {
            stdout: stdout
        });
    }
    function test_loaderFindsCatalogsAndSwitchesLive() {
        const loader = loaderFor("tr");
        verify(I18n.loading, "the first catalog hides text until it arrives");
        answer(loader, 'tr.po de.po\nmsgid "Apply"\nmsgstr "Uygula"\n');
        verify(!I18n.loading);
        compare(label.shown, "Uygula");
        compare(I18n.available, ["tr", "de"]);
        compare(I18n.languageOptions.map(option => option[0]), ["", "en", "tr", "de"]);
        loader.language = "en";
        answer(loader, "tr.po de.po\n");
        compare(label.shown, "Apply");
        verify(!I18n.loading, "switching later never hides the widget");
    }
    function test_noCatalogsFoundIsEnglish() {
        const loader = loaderFor("tr");
        answer(loader, "*.po\n");
        compare(I18n.available, []);
        compare(label.shown, "Apply");
    }
    function test_closingAPreviewRestoresTheSavedLanguage() {
        const widget = loaderFor("en");
        answer(widget, "tr.po\n");
        const saved = I18n.loadedKey;
        const preview = createTemporaryObject(loaderComponent, this, {
            language: "tr",
            preview: true
        });
        answer(preview, 'tr.po\nmsgid "Apply"\nmsgstr "Uygula"\n');
        compare(label.shown, "Uygula");
        preview.destroy();
        wait(0);
        compare(widget.command, saved);
        answer(widget, "tr.po\n");
        compare(label.shown, "Apply");
    }
    function test_settingUsesTheFoundLanguages() {
        const rows = [].concat.apply([], Schema.SECTIONS.map(section => section.rows));
        compare(rows.find(entry => entry.k === "language").opts, "languages");
    }
}
