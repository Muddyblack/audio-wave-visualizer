// Only advertised format metadata is used; an output device's format is not
// evidence of the source quality. Xesam audioBitrate is measured in bits/sec.
function badges(metadata) {
    const m = metadata || {};
    function value(keys) {
        for (const key of keys) {
            if (m[key] !== undefined && m[key] !== null && m[key] !== "")
                return Array.isArray(m[key]) ? m[key][0] : m[key];
        }
        return "";
    }
    function positive(keys) {
        const n = Number(value(keys));
        return Number.isFinite(n) && n > 0 ? n : 0;
    }
    const raw = String(value(["xesam:audioCodec", "audio:codec", "codec", "xesam:contentType"])).toLowerCase();
    const known = raw.match(/\b(flac|alac|dsd(?:64|128|256|512)?|aac|mp3|opus|vorbis|pcm)\b/);
    const result = known ? [known[1].toUpperCase()] : [];
    if (/^(flac|alac)$/.test(known ? known[1] : "") || value(["audio:lossless", "lossless"]) === true)
        result.push("Lossless");
    const rate = positive(["xesam:audioSampleRate", "audio:sampleRate", "sampleRate"]);
    const bits = positive(["xesam:audioBitsPerSample", "audio:bitsPerSample", "bitsPerSample"]);
    const detail = [];
    if (rate) detail.push(Number((rate / 1000).toFixed(3)) + "kHz");
    if (bits && bits <= 64) detail.push(bits + "bit");
    if (detail.length) result.push(detail.join("/"));
    const bitrate = positive(["xesam:audioBitrate", "audio:bitrate", "bitrate"]);
    if (bitrate) result.push(Math.round(bitrate / 1000) + " kbps");
    return result;
}
