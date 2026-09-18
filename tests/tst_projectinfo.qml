import QtQuick
import QtTest
import "../package/contents/ui/studio" as Studio
import "../package/contents/ui/studio/ProjectInfo.js" as Project

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
    function test_fundingLinksMatchGitHubChoices() {
        const pane = createTemporaryObject(infoComponent, this);
        verify(pane !== null);
        const expected = [["github", "https://github.com/sponsors/muddyblack"], ["ko_fi", "https://ko-fi.com/muddyblack"], ["buy_me_a_coffee", "https://buymeacoffee.com/muddyblack"]];
        for (const entry of expected) {
            const card = findChild(pane, "funding_" + entry[0]);
            verify(card !== null, entry[0] + " support card exists");
            compare(card.modelData.url, entry[1]);
            const icon = findChild(pane, "fundingIcon_" + entry[0]);
            verify(icon !== null);
            tryCompare(icon, "status", Image.Ready);
        }
    }
    function test_statisticsAlwaysLinkToTheirSources() {
        const pane = createTemporaryObject(infoComponent, this);
        verify(pane !== null);
        const expected = [["stars", "https://github.com/Muddyblack/audio-wave-visualizer/stargazers"], ["downloads", "https://github.com/Muddyblack/audio-wave-visualizer/releases"], ["kde", "https://www.opendesktop.org/p/2359422"]];
        for (const entry of expected) {
            const card = findChild(pane, "stat_" + entry[0]);
            verify(card !== null, entry[0] + " stat card exists offline");
            compare(card.modelData.href, entry[1]);
            const icon = findChild(pane, "statIcon_" + entry[0]);
            verify(icon !== null);
            tryCompare(icon, "status", Image.Ready);
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
    function test_contributorsAppearOnlyForValidOnlineData() {
        const pane = createTemporaryObject(infoComponent, this);
        const section = findChild(pane, "contributorsSection");
        verify(!section.visible, "Offline Info stays compact");
        compare(Project.contributors("not json").length, 0);
        compare(Project.contributors("{}").length, 0);
        const list = Project.contributors(JSON.stringify([
            {
                login: "Helpful-Dev",
                type: "User",
                contributions: 3
            },
            {
                login: "build[bot]",
                type: "Bot",
                contributions: 30
            },
            {
                login: "<script>",
                type: "User",
                contributions: 2
            }
        ]));
        compare(list.length, 1);
        compare(list[0].profile, "https://github.com/Helpful-Dev");
        pane.contributorList = list;
        verify(section.visible);
        const card = findChild(pane, "contributor_Helpful-Dev");
        verify(card !== null);
        compare(card.modelData.commits, 3);
    }
    function test_licenseComesFromBundledFile() {
        const pane = createTemporaryObject(infoComponent, this);
        compare(Project.licenseId, "GPL-3.0-or-later");
        compare(Project.license, "GNU GPL v3 or later");
        verify(findChild(pane, "projectLicense") !== null);
    }
}
