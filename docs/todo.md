# Future Roadmap & Feature TODO

## 1. Audio Engine & DSP Innovations

- [ ] **Audio Input & Sink Monitor Switcher** `[High]`
  - Allow selecting between default sink monitor, specific application audio streams (e.g. Spotify or browser only), or microphone / line-in.
  - *Technical Scope*: Extend `feeder.sh` and PipeWire/Pulse capture arguments; add input device selector in Audio settings tab.
- [ ] **Beat & Transient Detection Events** `[High]`
  - Lightweight rate-of-energy rise ($dE/dt$) detector on bass frequencies to trigger dynamic UI reactions (beat pulses, visual ripples, cover art bounce).
  - *Technical Scope*: Compute in `WaveMath.js` / `VisualizerCore.qml` and expose `beatTrigger` / `energyPulse` properties.
- [ ] **Equalizer Frequency Focus & Band Weighting** `[Medium]`
  - Add low/high cutoff filters and logarithmic vs. mel scale distribution options to emphasize bass punch or treble detail per music genre.
  - *Technical Scope*: Pass custom `cava.conf` frequency range and logarithmic scaling parameters dynamically.
- [ ] **Smart Audio State Transitions & Silence Crossfade** `[Nice to have]`
  - Smoothly interpolate visualizers down to an idle ambient state or gentle undulating wave when audio ceases, preventing abrupt visual snaps.
  - *Technical Scope*: Damping decay in `WaveMotion.qml` during playback pause/silence transitions.


---

## 5. Media Controls & Smart Metadata

- [ ] **"Up Next" Play Queue Preview Drawer** `[Medium]`
  - Collapsible flyout drawer listing the upcoming tracks from the active player's queue (where supported by MPRIS/MPD/Spotify).
  - *Technical Scope*: New `PlayQueue.qml` component using MPRIS `TrackList` interface.
- [ ] **Hi-Res Audio & Format Badges** `[Nice to have]`
  - Small badges for `FLAC`, `96kHz/24bit`, `DSD`, `Lossless`, or streaming bitrate parsed from track metadata.
  - *Technical Scope*: Display badges in `TrackDetails.qml` and `TrackText.qml`.
- [ ] **Artist Bio & Album Information Popup** `[Nice to have]`
  - Clickable info modal fetching quick release year, genre tags, and artist summary from MusicBrainz / Wikipedia.
  - *Technical Scope*: Network lookup in `ArtworkLightbox.qml` or new info modal.

---

## 6. Preset Management, Customization & Community

- [ ] **Community Preset Hub & 1-Click Install** `[High]`
  - In-app preset repository browser connected to a community catalog, allowing instant preview and 1-click import.
  - *Technical Scope*: JSON-based remote repository loader in `package/contents/ui/configStudio.qml` and web studio.
- [x] **Sound-Reactive Album Palette Generator 2.0 (Material You)** `[High]`
  - Advanced color extraction computing vibrant, muted, dominant, and accent tones from album art to automatically build harmonious 3-color gradients.
  - *Technical Scope*: Extend `CoverColors.qml` palette extraction logic.

---

## 7. Interactive Controls & Next-Gen Progress Bar Innovations

- [x] **Acoustic Waveform Profile Seekbar (Real Audio Peak Cache)** `[High]`
  - Replace synthetic pseudo-random bars (Style 4) with real acoustic amplitude peaks extracted from local audio files or cached stream analysis (SoundCloud/Audiomack style).
  - Show actual track dynamics: intros, drops, breakdowns, and quiet bridges right on the progress track.
  - *Technical Scope*: Background worker (`audiowaveform` CLI / `ffmpeg` / Python helper) generating 128 normalized float peaks into `~/.cache/plasma-audio-visualizer/peaks/<sha1>.json`; load asynchronously in `ProgressBar.qml` / `WaveArea.qml`.
- [x] **Scrubbing Hover Tooltip, Time Delta & Ghost Playhead** `[High]`
  - Hovering over the progress bar displays a floating glass pill tooltip with target timestamp (e.g. `2:45`) and relative jump delta (e.g. `+0:32` / `-1:10`).
  - Render a subtle "ghost" needle tracing cursor position before committing the seek.
  - *Technical Scope*: Add hover tracking (`hoverEnabled: true`, `containsMouse`, `mouseX`) in `ProgressBar.qml` with an animated tooltip anchored above the track.
- [x] **Interactive Gesture Controls: Wheel Seeking & Double-Tap Jumps** `[High]`
  - Scroll wheel over the progress bar or transport dock performs fine-grained seeks (configurable, e.g. ±2s or ±5s per notch).
  - Double-click on the left third of the bar skips back 10s; double-click on the right third skips forward 10s (YouTube / mobile style) with quick directional ripple animations.
  - *Technical Scope*: Add `WheelHandler` and click timestamp/coordinate heuristics to `ProgressBar.qml` `MouseArea`.
- [x] **Multi-Speed Fine Scrubbing (iOS / Pro Audio Style)** `[Medium]`
  - Dragging the seekbar horizontally seeks normally (1x); dragging the pointer vertically away from the bar decreases scrub velocity (0.5x half-speed, 0.25x quarter-speed, 0.1x fine-scrub) for pinpoint lyric and beat seeking.
  - Dynamic UI badge showing current scrubbing speed multiplier (`1x`, `½x`, `¼x`, `fine`).
  - *Technical Scope*: Calculate vertical mouse drag delta `Math.abs(mouseY - trackCenterY)` in `ProgressBar.qml` `MouseArea` to scale horizontal scrub ratio increments.
- [x] **Dynamic Audio-Reactive Seekbar Pulses & Transient Bloom** `[Medium]`
  - Progress track reacts dynamically to live audio energy: filled track thickness, glow radius, or playhead knob swells on bass kicks ($dE/dt$).
  - Subtle animated neon ripples or sparks emit from the playhead thumb along the played track during high-energy musical segments.
  - *Technical Scope*: Bind `progressTrack.height` and `MultiEffect.shadowBlur` in `ProgressBar.qml` to `VisualizerCore.bass` and `energyPulse` properties.
- [x] **Chapter Marks, Podcast Cues & Track Partitions** `[Medium]`
  - Display discrete visual notch dividers and labeled segments along the progress bar for audiobooks, podcasts, DJ sets, or albums with embedded chapter marks or cue sheets.
  - Hovering over a segment previews the chapter title; clicking snaps the playhead to the chapter start.
  - *Technical Scope*: Query MPRIS track metadata (`mpris:trackid`, chapter tags) or local `.cue`/`.chapters` files in `LyricsSource.qml` or new `ChapterModel.qml`; render tick overlays in `ProgressBar.qml`.
- [x] **A-B Looping Range Selector** `[Nice to have]`
  - Allow setting an In-point (A) and Out-point (B) marker along the progress bar to loop a specific musical phrase, guitar solo, or speech segment repeatedly.
  - Drag-to-adjust loop start and end flags with active loop range highlight.
  - *Technical Scope*: `PlaybackClock.qml` monitor that triggers `seekToFraction()` back to point A when `position >= pointB`; exposed via right-click context menu on progress bar.
- [x] **Circular & Arc Progress Dial for Cover Art / Disc Layouts** `[Nice to have]`
  - Interactive radial progress ring embracing circular album covers or vinyl disc layouts (`LayoutArt.qml`), supporting circular angular scrubbing (`atan2`).
  - Sleek neon gradient arc with orbiting playhead dot.
  - *Technical Scope*: `ArcProgress.qml` component using QML `ShapePath` conical gradient, replacing `CoverProgressRing` with interactive angular seek math.

---

## 2. Next-Gen Visual Styles & Shader FX (Completed)

- [x] **3D Audio Terrains & Grids (GLSL)** `[High]`
  - Retro synthwave perspective wireframe / neon grid undulating to audio frequencies.
  - *Technical Scope*: New GLSL fragment shader `viz_terrain.frag` with Canvas wireframe fallback.
- [x] **Audio Tunnel / Wormhole Visualizer** `[Medium]`
  - Concentric pulsing rings with depth projection reacting to beat transients and frequency distribution.
  - *Technical Scope*: `viz_tunnel.frag` using polar-to-depth coordinate mapping.
- [x] **Fluid / Metaball Liquid Plasma** `[Medium]`
  - Organic liquid blobs that merge, bounce, and distort dynamically based on audio energy and spectral bands.
  - *Technical Scope*: Distance-field metaball fragment shader `viz_fluid.frag`.
- [x] **Audio CRT Oscilloscope & Lissajous Figures** `[Nice to have]`
  - Analog oscilloscope / vectorscope simulation with phosphor green / amber persistence and electron beam bloom.
  - *Technical Scope*: Direct stereo phase visualization in shader pipeline (`viz_scope.frag`).
- [x] **Desktop Backdrop Sampling & Glass Refraction 2.0** `[High]`
  - Sample underlying desktop wallpaper / compositor layer with real Fresnel specular highlight and chromatic aberration.
  - *Technical Scope*: Enhance `BackdropBlur.qml` and `CardMaterial.qml` with Wayland layer-shell blur / Plasma background contrast effects (`glass_refraction.frag`).
- [x] **Reactive Gravity Particles 2.0** `[Nice to have]`
  - Sparks and embers emitted from EQ peaks that drift with physics inertia and turbulence.
  - *Technical Scope*: GPU compute / vertex buffer particle system in `viz_particles.frag` and `viz_particles.vert`.
- [x] **Sparkles & Starfield Shader (GLSL)** `[Medium]`
  - Dynamic twinkling starfield with sound-reactive twinkle rates and frequency-driven nebulae.
  - *Technical Scope*: `viz_sparkles.frag` using audio energy harmonics.
- [x] **Custom QML Visualizer & Progress Bar Style Loader** `[His unavailable. I’ll share the seek, gesture, and loop logic across the existing linear bar styles.
igh]`
  - User-extensible plugin architecture allowing arbitrary custom `.qml` visualizer and seekbar components loaded dynamically.
  - *Technical Scope*: `CustomVisualizer.qml`, `CustomProgressBar.qml`, `CustomStylePicker.qml`, and schema validation.


  ---
  ## 3. Synced Lyrics & Karaoke Experience

- [x] **Local `.lrc` & Embedded Audio Tag Support** `[High]`
  - Read `.lrc` files located alongside audio files, and extract embedded `USLT` / `SYLT` ID3 tags via MPRIS/file URI before querying online services.
  - *Technical Scope*: Enhance `LyricsSource.qml` to parse local metadata and file paths.
- [x] **Syllable-by-Syllable Karaoke Word-Fill Animation** `[Medium]`
  - Smooth horizontal glowing wipe animation across individual words for enhanced synced LRC timestamps (Spotify / Apple Music style).
  - *Technical Scope*: Rich text formatting with gradient-masked sub-word shaders in `package/contents/ui/layouts/Lyrics.qml`.
- [x] **Interactive On-Screen Sync Offset Nudge** `[Medium]`
  - Mini `+` / `-` 100ms offset nudge controls and keyboard shortcuts on the lyrics view for on-the-fly timing adjustments.
  - *Technical Scope*: Bind to `lyricsOffset` property directly from UI controls in `Lyrics.qml`.
- [x] **Multi-Language Lyrics, Romaji / Furigana & Translations** `[Nice to have]`
  - Side-by-side or subtitle-style translation lines, with automatic Pinyin / Romaji conversion for Asian languages.
  - Implemented with translation sidecars / paired timestamps and optional local Pinyin, Romaji and kana subtitle conversion. LRCLIB has no documented translation endpoint; see [lyrics setup](lyrics.md).

---

## 4. Desktop & Compositor Integration (Plasma 6 & Hyprland)

- [x] **Ambient Desktop LED / Wallpaper Glow** `[High]`
  - Project a soft, dynamic, sound-reactive ambient glow around the card onto the desktop wallpaper or panel edges.
  - *Technical Scope*: `CardGlow.qml` expansion with multi-stop radial bleed.
- [x] **Smart Window Snapping & Waybar / Caelestia Docking** `[Medium]`
  - Quickshell layer-shell docking to status bars with automatic margin negotiation and width expansion.
  - *Technical Scope*: Enhance `hyprland/AudioVisualizerShell.qml` and `PanelPill.qml`.
