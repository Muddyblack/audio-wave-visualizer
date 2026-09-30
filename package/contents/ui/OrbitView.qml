pragma ComponentBehavior: Bound
import QtQuick
import "debug"

OrbitCanvas {
    id: orbitRoot
    property bool simpleRender: false
    property bool shaderFailed: false
    shaderEnabled: !orbitRoot.simpleRender && !GpuDebug.noShaders && GraphicsInfo.api !== GraphicsInfo.Software && !orbitRoot.shaderFailed
    Loader {
        anchors.fill: parent
        active: orbitRoot.shaderEnabled
        sourceComponent: OrbitShader {
            orbit: orbitRoot
            onStatusChanged: {
                if (status === ShaderEffect.Error)
                    orbitRoot.shaderFailed = true;
            }
        }
    }
}
