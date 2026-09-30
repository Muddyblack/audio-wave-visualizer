import QtQuick
import QtTest
import "../package/contents/ui/debug"

TestCase {
    name: "GpuDebug"

    function cleanup() {
        GpuDebug.apply("");
    }

    function test_unsetChangesNothing() {
        verify(GpuDebug.handle(GpuDebug.command, {
            stdout: "awv-gpu-debug:"
        }));
        verify(!GpuDebug.noLayers && !GpuDebug.noSources && !GpuDebug.noShaders);
    }

    function test_switches() {
        GpuDebug.handle(GpuDebug.command, {
            stdout: "awv-gpu-debug:layers,shaders"
        });
        verify(GpuDebug.noLayers && !GpuDebug.noSources && GpuDebug.noShaders);
        GpuDebug.apply("all");
        verify(GpuDebug.noLayers && GpuDebug.noSources && GpuDebug.noShaders);
    }

    function test_otherCommandsAreIgnored() {
        verify(!GpuDebug.handle("echo hi", {
            stdout: "awv-gpu-debug:all"
        }));
        verify(!GpuDebug.noLayers);
    }
}
