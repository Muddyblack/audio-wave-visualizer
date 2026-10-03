.pragma library

// Copy settings to every other widget of this plugin (one per monitor, say)
// through plasmashell's scripting interface. Placement stays per widget.

function ascii(json) {
    return json.replace(/[\u007f-￿]/g, function (c) {
        return "\\u" + ("0000" + c.charCodeAt(0).toString(16)).slice(-4);
    });
}

function values(draft, skip) {
    var result = {};
    Object.keys(draft).forEach(function (key) {
        var value = draft[key];
        if (skip.indexOf(key) !== -1 || value === undefined) return;
        result[key] = value && typeof value === "object" && value.r !== undefined && !Array.isArray(value) ? String(value) : value;
    });
    return result;
}

// Prints how many other widgets were updated.
function script(plugin, selfId, settings) {
    return "var v=" + ascii(JSON.stringify(settings)) + ",n=0;"
        + "desktops().concat(panels()).forEach(function(c){c.widgetIds.forEach(function(id){"
        + "var w=c.widgetById(id);if(w.type!==" + JSON.stringify(plugin) + "||w.id===" + Number(selfId) + ")return;"
        + "w.currentConfigGroup=[\"General\"];for(var k in v)w.writeConfig(k,v[k]);w.reloadConfig();n++;});});print(n);";
}

function command(plugin, selfId, settings) {
    var encoded = Qt.btoa(script(plugin, selfId, settings));
    return "q=$(command -v qdbus6 || command -v qdbus || command -v qdbus-qt6) && "
        + "\"$q\" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \"$(printf %s " + encoded + " | base64 -d)\"";
}
