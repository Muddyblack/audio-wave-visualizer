import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    name: "PanelPopup"
    when: windowShown
    Item {
        id: pill
    }
    PanelPopupState {
        id: state
        showDelay: 20
        hideDelay: 40
    }
    function init() {
        state.dismiss();
        state.anchorHovered = false;
        state.popupHovered = false;
        state.available = true;
        state.trigger = "both";
    }
    function test_clickOnlyIgnoresHover() {
        state.trigger = "click";
        state.hover(pill, true);
        wait(60);
        verify(!state.opened);
        state.toggle(pill);
        verify(state.opened && state.pinned);
        state.hover(pill, false);
        wait(60);
        verify(state.opened);
        state.toggle(pill);
        verify(!state.opened);
    }
    function test_hoverOnlyIgnoresClickAndClosesOnLeave() {
        state.trigger = "hover";
        state.toggle(pill);
        verify(!state.opened);
        state.hover(pill, true);
        state.toggle(pill);
        tryCompare(state, "opened", true);
        state.toggle(pill);
        verify(state.opened && !state.pinned);
        state.hover(pill, false);
        tryCompare(state, "opened", false);
    }
    function test_changingModeCancelsPendingHoverAndClosesPinnedCard() {
        state.hover(pill, true);
        state.trigger = "click";
        wait(60);
        verify(!state.opened);
        state.toggle(pill);
        state.trigger = "hover";
        verify(!state.opened && !state.pinned);
    }
    function test_briefHoverDoesNotOpen() {
        state.hover(pill, true);
        state.hover(pill, false);
        wait(60);
        verify(!state.opened);
    }
    function test_hoverOpensAndCrossingGapKeepsControlsReachable() {
        state.hover(pill, true);
        tryCompare(state, "opened", true);
        compare(state.anchor, pill);
        verify(!state.pinned);
        state.hover(pill, false);
        wait(10);
        state.popupHovered = true;
        wait(60);
        verify(state.opened);
        state.popupHovered = false;
        tryCompare(state, "opened", false);
    }
    function test_clickPinsHoveredCardAndSecondClickCloses() {
        state.hover(pill, true);
        tryCompare(state, "opened", true);
        state.toggle(pill);
        verify(state.pinned);
        state.hover(pill, false);
        wait(60);
        verify(state.opened);
        state.toggle(pill);
        verify(!state.opened);
        verify(!state.pinned);
    }
    function test_disablingCancelsPendingHover() {
        state.hover(pill, true);
        state.available = false;
        wait(60);
        verify(!state.opened);
    }
    function test_explicitPinSurvivesLeavingAndPillClicks() {
        state.hover(pill, true);
        tryCompare(state, "opened", true);
        state.togglePin();
        verify(state.keepOpen);
        state.hover(pill, false);
        state.toggle(pill);
        wait(80);
        verify(state.opened && state.keepOpen);
        state.togglePin();
        verify(!state.opened && !state.keepOpen && !state.pinned);
    }
    function test_explicitDismissAndUnavailableClearPin() {
        state.toggle(pill);
        verify(!state.keepOpen, "Ordinary clicks still allow focus-loss dismissal");
        state.togglePin();
        state.dismiss();
        verify(!state.keepOpen);
        state.toggle(pill);
        state.togglePin();
        state.available = false;
        verify(!state.opened && !state.keepOpen);
    }
}
