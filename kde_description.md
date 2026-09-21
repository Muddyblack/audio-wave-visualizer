[h1]Plasma Audio Visualizer[/h1]

Oh boy this is a big one.
V3 is finally out and so many new features have been added to this new version.

We now have a website a like settings menu with instant previews of how the widget will look and so many configurations.
If one wants, one can rice up their audio visualizer widget as if there isn't already enough to rice in Linux, eh? 😂

So what is this? This is an obviously **modern** and especially riceable, customizable audio visualizer widget for KDE Plasma 6 and now even Hyprland via Quickshell support. It renders different visualisations, such as a mirrored waveform reacting in real time to whatever audio is playing system-wide, alongside complete MPRIS track info, album art, transport controls, and a seekable progress bar.

[b]See it in action:[/b] [url=https://youtu.be/ytHqeP4cBgA]Watch the video demo on YouTube[/url]


---

[b]Features[/b]
[list]
[*] [b]Dozens of Ready-Made Presets:[/b] Choose from cards, artwork backgrounds, posters, compact strips, panel icons, and more.
[*] [b]Many Audio Visualizers:[/b] Waves, bars, particles, rings, and other styles react to system audio captured by cava.
[*] [b]Live Settings Studio:[/b] Preview changes as you customize layouts, colors, visualizers, progress bars, artwork, and motion.
[*] [b]Make and Share Presets:[/b] Save your own looks and exchange them as JSON with the Plasma, Quickshell, and browser studios.
[*] [b]Custom QML Styles:[/b] Import your own visualizers and progress bars from trusted local QML files.
[*] [b]Album Art and Track Details:[/b] Show cover art, title, artist, playback time, and an optional artwork backdrop.
[*] [b]Playback Controls:[/b] Play, pause, skip tracks, and seek through MPRIS players when supported.
[*] [b]Lyrics and Karaoke:[/b] Show a synced line on the card or switch to a lyrics-only view, with local files and optional online lookup.
[*] [b]Plasma and Hyprland:[/b] Use the widget on KDE Plasma 6 or with Quickshell on Hyprland.
[/list]

---

[b]Requirements[/b]
To run the widget, you will need:
[list]
[*] [b]KDE Plasma 6[/b] with [b]kpackagetool6[/b], or [b]Quickshell[/b] for the Hyprland version.
[*] [b]cava[/b] and a running [b]PipeWire[/b] or [b]PulseAudio[/b] server for audio-reactive visuals.
[*] [b]flock[/b] (from util-linux) and [b]pkill[/b] (from procps).
[/list]

For local lyrics, install [b]Python 3[/b]. Embedded ID3 lyrics also need the Python [b]mutagen[/b] package; automatic pronunciation subtitles use optional [b]pykakasi[/b] or [b]pypinyin[/b].

If the bars stay flat, the widget now says why right where the waveform would be. For a full report, run:
[code]
bash ~/.local/share/plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer/contents/code/doctor.sh
[/code]

---

[b]Quick Install (Terminal)[/b]

[code]
git clone https://github.com/Muddyblack/audio-wave-visualizer.git
cd audio-wave-visualizer
kpackagetool6 -t Plasma/Applet -i package
[/code]

To update an existing installation:
[code]
kpackagetool6 -t Plasma/Applet -u package
[/code]

---

[b]Configuration[/b]
Right-click the widget to open its settings studio and customize:
[list]
[*] Presets: choose a ready-made look, save your own, or share one as JSON
[*] Layouts, visualizer styles, and custom QML visualizers
[*] Progress bar styles, playback buttons, and seeking options
[*] Lyrics display, timing, typography, and pronunciation subtitles
[*] System accent, artwork-based palettes, and custom colors for the visualizer, text, controls, and progress bar
[*] Card materials, shadows, corner radius, and album artwork backgrounds
[*] Audio input and source, frequency bars, frame rate, sensitivity, and smoothing
[*] Motion, power-saving behavior, and Hyprland placement options
[/list]
