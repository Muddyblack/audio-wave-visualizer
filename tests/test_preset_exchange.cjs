const fs = require('fs'), vm = require('vm'), assert = require('assert');
const appJs = fs.readFileSync('docs/website/app.js', 'utf8');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync('docs/website/assets/studio/Runtime.js', 'utf8'), context);
vm.runInContext(fs.readFileSync('hyprland/Configuration.js', 'utf8'), context);
context.xml = fs.readFileSync('package/contents/config/main.xml', 'utf8');
vm.runInContext(appJs.slice(appJs.indexOf('const HYPR ='), appJs.indexOf('const VIZ =')) + '\nvar webDefaults = DEFAULTS; var webKnown = LOOK_DEFAULTS; var qmlKnown = defaults(xml);', context);
vm.runInContext(`
var cases = [webDefaults,
 Object.assign({}, webDefaults, {layoutMode:'compact', surfaceStyle:'art', detailFields:'album,genre', titleSize:14}),
 Object.assign({}, webDefaults, {layoutMode:'orbit', detailFields:'', customColor:'#55ffcc'})];
var results = cases.map(function(state) {
 var text = PresetCodec.encode('Shared', state, webKnown, true);
 var qml = PresetCodec.decode(text, qmlKnown, false);
 var back = PresetCodec.decode(PresetCodec.encode(qml.name, Object.assign({}, qmlKnown, qml.settings), qmlKnown, false), webKnown, true);
 return {state:state, qml:qml.settings, back:back.settings};
});`, context);
for (const {state,qml,back} of context.results) {
 assert.equal(back.layoutMode, state.layoutMode);
 assert.equal(back.surfaceStyle, state.surfaceStyle);
 assert.equal(back.detailFields, state.detailFields);
 assert.equal(back.titleSize, state.titleSize);
 assert(!('userPresets' in qml));
}
new vm.Script(appJs);
console.log('PASS: actual browser and main.xml defaults, bidirectional presets, script syntax');

const presentationCode = fs.readFileSync('package/contents/code/PresentationSettings.js', 'utf8').replace(/^\.pragma library\s*/, '');
vm.runInContext('var Presentations = (function() {' + presentationCode + '; return {resolve, edit, syncAppearance}; })();', context);
vm.runInContext(`
var configured = Presentations.edit(qmlKnown,
 Object.assign(Presentations.resolve(qmlKnown, 'panel'), {layoutMode:'pill', pillEq:'wave', pillControls:'all', pillPopupTrigger:'click', progressBarStyle:-1, pillProgress:'off', customColor:'#112233'}), 'panel');
configured = Presentations.edit(configured,
 Object.assign(Presentations.resolve(configured, 'popup'), {layoutMode:'orbit', bgRadius:3, cardShadow:'none', customColor:'#abcdef'}), 'popup');
var profileResults = ['panel', 'popup'].map(function(target) {
 var native = Presentations.resolve(configured, target);
 var exported = PresetCodec.encode('Separate ' + target, native, qmlKnown, false);
 var browser = PresetCodec.decode(exported, webKnown, true);
 var imported = PresetCodec.decode(PresetCodec.encode(browser.name, browser.settings, webKnown, true), qmlKnown, false);
 var applied = Presentations.edit(configured, Object.assign({}, native, imported.settings), target);
 return {target, native, exported:JSON.parse(exported), imported:imported.settings, applied};
});`, context);
for (const {target,native,exported,imported,applied} of context.profileResults) {
 assert.equal(exported.format, 'plasma-audio-visualizer-look');
 assert.equal(exported.version, 1);
 assert.equal(imported.layoutMode, native.layoutMode);
 assert.equal(imported.customColor, native.customColor);
 assert.equal(imported.bgRadius, native.bgRadius);
 assert.equal(imported.pillControls, native.pillControls);
 assert.equal(imported.progressBarStyle, native.progressBarStyle);
 assert.equal(imported.pillPopupTrigger, native.pillPopupTrigger);
 assert(!('panelAppearance' in exported.settings));
 assert(!('popupAppearance' in exported.settings));
 const other = target === 'panel' ? 'popupAppearance' : 'panelAppearance';
 assert.equal(applied[other], context.configured[other]);
}
console.log('PASS: pill and popup designs round-trip through website JSON v1 without overwriting each other');

vm.runInContext(`
var synced = Presentations.syncAppearance(configured, 'popup');
var syncedResults = ['panel', 'popup'].map(function(target) {
 var native = Presentations.resolve(synced, target);
 var text = PresetCodec.encode('Synced ' + target, native, qmlKnown, false);
 var browser = PresetCodec.decode(text, webKnown, true);
 var back = PresetCodec.decode(PresetCodec.encode(browser.name, browser.settings, webKnown, true), qmlKnown, false);
 return {native, back:back.settings, envelope:JSON.parse(text)};
});`, context);
for (const {native, back, envelope} of context.syncedResults) {
 assert.equal(envelope.version, 1);
 for (const key of ['layoutMode', 'customColor', 'visualizerType', 'progressBarStyle', 'pillControls'])
  assert.equal(back[key], native[key]);
 assert(!('panelAppearance' in envelope.settings));
 assert(!('popupAppearance' in envelope.settings));
}
console.log('PASS: synced looks use existing v1 JSON and round-trip through website');
