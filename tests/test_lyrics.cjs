const assert = require('node:assert/strict');
const {parse, attach} = require('../package/contents/code/Lyrics.js');
const lines = parse('[offset:100]\n[00:01.00]<00:01.00>Hel<00:01.50>lo <00:02.00>world<00:03.00>\n[00:04]Next');
assert.equal(lines[0].text, 'Hello world');
assert.deepEqual(lines[0].words, [
    {start: 0, length: 3, time: 0.9, end: 1.4},
    {start: 3, length: 3, time: 1.4, end: 1.9},
    {start: 6, length: 5, time: 1.9, end: 2.9}
]);
assert.equal(lines[0].time, 0.9);
assert.deepEqual(parse('[00:02][00:10]<00:02>a<00:03>b').map(l => l.words[0].time), [2, 10]);
assert.equal(parse('[00:01]Original\n[00:01]Translation')[0].translation, 'Translation');
assert.equal(parse('[00:01]<00:01>last')[0].words[0].end, 3);
assert.equal(parse('[00:01]<00:01>one\n[00:04]two')[0].words[0].end, 4);
assert.equal(parse('[ar:Artist]\n[00:99]bad\nplain').length, 0);
assert.equal(parse('\uFEFF[00:01.125]Unicode 日本語 <b> & text\r\n')[0].text, 'Unicode 日本語 <b> & text');
assert.equal(attach(parse('[00:01]One'), '[00:01]Uno', 'translation')[0].translation, 'Uno');
console.log('PASS: enhanced LRC, offsets, repetitions, translations, malformed timestamps');
