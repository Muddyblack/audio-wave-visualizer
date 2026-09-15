.pragma library

function validRect(rect) {
    return rect && Number.isFinite(rect.x) && Number.isFinite(rect.y)
        && Number.isFinite(rect.width) && Number.isFinite(rect.height)
        && rect.width > 0 && rect.height > 0;
}

// Subtract each covering window from the remaining visible pieces. Summing
// window areas would incorrectly count overlaps twice and hide visible gaps.
function fullyCovered(rect, covers) {
    if (!validRect(rect))
        return false;
    let remaining = [rect];
    for (const cover of covers) {
        if (!validRect(cover))
            continue;
        const next = [];
        for (const piece of remaining) {
            const left = Math.max(piece.x, cover.x);
            const top = Math.max(piece.y, cover.y);
            const right = Math.min(piece.x + piece.width, cover.x + cover.width);
            const bottom = Math.min(piece.y + piece.height, cover.y + cover.height);
            if (right <= left || bottom <= top) {
                next.push(piece);
                continue;
            }
            if (left > piece.x)
                next.push({x: piece.x, y: piece.y, width: left - piece.x, height: piece.height});
            if (right < piece.x + piece.width)
                next.push({x: right, y: piece.y, width: piece.x + piece.width - right, height: piece.height});
            if (top > piece.y)
                next.push({x: left, y: piece.y, width: right - left, height: top - piece.y});
            if (bottom < piece.y + piece.height)
                next.push({x: left, y: bottom, width: right - left, height: piece.y + piece.height - bottom});
        }
        remaining = next;
        if (remaining.length === 0)
            return true;
    }
    return false;
}

function sameWorkspace(a, b) {
    if (!a || !b)
        return false;
    if (Number.isFinite(a.id) && Number.isFinite(b.id) && a.id !== 0 && b.id !== 0)
        return a.id === b.id;
    return !!a.name && a.name === b.name;
}

function coveredScreens(rectangles, toplevels, monitors) {
    if (!rectangles || !toplevels || !monitors)
        return [];
    const screens = [];
    const workspaces = [];
    for (const monitor of monitors) {
        const data = monitor.lastIpcObject || monitor;
        if (data.disabled === true)
            continue;
        const name = monitor.name || data.name;
        if (name)
            screens.push({name: name, id: monitor.id ?? data.id});
        workspaces.push(monitor.activeWorkspace || data.activeWorkspace);
        workspaces.push(monitor.activeSpecialWorkspace || data.specialWorkspace);
    }

    const covers = [];
    for (const toplevel of toplevels) {
        const data = toplevel.lastIpcObject || toplevel;
        // Missing IPC state is not evidence that a window covers the widget.
        // Layer surfaces normally never appear here; settings windows do and
        // must count, so do not filter out all Quickshell application windows.
        if (data.mapped !== true || data.hidden !== false || data.namespace === "audio-wave-visualizer")
            continue;
        const workspace = toplevel.workspace || data.workspace;
        if (!data.pinned && !workspaces.some(active => sameWorkspace(workspace, active)))
            continue;
        if (!Array.isArray(data.at) || !Array.isArray(data.size))
            continue;
        // A tiled/fullscreen window can have bounds beyond its own output,
        // but Hyprland does not render it onto neighboring outputs. Only
        // floating non-fullscreen windows and pinned windows may span them.
        // Prefer the live native monitor over the last IPC snapshot.
        const owner = toplevel.monitor === undefined ? data.monitor : toplevel.monitor;
        const ownerId = Number.isFinite(owner) ? owner : owner?.id;
        const ownerName = owner?.name;
        const screen = screens.find(candidate =>
            (Number.isFinite(ownerId) && candidate.id === ownerId)
            || (ownerName && candidate.name === ownerName));
        if (!screen)
            continue;
        // IPC at/size are desktop logical coordinates, including fullscreen
        // geometry. Do not rescale/rotate them using physical monitor pixels.
        const rect = {x: data.at[0], y: data.at[1], width: data.size[0], height: data.size[1]};
        if (validRect(rect))
            covers.push({rect: rect, screen: screen.name,
                spansScreens: data.pinned === true || (data.floating === true && data.fullscreen === 0)});
    }

    return rectangles.filter(rect => screens.some(screen => screen.name === rect.name)
        && fullyCovered(rect, covers.filter(cover => cover.screen === rect.name || cover.spansScreens)
            .map(cover => cover.rect)))
        .map(rect => rect.name);
}
