import QtQuick
import QtTest
import "../package/contents/ui/text"

TestCase {
    name: "I18n"

    QtObject {
        id: label
        property string shown: I18n.i18n("Apply")
    }

    function cleanup() {
        I18n.useKde(null);
        I18n.load("");
    }

    function test_englishFillsPlaceholders() {
        compare(I18n.i18n("%1 bars", 5), "5 bars");
    }
    function test_emptyStaysEmpty() {
        compare(I18n.i18n(""), "");
        compare(I18n.i18n(undefined), "");
    }
    function test_languagesFromLocale() {
        compare(I18n.languages("tr_TR.UTF-8"), ["tr_TR", "tr"]);
        compare(I18n.languages("C"), []);
    }
    function test_bindingFollowsLoadedCatalog() {
        compare(label.shown, "Apply");
        I18n.load('msgid ""\nmsgstr ""\n\nmsgid "Apply"\nmsgstr "Uygula"\n');
        compare(label.shown, "Uygula");
        I18n.load("");
        compare(label.shown, "Apply");
    }
    function test_kdeWinsOverCatalog() {
        I18n.load('msgid "Apply"\nmsgstr "Uygula"\n');
        I18n.useKde(text => "kde:" + text);
        compare(label.shown, "kde:Apply");
    }
}
