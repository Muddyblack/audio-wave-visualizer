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
    function test_versionComparison_data() {
        return [
            {
                tag: "new release",
                current: "3.0.0",
                latest: "3.1.0",
                expected: "Update available"
            },
            {
                tag: "numeric components",
                current: "3.9.0",
                latest: "3.10.0",
                expected: "Update available"
            },
            {
                tag: "same version",
                current: "v3.0.0",
                latest: "3.0.0",
                expected: "Up to date"
            },
            {
                tag: "development ahead",
                current: "4.0.0",
                latest: "3.0.0",
                expected: "Newer than latest release"
            },
            {
                tag: "prerelease",
                current: "3.0.0-rc.1",
                latest: "3.0.0",
                expected: "Update available"
            },
            {
                tag: "build metadata",
                current: "3.0.0+local",
                latest: "3.0.0",
                expected: "Up to date"
            },
            {
                tag: "unknown",
                current: "main",
                latest: "3.0.0",
                expected: "Version comparison unavailable"
            }
        ];
    }
    function test_versionComparison(data) {
        compare(Project.releaseStatus(data.current, data.latest), data.expected);
    }
    function test_releaseResponseValidation() {
        compare(Project.releaseVersion('{"tag_name":"v3.1.0","draft":false,"prerelease":false}'), "3.1.0");
        for (const response of ["null", "{}", "not json", '{"message":"rate limited"}', '{"tag_name":"v4.0.0","draft":true}', '{"tag_name":"v4.0.0","prerelease":true}', '{"tag_name":"v4.0.0-beta"}'])
            compare(Project.releaseVersion(response), "");
    }
    function test_versionCardStates() {
        const pane = createTemporaryObject(infoComponent, this);
        verify(Project.parseVersion(pane.currentVersion) !== null);
        const status = findChild(pane, "versionStatusLabel");
        compare(status.text, "Not checked");
        pane.releaseCheckState = "Checking…";
        compare(status.text, "Checking…");
        pane.cancelRequests();
        compare(status.text, "Could not check for updates");
        pane.latestVersion = "999.0.0";
        compare(status.text, "Update available");
        compare(findChild(pane, "latestVersionLabel").text, "Latest stable release · 999.0.0");
        pane.latestVersion = pane.currentVersion;
        compare(status.text, "Up to date");
    }
    function test_licenseComesFromBundledFile() {
        const pane = createTemporaryObject(infoComponent, this);
        compare(Project.licenseId, "GPL-3.0-or-later");
        compare(Project.license, "GNU GPL v3");
        verify(findChild(pane, "projectLicense") !== null);
    }
}
