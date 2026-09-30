import QtQuick
import QtTest
import "../package/contents/ui/debug"

TestCase {
    name: "GpuDebug"

    function cleanup() {
        GpuDebug.apply("", false);
    }

    function test_unsetChangesNothing() {
        verify(GpuDebug.handle(GpuDebug.command, {
            stdout: "awv-gpu-debug::"
        }));
        verify(!GpuDebug.noLayers && !GpuDebug.noSources && !GpuDebug.noShaders && !GpuDebug.avoidGlShaders);
    }

    function test_switches() {
        GpuDebug.handle(GpuDebug.command, {
            stdout: "awv-gpu-debug:layers,shaders:"
        });
        verify(GpuDebug.noLayers && !GpuDebug.noSources && GpuDebug.noShaders);
        GpuDebug.apply("all", false);
        verify(GpuDebug.noLayers && GpuDebug.noSources && GpuDebug.noShaders);
    }

    // Issue #10: NVIDIA's OpenGL driver leaks while the shader renderers animate.
    function test_nvidiaAvoidsGlShaders() {
        GpuDebug.handle(GpuDebug.command, {
            stdout: "awv-gpu-debug::nvidia"
        });
        verify(GpuDebug.avoidGlShaders);
        verify(!GpuDebug.noShaders);
        GpuDebug.handle(GpuDebug.command, {
            stdout: "awv-gpu-debug:gl-shaders:nvidia"
        });
        verify(!GpuDebug.avoidGlShaders);
    }

    function test_otherCommandsAreIgnored() {
        verify(!GpuDebug.handle("echo hi", {
            stdout: "awv-gpu-debug::nvidia"
        }));
        verify(!GpuDebug.avoidGlShaders);
    }
}
