// Strings that Plasma reads from metadata.json through KJsonUtils, not from
// code. KJsonUtils resolves "Description[<lang>]" in the plasmoid's own
// translation domain, so it belongs in template.pot; this shim is what puts it
// there. It is never executed — Messages.sh only feeds it to xgettext.
//
// Keep the argument byte-for-byte identical to metadata.json, otherwise the
// catalog would translate a string that never reaches the screen.
i18n("Reactive audio visualizer with 16 visualizer styles, 28 built-in presets, a live settings studio, album artwork with glass/liquid card styling, synced lyrics, and MPRIS playback controls.");
