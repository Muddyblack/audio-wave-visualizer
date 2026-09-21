import QtQuick

QtObject {
    property var localChapters: []
    property var metadata: ({})
    property real duration: 0
    // Chapter metadata is player-specific; these adapters use seconds.
    readonly property var chapters: {
        const source = metadata["chapters"] || metadata["xesam:chapters"] || metadata["mpris:chapters"] || localChapters;
        if (!source || typeof source === "string" || typeof source.length !== "number")
            return [];
        const result = Array.from(source).filter(c => c && typeof c === "object").map((c, i) => ({
                    start: Number(c.start ?? c.start_time),
                    title: String(c.title || "Chapter " + (i + 1)).slice(0, 160)
                })).filter(c => Number.isFinite(c.start) && c.start >= 0 && (duration <= 0 || c.start < duration)).sort((a, b) => a.start - b.start);
        return result.filter((c, i) => !i || c.start !== result[i - 1].start).slice(0, 512);
    }
    function at(seconds) {
        let selected = null;
        for (const chapter of chapters) {
            if (chapter.start > seconds)
                break;
            selected = chapter;
        }
        return selected;
    }
}
