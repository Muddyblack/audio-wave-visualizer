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

## 3. Synced Lyrics & Karaoke Experience

- [ ] **Local `.lrc` & Embedded Audio Tag Support** `[High]`
  - Read `.lrc` files located alongside audio files, and extract embedded `USLT` / `SYLT` ID3 tags via MPRIS/file URI before querying online services.
  - *Technical Scope*: Enhance `LyricsSource.qml` to parse local metadata and file paths.
- [ ] **Syllable-by-Syllable Karaoke Word-Fill Animation** `[Medium]`
  - Smooth horizontal glowing wipe animation across individual words for enhanced synced LRC timestamps (Spotify / Apple Music style).
  - *Technical Scope*: Rich text formatting with gradient-masked sub-word shaders in `package/contents/ui/layouts/Lyrics.qml`.
- [ ] **Interactive On-Screen Sync Offset Nudge** `[Medium]`
  - Mini `+` / `-` 100ms offset nudge controls and keyboard shortcuts on the lyrics view for on-the-fly timing adjustments.
  - *Technical Scope*: Bind to `lyricsOffset` property directly from UI controls in `Lyrics.qml`.
- [ ] **Multi-Language Lyrics, Romaji / Furigana & Translations** `[Nice to have]`
  - Side-by-side or subtitle-style translation lines, with automatic Pinyin / Romaji conversion for Asian languages.
  - *Technical Scope*: LRCLIB translation endpoints and secondary text line rendering.

---

## 4. Desktop & Compositor Integration (Plasma 6 & Hyprland)

- [ ] **Ambient Desktop LED / Wallpaper Glow** `[High]`
  - Project a soft, dynamic, sound-reactive ambient glow around the card onto the desktop wallpaper or panel edges.
  - *Technical Scope*: `CardGlow.qml` expansion with multi-stop radial bleed.
- [ ] **Fullscreen Screensaver & Lockscreen "Now Playing" Mode** `[Medium]`
  - Fullscreen minimalist display with oversized visualizer, album cover, and floating lyrics for idle/lock screen scenarios.
  - *Technical Scope*: Plasma lockscreen applet integration / standalone Quickshell overlay view.
- [ ] **Smart Window Snapping & Waybar / Caelestia Docking** `[Medium]`
  - Quickshell layer-shell docking to status bars with automatic margin negotiation and width expansion.
  - *Technical Scope*: Enhance `hyprland/AudioVisualizerShell.qml` and `PanelPill.qml`.
- [ ] **Mouse Gestures & Interactive Card Surfaces** `[High]`
  - Scroll anywhere on the card to adjust player volume, middle-click to toggle mute, and double-click to toggle mini/expanded mode.
  - *Technical Scope*: Add `MouseArea` wheel and gesture handlers in `VisualizerView.qml`.

---

## 5. Media Controls & Smart Metadata

- [ ] **Per-Player Volume Slider & Flyout** `[High]`
  - Discrete volume slider in the transport dock to adjust player volume directly via MPRIS `org.mpris.MediaPlayer2.Player.Volume`.
  - *Technical Scope*: `TransportDock.qml` and `CommandProcess.qml` / Quickshell MPRIS interface.
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



  --- DONE

  ## 2. Next-Gen Visual Styles & Shader FX

- [x] **3D Audio Terrains & Grids (GLSL)** `[High]`
  - Retro synthwave perspective wireframe / neon grid undulating to audio frequencies.
  - *Technical Scope*: New GLSL fragment shader `viz_terrain.frag` with Canvas wireframe fallback.
- [x] **Audio Tunnel / Wormhole Visualizer** `[Medium]`
  - Concentric pulsing rings with depth projection reacting to beat transients and frequency distribution.
  - *Technical Scope*: `viz_tunnel.frag` using polar-to-depth coordinate mapping.
- [x] **Fluid / Metaball Liquid Plasma** `[Medium]`
  - Organic liquid blobs that merge, bounce, and distort dynamically based on audio energy and spectral bands.
  - *Technical Scope*: Distance-field metaball fragment shader.
- [x] **Audio CRT Oscilloscope & Lissajous Figures** `[Nice to have]`
  - Analog oscilloscope / vectorscope simulation with phosphor green / amber persistence and electron beam bloom.
  - *Technical Scope*: Direct stereo phase visualization in shader pipeline.
- [x] **Desktop Backdrop Sampling & Glass Refraction 2.0** `[High]`
  - Sample underlying desktop wallpaper / compositor layer with real Fresnel specular highlight and chromatic aberration.
  - *Technical Scope*: Enhance `BackdropBlur.qml` and `CardMaterial.qml` with Wayland layer-shell blur / Plasma background contrast effects.
- [x] **Reactive Gravity Particles 2.0** `[Nice to have]`
  - Sparks and embers emitted from EQ peaks that drift with physics inertia and turbulence.
  - *Technical Scope*: GPU compute / vertex buffer particle system in `viz_particles.frag`.