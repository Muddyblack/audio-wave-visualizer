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
