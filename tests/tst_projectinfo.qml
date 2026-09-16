import QtQuick
import QtTest
import "../package/contents/ui/studio" as Studio

TestCase {
    name: "ProjectInfo"
    when: windowShown
    visible: true
    width: 400
    height: 600

    Component {
        id: infoComponent
        Studio.ProjectInfoPane {
            width: 360
            studio: ({
                    onScreen: false
                })
        }
    }
    function test_avatarSurvivesLoadingAndOfflineWithoutShaders() {
        const pane = createTemporaryObject(infoComponent, this);
        verify(pane !== null);
        const avatar = findChild(pane, "authorAvatar");
        const fallback = findChild(pane, "authorAvatarFallback");
        verify(fallback.visible);
        verify(!avatar.ready);
        waitForRendering(avatar);
        const point = avatar.mapToItem(pane, 20, 20);
        const corner = avatar.mapToItem(pane, 0, 0);
        const beforeCenter = grabImage(pane).pixel(point.x, point.y).toString();
        const beforeCorner = grabImage(pane).pixel(corner.x, corner.y).toString();
        // Exercise the real image pipeline without depending on GitHub access.
        avatar.source = Qt.resolvedUrl("../package/icon.png");
        tryCompare(avatar, "ready", true);
        verify(!fallback.visible);
        waitForRendering(avatar);
        tryVerify(() => grabImage(pane).pixel(point.x, point.y).toString() !== beforeCenter, 5000, "Loaded avatar remains drawn on the software renderer");
        const image = grabImage(pane);
        compare(image.pixel(corner.x, corner.y).toString(), beforeCorner, "Avatar corners remain circular");
        avatar.source = "";
        verify(!avatar.ready);
        verify(fallback.visible, "Offline author initials remain visible");
    }
}
