# Share a Studio preset

Open **Presets → My presets**, name your current look, and save it. To share a
saved look, select it first, then choose **Copy as JSON** (on the website,
**Copy current as JSON**). Send the JSON to another user; they can paste it into
**Import JSON** in the desktop or web Studio.

The export contains visual settings, not custom QML files, favourites, or the
automatic daily setting. A look using a custom QML style needs that trusted file
installed separately. Never treat an unfamiliar QML file as a harmless preset.

## Suggest a preset for everyone

1. Fork [the repository](https://github.com/Muddyblack/audio-wave-visualizer).
2. Add the exported JSON as `docs/preset-submissions/your-look.json` in your fork.
3. Open a pull request with a short description, a screenshot, and the name you
   want credited. Use built-in styles so other users can reproduce the look.

The GitHub web editor is enough to add the file. Submissions are reviewed;
opening a pull request does not publish or install a preset automatically.
Accepted looks can be added to the bundled preset list in a future release.

## Daily looks and favourites

**Presets → Today’s look** generates one variation from built-in styles for your
local calendar date. Reopening Studio does not shuffle it. Save or star it to
keep a copy in My presets; tomorrow's suggestion does not replace that copy.

**Apply today’s look automatically** is optional and off by default. On desktop,
apply your settings to enable it. The running widget checks the date on startup
and every 30 seconds, applies the daily appearance once, and remembers the date
across restarts. Audio settings, placement, and preset libraries are preserved.
Manual changes then stay until the next day. Turning it off keeps the current
look. In the web Studio the option affects only that browser, while the page is
open or on the next visit; it cannot change your desktop widget.

Favourites are local to your widget configuration or browser. The star marks a
look without applying it. Import/export can transfer saved looks between them.
