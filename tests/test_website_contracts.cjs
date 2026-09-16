// Run with node tests/test_website_contracts.cjs. Exercises the generated QML
// modules and browser adapter together without pretending to verify browser pixels.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..', 'docs', 'website');
const context = vm.createContext({console, assert, structuredClone});
context.window = context;
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
for (const [, file] of html.matchAll(/<script src="([^"]+)"/g)) {
  if (file !== 'app.js') vm.runInContext(fs.readFileSync(path.join(root, file), 'utf8'), context, {filename:file});
}
const source = fs.readFileSync(path.join(root, 'app.js'), 'utf8');
const manifest = JSON.parse(fs.readFileSync(path.resolve(root, '../../package/metadata.json'), 'utf8'));
assert.equal(vm.runInContext('ProjectManifest.version', context), manifest.KPlugin.Version);
vm.runInContext(source.slice(source.indexOf('const HYPR ='), source.indexOf('let lastT =')), context);
vm.runInContext(source.slice(source.indexOf('const presetState ='), source.indexOf('function renderPresets()')), context);
vm.runInContext(`
  assert.deepEqual(Array.from(sizeOf(DEFAULTS)), [360, 104]);
  assert.equal(typeof DEFAULTS.detailFields, 'string');
  for (const preset of PRESETS) {
    const state = presetState(preset), size = sizeOf(state);
    assert(size.every(v => Number.isFinite(v) && v > 0), preset.id);
    for (const status of ['normal', 'paused', 'idle', 'backend']) {
      const html = widgetHTML(state, status);
      assert(!/NaN|undefined/.test(html), preset.id + ': invalid markup');
    }
  }
  const compact = presetState(PRESETS.find(p => p.id === 'compact'));
  assert.equal(compact.layoutMode, 'compact');
  assert.deepEqual(Array.from(sizeOf(compact)), [200, 84]);
  const artwork = presetState(PRESETS.find(p => p.id === 'cover'));
  assert.equal(artwork.surfaceStyle, 'art');
  assert.equal(nativeState(artwork).artBg, true);
  for (const section of Schema.SECTIONS) for (const row of section.rows) {
    if (row.get) assert.doesNotThrow(() => row.get(nativeState(DEFAULTS)));
    if (row.when) assert.doesNotThrow(() => row.when(nativeState(DEFAULTS), 'kde'));
  }
  const layoutRow = Schema.SECTIONS.flatMap(s => s.rows).find(r => r.k === 'layoutMode');
  for (const mode of ['classic', 'compact', 'orbit', 'pill']) {
    const state = {...DEFAULTS, ...PresetCodec.browser(Schema.rowPatch(layoutRow, mode, nativeState(DEFAULTS)))};
    assert.equal(Schema.rowValue(layoutRow, nativeState(state)), mode);
  }
  const d = derive(DEFAULTS, 'normal');
  for (const mode of ['solid', 'gradient', 'cover', 'palette', 'rainbow']) {
    const stops = colorStops({...DEFAULTS, vizColorMode:mode}, d, 2);
    assert(stops.every(c => [c.r,c.g,c.b,c.a].every(Number.isFinite)));
  }
`, context);
// Browser Canvas API test double rejects invalid geometry and color conversions.
let strokes = 0;
const gradient = () => ({addColorStop(p, c) {
  assert(Number.isFinite(p) && p >= 0 && p <= 1);
  assert(!/NaN|undefined|object Object/.test(String(c)), String(c));
}});
const target = {createLinearGradient:gradient, createRadialGradient:gradient, createConicGradient:gradient};
const canvas = new Proxy(target, {
  get(obj,key) {
    if (key in obj) return obj[key];
    if (key === 'createConicalGradient') return undefined;
    return (...args) => { strokes++; for (const value of args) if (typeof value === 'number') assert(Number.isFinite(value), String(key)); };
  },
  set(obj,key,value) { if (/Style$|shadowColor/.test(key) && !(value && typeof value.addColorStop === 'function')) assert(!/NaN|undefined|object Object/.test(String(value)), String(value)); obj[key]=value; return true; }
});
context.canvas = canvas;
vm.runInContext(`
  const element = {clientWidth:160, clientHeight:64, width:0, height:0, dataset:{}, getContext:() => canvas};
  for (let type = 0; type < VIZ.length; type++) {
    const state = {...DEFAULTS, visualizerType:type, vizColorMode:'palette'};
    const entry = {el:element, key:'wave-'+type, getS:()=>state, getStatus:()=> 'normal'};
    for (let frame = 0; frame < 30; frame++) drawWave(entry, frame / 30);
  }
  for (const style of ORBITS) {
    const state = {...DEFAULTS, orbitStyle:style.toLowerCase(), vizColorMode:'palette'};
    const entry = {el:element, key:'orbit-'+style, getS:()=>state, getStatus:()=> 'normal'};
    for (let frame = 0; frame < 30; frame++) drawOrbit(entry, frame / 30);
  }
`, context);
assert(strokes > 0);
console.log('PASS: generated modules, presets, layout sizing, settings conversion, all waveform and orbit drawing paths');
vm.runInContext(source.slice(source.indexOf('function stagePlacement('), source.indexOf('function fitStage()')), context);
vm.runInContext(`
  for (const [sw, sh] of [[600,420], [340,320], [900,520]]) {
    for (const [w, h] of [[360,104], [250,332], [660,44]]) {
      for (const zoom of [1, 2]) {
        const above = h === 44 ? 116 : 0;
        const p = stagePlacement(sw, sh, w, h, 68, 60, zoom, above);
        assert(p.left >= 19.99);
        assert(p.top - above * p.scale >= 67.99);
        assert(p.top + h * p.scale <= sh - 59.99);
        assert(Math.abs(p.left * 2 + w * p.scale - sw) < 1e-6);
      }
    }
  }
`, context);
const catalog = vm.runInContext('StudioCatalog.wallpapers', context);
for (const wallpaper of catalog) {
  assert(fs.existsSync(path.join(root, 'assets/studio/wallpapers', wallpaper.file)));
}
console.log('PASS: stage centering, toolbar/pop-up clearance, zoom bounds, wallpaper assets');
// Settings rows must accept the shared schema's arrays, dynamic options, and
// canonical getters. DOM styling and pixel output require browser visual testing.
const element = () => ({innerHTML:'',dataset:{},style:{setProperty(){}},classList:{toggle(){}},querySelector:()=>element(),querySelectorAll:()=>[],setAttribute(){},addEventListener(){}});
context.document = {createElement:element, activeElement:null};
context.$ = (selector, parent) => parent.querySelector(selector);
context.$$ = (selector, parent) => parent.querySelectorAll(selector);
context.renderProjectInfo = context.renderPresetPicker = context.renderUserPresets = context.renderAnchor = () => () => {};
context.diag = () => '';
context.platformNote = () => '';
vm.runInContext('let S = structuredClone(DEFAULTS); const SCREENS = [];', context);
vm.runInContext(source.slice(source.indexOf('function buildRow('), source.indexOf('function renderSettings()')), context);
vm.runInContext(`
  for (const section of Schema.SECTIONS) for (const row of section.rows) {
    const built = buildRow(row);
    built.sync(DEFAULTS);
    assert(!/undefined|NaN/.test(built.el.innerHTML), row.k || row.id);
    if (row.type === 'tiles' && row.opts.some(o => o.pv === 'material')) {
      for (const option of row.opts) {
        assert(built.el.innerHTML.includes('data-material="' + option.v + '"'));
        MaterialPreview.draw(canvas, 110, 50, option.v);
      }
      assert(!built.el.innerHTML.includes('>material<'));
    }
  }
`, context);
console.log('PASS: every shared settings row builds and synchronizes');

vm.runInContext(`
  const daily = Schema.dailyLook('2026-09-16');
  assert.equal(JSON.stringify(daily), JSON.stringify(Schema.dailyLook('2026-09-16')));
  assert.notEqual(JSON.stringify(daily.s), JSON.stringify(Schema.dailyLook('2026-09-17').s));
  const scheduled = Schema.dailyUpdate(LOOK_DEFAULTS, {...LOOK_DEFAULTS, autoDailyLook:true, inputSource:'my-monitor', favoritePresets:'["glass"]'}, '2026-09-16');
  assert.equal(scheduled.inputSource, 'my-monitor');
  assert.equal(scheduled.favoritePresets, '["glass"]');
  assert.equal(Schema.dailyUpdate(LOOK_DEFAULTS, {...scheduled, customColor:'#123456'}, '2026-09-16'), null);
  assert.equal(ProjectInfo.count('{"value":"1.2k"}'), '1.2k');
  assert.equal(ProjectInfo.count('{"value":"0"}'), '0');
  assert.equal(ProjectInfo.count('{"value":"not found","isError":true}'), '');
  assert.equal(ProjectInfo.count('<html>offline</html>'), '');
`, context);
console.log('PASS: daily determinism, automatic appearance preservation, optional project statistics');

const readme = fs.readFileSync(path.resolve(root, '../../README.md'), 'utf8');
const badgeUrl = new URL(readme.match(/src="([^"\n]+)" alt="KDE Store Downloads"/)[1]);
const studioBadge = new URL(vm.runInContext("ProjectInfo.statistics.find(s => s.id === 'kde').url", context));
assert.equal(studioBadge.searchParams.get('url'), badgeUrl.searchParams.get('url'));
assert.equal(studioBadge.searchParams.get('query'), badgeUrl.searchParams.get('query'));
vm.runInContext(`
  for (const mode of ['solid', 'gradient', 'cover', 'palette', 'rainbow']) {
    const state = {...DEFAULTS, vizColorMode:mode, controlsColorSource:'visualizer', progressColorSource:'visualizer'};
    const d = derive(state, 'normal');
    assert(d.pgStops.length > 0);
    assert.equal(d.control, d.pgStops[0]);
    for (const style of [4, 5, 7]) {
      const el = {clientWidth:160, clientHeight:18, width:0, height:0, dataset:{}, getContext:()=>canvas};
      drawSeek({el, key:'linked-'+mode+'-'+style, pbs:style, getS:()=>state, getStatus:()=> 'normal'}, 2);
    }
  }
`, context);
console.log('PASS: README download source parity and linked colours for every progress canvas');
