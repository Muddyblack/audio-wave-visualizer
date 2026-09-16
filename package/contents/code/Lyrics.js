// Shared line/enhanced-LRC parser. Times are seconds; ranges use UTF-16 offsets
// so QML text geometry and the parser agree on character positions.
function stamp(minutes, seconds, fraction) {
    return Number(minutes) * 60 + Number(seconds) + (fraction ? Number('0.' + fraction) : 0);
}

function matches(pattern, text) {
    const result = [];
    let match;
    while ((match = pattern.exec(text)) !== null)
        result.push(match);
    return result;
}

function parse(input) {
    const source = String(input || '').replace(/^\uFEFF/, '');
    const offsetTag = source.match(/\[offset:([+-]?\d+)\]/i);
    const offset = offsetTag ? -Number(offsetTag[1]) / 1000 : 0;
    const result = [];
    for (const raw of source.split(/\r?\n/)) {
        const tags = matches(/\[(\d+):([0-5]?\d)(?:[.:](\d+))?\]/g, raw);
        if (!tags.length)
            continue;
        const body = raw.replace(/\[(\d+):([0-5]?\d)(?:[.:](\d+))?\]/g, '').replace(/\[offset:[+-]?\d+\]/ig, '').trim();
        const markers = matches(/<(\d+):([0-5]?\d)(?:[.:](\d+))?>/g, body);
        let text = '';
        const words = [];
        let cursor = 0;
        let time = stamp(tags[0][1], tags[0][2], tags[0][3]);
        for (const marker of markers) {
            const part = body.slice(cursor, marker.index);
            if (part) {
                words.push({start: text.length, length: part.length, time: time + offset,
                    end: stamp(marker[1], marker[2], marker[3]) + offset});
                text += part;
            }
            time = stamp(marker[1], marker[2], marker[3]);
            cursor = marker.index + marker[0].length;
        }
        const tail = body.slice(cursor);
        if (tail && markers.length)
            words.push({start: text.length, length: tail.length, time: time + offset, end: null});
        text += tail;
        for (const tag of tags) {
            const start = stamp(tag[1], tag[2], tag[3]) + offset;
            const shift = start - (stamp(tags[0][1], tags[0][2], tags[0][3]) + offset);
            result.push({time: start, text: text, words: words.map(w => ({
                start: w.start, length: w.length, time: w.time + shift,
                end: w.end === null ? null : w.end + shift
            }))});
        }
    }
    result.sort((a, b) => a.time - b.time);
    // Repeated timestamps often encode a translation on the following line.
    const merged = [];
    for (const line of result) {
        const previous = merged[merged.length - 1];
        if (previous && previous.time === line.time) {
            if (line.text && previous.text !== line.text)
                previous.translation = [previous.translation, line.text].filter(Boolean).join('\n');
        } else {
            merged.push(line);
        }
    }
    for (let i = 0; i < merged.length; i++) {
        for (const word of merged[i].words) {
            if (word.end === null)
                word.end = i + 1 < merged.length ? merged[i + 1].time : word.time + 2;
            word.end = Math.max(word.time, word.end);
        }
    }
    return merged;
}

function attach(lines, secondary, field) {
    const extra = parse(secondary);
    for (const line of lines) {
        const match = extra.find(other => Math.abs(other.time - line.time) < 0.02);
        if (match)
            line[field] = match.text;
    }
    return lines;
}

if (typeof module !== 'undefined')
    module.exports = {parse, attach};
