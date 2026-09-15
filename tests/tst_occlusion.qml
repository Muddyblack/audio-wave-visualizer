import QtQuick
import QtTest
import "../hyprland/Occlusion.js" as Geometry

TestCase {
    name: "Occlusion"

    function rectangle(x, y, width, height, name = "DP-1") {
        return {
            name: name,
            x: x,
            y: y,
            width: width,
            height: height
        };
    }

    function client(x, y, width, height, options = {}) {
        return Object.assign({
            mapped: true,
            hidden: false,
            at: [x, y],
            size: [width, height],
            workspace: {
                id: 1
            },
            monitor: 0,
            floating: false,
            fullscreen: 0
        }, options);
    }

    function monitors() {
        return [
            {
                id: 0,
                name: "DP-1",
                activeWorkspace: {
                    id: 1
                },
                lastIpcObject: {
                    specialWorkspace: {
                        id: 0,
                        name: ""
                    }
                }
            }
        ];
    }

    function test_unionCoversWithoutDoubleCounting() {
        const target = rectangle(0, 0, 100, 100);
        verify(Geometry.fullyCovered(target, [rectangle(0, 0, 50, 100), rectangle(50, 0, 50, 100)]));
        verify(Geometry.fullyCovered(target, [rectangle(0, 0, 100, 50), rectangle(0, 50, 100, 50)]));
        verify(!Geometry.fullyCovered(target, [rectangle(0, 0, 75, 100), rectangle(0, 0, 75, 100)]));
        verify(!Geometry.fullyCovered(target, [rectangle(0, 0, 49, 100), rectangle(50, 0, 50, 100)]));
        verify(!Geometry.fullyCovered(target, [rectangle(100, 0, 100, 100)]));
    }

    function test_activeWorkspaceAndPinnedWindows() {
        const target = [rectangle(0, 0, 100, 100)];
        compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100)], monitors()), ["DP-1"]);
        compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100, {
                workspace: {
                    id: 2
                }
            })], monitors()), []);
        compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100, {
                workspace: {
                    id: 2
                },
                pinned: true
            })], monitors()), ["DP-1"]);
        const native = {
            workspace: {
                id: 2
            },
            lastIpcObject: client(0, 0, 100, 100)
        };
        compare(Geometry.coveredScreens(target, [native], monitors()), [], "Live workspace takes precedence over the stale IPC snapshot");
    }

    function test_irregularUnionKeepsInteriorHole() {
        const target = rectangle(0, 0, 100, 100);
        const covers = [rectangle(0, 0, 100, 40), rectangle(0, 60, 100, 40), rectangle(0, 40, 40, 20), rectangle(60, 40, 40, 20)];
        verify(!Geometry.fullyCovered(target, covers));
        covers.push(rectangle(40, 40, 20, 20));
        verify(Geometry.fullyCovered(target, covers));
    }

    function test_specialWorkspace() {
        const target = [rectangle(0, 0, 100, 100)];
        const window = client(0, 0, 100, 100, {
            workspace: {
                id: -99,
                name: "special:scratch"
            }
        });
        const screens = monitors();
        compare(Geometry.coveredScreens(target, [window], screens), []);
        screens[0].lastIpcObject.specialWorkspace = {
            id: -99,
            name: "special:scratch"
        };
        compare(Geometry.coveredScreens(target, [window], screens), ["DP-1"]);
        screens[0].lastIpcObject.specialWorkspace = {
            id: 0,
            name: ""
        };
        screens[0].activeSpecialWorkspace = {
            id: -99,
            name: "special:scratch"
        };
        compare(Geometry.coveredScreens(target, [window], screens), ["DP-1"]);
    }

    function test_unmappedHiddenAndMissingState() {
        const target = [rectangle(0, 0, 100, 100)];
        for (const options of [
            {
                mapped: false
            },
            {
                hidden: true
            },
            {
                hidden: undefined
            },
            {
                mapped: undefined
            },
            {
                size: []
            },
            {
                at: [NaN, 0]
            },
            {
                workspace: null
            },
            {
                monitor: undefined
            },
            {
                monitor: 999
            }
        ])
            compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100, options)], monitors()), []);
        compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100)], []), []);
        compare(Geometry.coveredScreens(target, [], monitors()), []);
        verify(!Geometry.fullyCovered(rectangle(0, 0, 0, 0), [rectangle(0, 0, 100, 100)]));
    }

    function test_fullscreenUsesRealGeometry() {
        const target = [rectangle(800, 600, 360, 104)];
        compare(Geometry.coveredScreens(target, [client(0, 0, 1920, 1080, {
                fullscreen: 2
            })], monitors()), ["DP-1"]);
        compare(Geometry.coveredScreens(target, [client(0, 0, 400, 300, {
                fullscreen: 2
            })], monitors()), [], "Fake fullscreen cannot cover pixels outside the window");
    }

    function test_monitorCoordinatesStayLogical() {
        const screens = [
            {
                id: 0,
                name: "DP-1",
                activeWorkspace: {
                    id: 1
                },
                lastIpcObject: {
                    x: -960,
                    y: 0,
                    width: 3840,
                    height: 2160,
                    scale: 2
                }
            },
            {
                id: 1,
                name: "DP-2",
                activeWorkspace: {
                    id: 2
                },
                lastIpcObject: {
                    x: 960,
                    y: -200,
                    width: 1920,
                    height: 1080,
                    scale: 1.5,
                    transform: 1
                }
            }
        ];
        const targets = [rectangle(-700, 600, 360, 104), rectangle(1100, 400, 360, 104, "DP-2")];
        const windows = [client(-960, 0, 1920, 1080), client(960, -200, 720, 1280, {
                workspace: {
                    id: 2
                },
                monitor: 1
            })];
        compare(Geometry.coveredScreens(targets, windows, screens), ["DP-1", "DP-2"]);
        windows[1].size = [200, 1280];
        compare(Geometry.coveredScreens(targets, windows, screens), ["DP-1"]);
    }

    function test_layerSurfaceExcludedButSettingsCount() {
        const target = [rectangle(0, 0, 100, 100)];
        compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100, {
                namespace: "audio-wave-visualizer"
            })], monitors()), []);
        compare(Geometry.coveredScreens(target, [client(0, 0, 100, 100, {
                class: "quickshell",
                title: "Audio Visualizer Settings"
            })], monitors()), ["DP-1"]);
    }

    function test_onlyFloatingOrPinnedWindowsSpanMonitors() {
        const screens = [
            {
                id: 0,
                name: "DP-1",
                activeWorkspace: {
                    id: 1
                }
            },
            {
                id: 1,
                name: "DP-2",
                activeWorkspace: {
                    id: 2
                }
            }
        ];
        const targets = [rectangle(0, 0, 100, 100), rectangle(100, 0, 100, 100, "DP-2")];
        // Oversized tiled/fullscreen bounds are clipped by Hyprland on the
        // neighboring output, even when both workspaces are active.
        const window = client(0, 0, 200, 100);
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-1"]);
        window.floating = true;
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-1", "DP-2"]);
        window.fullscreen = 2;
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-1"]);
        window.fullscreen = undefined;
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-1"], "Unknown fullscreen state cannot prove cross-monitor coverage");
        window.pinned = true;
        window.workspace = {
            id: 99
        };
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-1", "DP-2"]);
    }

    function test_liveMonitorOverridesIpcSnapshot() {
        const screens = [
            {
                id: 0,
                name: "DP-1",
                activeWorkspace: {
                    id: 1
                }
            },
            {
                id: 1,
                name: "DP-2",
                activeWorkspace: {
                    id: 2
                }
            }
        ];
        const targets = [rectangle(0, 0, 100, 100), rectangle(100, 0, 100, 100, "DP-2")];
        const window = {
            monitor: {
                id: 1,
                name: "DP-2"
            },
            workspace: {
                id: 2
            },
            lastIpcObject: client(0, 0, 200, 100)
        };
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-2"]);
        window.monitor = {
            name: "DP-2"
        };
        compare(Geometry.coveredScreens(targets, [window], screens), ["DP-2"], "Native monitor names also identify the owner");
        window.monitor = {
            id: 999,
            name: "removed"
        };
        compare(Geometry.coveredScreens(targets, [window], screens), [], "Unknown monitor leaves both widgets visible");
        window.monitor = null;
        compare(Geometry.coveredScreens(targets, [window], screens), [], "A lost native monitor cannot reuse stale IPC ownership");
    }
}
