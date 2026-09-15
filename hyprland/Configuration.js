// Read the same defaults KConfig uses for Plasma; do not maintain a second list.
function defaults(xml) {
    const result = {};
    const entries = /<entry\s+name="([^"]+)"\s+type="([^"]+)"\s*>\s*<default>([^<]*)<\/default>/g;
    let entry;
    while ((entry = entries.exec(xml)) !== null) {
        const type = entry[2];
        const value = entry[3];
        result[entry[1]] = type === "Bool" ? value === "true" : type === "Int" || type === "Double" ? Number(value) : value;
    }
    return result;
}

function parsePreferences(text) {
    const value = JSON.parse(text);
    if (!value || typeof value !== "object" || Array.isArray(value))
        throw new Error("expected a settings object");
    return value;
}

function overrides(baseline, draft) {
    const result = {};
    for (const key of Object.keys(draft)) {
        if (draft[key] !== baseline[key])
            result[key] = draft[key];
    }
    return result;
}

function screens(available, monitor) {
    if (monitor === "all") return available;
    const selected = available.find(screen => screen.name === monitor) || available[0];
    return selected ? [selected] : [];
}
