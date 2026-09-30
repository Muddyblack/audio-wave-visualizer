import QtQuick
import QtTest
import "../package/contents/ui/debug"

TestCase {
    name: "GpuDebug"

    function cleanup() {
        GpuDebug.apply("");
    }

    function test_unsetChangesNothing() {
        GpuDebug.apply("");
        verify(!GpuDebug.noLayers && !GpuDebug.noSources && !GpuDebug.noShaders);
    }

    function test_switches() {
        GpuDebug.apply("layers,shaders");
        verify(GpuDebug.noLayers && !GpuDebug.noSources && GpuDebug.noShaders);
        GpuDebug.apply("all");
        verify(GpuDebug.noLayers && GpuDebug.noSources && GpuDebug.noShaders);
    }
}
