.pragma library

// Entry points must be local files. This is not a sandbox for their contents.
function validUrl(url) {
    return typeof url === "string" && /^file:\/\/\/[^?#]+\.qml$/i.test(url);
}

function readLibrary(text) {
    try {
        const data = JSON.parse(text || "[]");
        const seen = {};
        return Array.isArray(data) ? data.filter(entry => {
            if (!entry || !validUrl(entry.url) || typeof entry.name !== "string" || seen[entry.url])
                return false;
            seen[entry.url] = true;
            return true;
        }) : [];
    } catch (e) {
        return [];
    }
}

function nameForUrl(url) {
    const name = url.split("/").pop().replace(/\.qml$/i, "");
    try {
        return decodeURIComponent(name);
    } catch (e) {
        return name;
    }
}
