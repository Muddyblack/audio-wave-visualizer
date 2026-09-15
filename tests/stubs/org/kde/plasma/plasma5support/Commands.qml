pragma Singleton
import QtQml

QtObject {
    property var calls: []
    property var cancelled: []
    property string legacyFrame: "100;200;300;400;"
}
