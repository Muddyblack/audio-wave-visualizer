# Share a Studio preset

Open **Presets → My presets**, name the current look, and save it. Select a saved look and choose **Copy as JSON** (or **Copy current as JSON** on the website). Send the JSON to another user, who can paste it into **Import JSON** in the desktop or web Studio.

The export includes visual settings, but not custom QML files, favourites, or the automatic daily setting. Custom QML styles must be installed separately. Only import QML files you trust; they are executable code, not harmless themes.

## Suggest a preset

1. Fork [the repository](https://github.com/Muddyblack/audio-wave-visualizer).
2. Add the exported JSON under `docs/preset-submissions/your-look.json` in your fork.
3. Open a pull request with a short description, screenshot, and attribution name. Use built-in styles so others can reproduce the look.

Submissions are reviewed; opening a pull request does not automatically publish or install a preset. Accepted looks may be included in a future release.

## Daily looks and favourites

**Presets → Today’s look** generates one variation from built-in styles for the local calendar date. Reopening Studio does not shuffle it. Save or star it to keep a copy in My presets; tomorrow’s suggestion does not replace that copy.

**Apply today’s look automatically** is optional and off by default. The desktop widget checks the date at startup and every 30 seconds, applies the daily appearance once, and remembers the date across restarts. Audio settings, placement, and preset libraries are preserved. Manual changes remain until the next day. The web Studio option affects only that browser and cannot change the desktop widget.

Desktop favourites and saved looks are stored in `~/.config/audio-wave-visualizer-presets.ini` and shared by Plasma widgets and the Hyprland Studio for that user. Removing a widget does not delete them. The web Studio keeps a separate browser-local library. Import/export transfers saved looks between desktop and web Studios.
