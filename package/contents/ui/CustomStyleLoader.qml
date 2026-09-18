import QtQuick
import "../code/CustomStyles.js" as CustomStyles

// Trusted extensions execute in the host QML engine. The small, versioned
// interface is a compatibility boundary, not a security boundary.
Item {
    id: root
    required property string interfaceName
    required property var interfaceObject
    property string loaderName: "customStyleLoader"
    property bool contentVisible: true
    readonly property alias item: loader.item
    readonly property real preferredWidth: (loader.item as Item)?.implicitWidth ?? 0
    readonly property real preferredHeight: (loader.item as Item)?.implicitHeight ?? 0
    property string sourceUrl: ""
    property string error: ""
    property bool initialized: false
    readonly property bool ready: loader.status === Loader.Ready && error === ""
    clip: true

    function load() {
        loader.source = "";
        error = "";
        if (!sourceUrl)
            return;
        if (!CustomStyles.validUrl(sourceUrl)) {
            error = "Choose a local .qml file.";
            return;
        }
        try {
            const properties = {};
            properties[interfaceName] = interfaceObject;
            loader.setSource(sourceUrl, properties);
        } catch (exception) {
            error = "Could not initialize this style: " + String(exception) + ". Using the built-in style.";
            loader.source = "";
        }
    }
    onSourceUrlChanged: {
        if (initialized)
            load();
    }
    Component.onCompleted: {
        initialized = true;
        load();
    }

    Loader {
        id: loader
        objectName: root.loaderName
        anchors.fill: parent
        active: root.visible
        asynchronous: true
        visible: root.ready && root.contentVisible
        onStatusChanged: {
            if (status === Loader.Error)
                root.error = "Could not load this QML style. Check that the file exists, its imports are installed, and it declares required property var " + root.interfaceName + ". See the host log for QML errors. Using the built-in style.";
        }
        onLoaded: {
            // Loaded extensions deliberately have a dynamic, versioned interface.
            // qmllint disable missing-property
            if (!(item instanceof Item) || item.apiVersion !== 1 || item[root.interfaceName] !== root.interfaceObject) {
                root.error = "This style must have an Item root, apiVersion: 1, and required property var " + root.interfaceName + ". Using the built-in style.";
                source = "";
            } else {
                root.error = "";
            }
            // qmllint enable missing-property
        }
    }
}
