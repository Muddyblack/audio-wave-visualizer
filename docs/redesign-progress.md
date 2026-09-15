# Redesign progress

Updated: 2026-09-15. Checklist for [redesign-plan.md](./redesign-plan.md), using
[index.html](./index.html) as the visual reference.

**Phases 1–11 are implemented with the limits below. Live desktop, browser visual
and power acceptance are still open.**
New configuration keys alone do not mean their features are implemented.

## Roadmap status

| Phase | Plan item | Status |
|---|---|---|
| 1 | Split shared components; add configuration defaults; preserve Classic | Implemented; 43 exact software snapshot comparisons pass |
| 2 | Bass, mid, high, smoothed bass and attack analysis | Implemented; synthetic audio and deterministic analysis tests pass |
| 3 | Visualizers 6–15, direction, colour modes, palettes, bloom, hue drift | Implemented in Canvas and shader families; 53 exact HTML-source comparisons pass on Qt; 42 GPU shader/Canvas rows measured on an OpenGL desktop; browser acceptance pending |
| 4 | Progress styles 5–10 and time format | Implemented in the Classic layout with Plasma and Hyprland settings; Classic snapshots unchanged; browser acceptance pending |
| 5 | Mirrored, inline, hero, stacked, strip, poster and orbit layouts | Implemented; orbit ring is Canvas-only (no shader family yet); Classic snapshots unchanged; GPU parity unchanged |
| 6 | Card materials, glass/liquid, depth and wallpaper sampling | Implemented without blur-behind, refraction or wallpaper sampling; Classic snapshots unchanged |
| 7 | Artwork shapes/effects and control dock options | Implemented; Classic snapshots unchanged; tilt has no perspective and reflection needs the GPU scene graph |
| 8 | Richer track information and opt-in lyrics | Implemented; format detail and live Plasma/Hyprland popup checks pending |
| 9 | Idle/paused behaviour, interaction and power options | Implemented; system reduced-motion preference and live battery checks pending |
| 10 | Panel pill/icon and popup; Waybar/Quickshell bar integration | Implemented; not yet checked in a live Plasma panel or Hyprland bar |
| 11 | Studio settings, search, preview, presets and diagnostics | Implemented in shared Plasma/Hyprland studio; automated settings tests pass; live Plasma and browser visual acceptance pending |
| 12 | README/gallery, release screenshots and version | Not started; developer workflow documentation is updated |

## Implemented work

### Phase 1 — shared components and compatibility

- [x] Extract `ArtView`, `CardSurface`, `ProgressBar`, `TrackText`, `TransportDock`,
  `WaveArea` and `layouts/Classic` from `VisualizerView`.
- [x] Keep Plasma and Hyprland using the same view and rendering components.
- [x] Add all 68 planned configuration keys and Hyprland's `hAnchor` default.
- [x] Parse StringList defaults and compare configuration values correctly.
- [x] Preserve the **29 actual original keys/defaults**, including
  `alwaysVisible=false`. The plan's count of 28 and its `alwaysVisible` annotation
  differ from the original repository defaults.
- [x] Preserve Classic pixels in 43 software comparisons against the original
  package, covering the existing visualizers, progress bars, sizes and card states.

### Phase 2 — audio analysis

- [x] Compute normalized bass/mid/high from raw source levels, before display
  smoothing, using fractional 20/40/40 frequency-bin ranges.
- [x] Add a 150 ms smoothed bass envelope and one-sample attack detection.
- [x] Reset analysis across capture, visibility and backend transitions; ignore
  obsolete asynchronous reads after a reset.
- [x] Keep cava, the shared frame transport and the existing audio clock.
- [x] Test frequency splits, malformed reads, attack timing, resets, silence and
  live synthetic feeder updates.

### Phase 3 — visualizers and colour

- [x] Peak Bars, LED Meter, Mountain, Oscilloscope, Ribbon, Radial Burst,
  Pixel Matrix, Pulse Orb, Sparkles and Silk Ribbon in both renderers.
- [x] Downward direction for the supported bar/area styles.
- [x] Solid, gradient, cover, palette and rainbow colour modes.
- [x] Aurora, Ember, Ice, Grove, Iris and Coral palettes; reactive hue and bloom.
- [x] Silk Ribbon curvature/fullness and band-driven geometry.
- [x] Cover accent/palette: Plasma ImageColors integration and a cached small
  image sampler for other hosts. Sampling does not follow audio frames.
- [x] Shared peak, particle and ripple state: at most 32 particles and 4 ripples,
  advanced once per audio timestamp. Waking cannot advance the first frame twice.
- [x] Keep time-dependent effects moving during a steady audible tone; retain
  the original clock suppression for default styles and settled silence.
- [x] Five shader families with bounded local bar lookups, analytic GPU bloom,
  generated shader packages and byte-for-byte rebuild checks.
- [x] Expose waveform options in the existing Plasma and Hyprland settings pages.
- [x] Add a reproducible comparison harness extracting the HTML drawing source.

### Phase 4 — progress styles and time labels

- [x] Squiggle, Segmented, Dotted, Capsule, Time only and Cover ring, following
  the HTML `.pb` CSS and `drawSeek` geometry and colours.
- [x] Squiggle phase rides audio frames; its amplitude settles with a one-shot
  transition when paused or with reduced motion, so a flat squiggle stops repainting.
- [x] Click the cover ring to seek clockwise from the top, using the same
  player-unit and capability handling as the linear bars. Rounded and circular
  rings preserve the cover action in their centre.
- [x] Cover ring (`CoverRing.qml`) replaces the bar around the cover, which shrinks
  by 6 px; without a cover the bar falls back to style 0.
- [x] `showTimes` and `timeFormat` (`-2:27` remaining), including the HTML's
  reduced bar heights without labels; Time only keeps its labels.
- [x] Plasma and Hyprland settings expose the new styles and time options.

### Phase 5 — layouts

- [x] Orbit (250 × 332): cover in the centre, `OrbitCanvas.qml` + `code/OrbitDraw.js`
  translate `drawOrbit` — bars, wave, dots, ribbon and sparks, mirrored ring
  values, conic colour gradient, reach, rotation (`t·0.2`, audio-frame clock),
  bass cover pulse. Sparks are capped at 32 and advance once per audio
  timestamp; reduced motion removes them and stops rotation.
- [ ] Orbit has no ShaderEffect family yet (plan C6/P1). It rasterizes a
  box-sized Canvas per audio frame on every scene graph; measure before relying
  on it for the heaviest presets.

- [x] Mirrored, Inline, Hero wave, Stacked, Poster and Slim strip, with the HTML
  sizes, padding (card on/off), gaps, text scales and cover sizes (`artScale`).
- [x] Shared layout parts (`layouts/Layout*.qml`) for cover + ring, progress,
  wave, dock and texts; `code/Layouts.js` holds the size table and mode fallback.
- [x] Poster: faded visualizer texture (`edgeFade` in both renderers, a shader
  uniform in every family), accent meta line, 1–2 line title, large clock that
  replaces the bar's time labels.
- [x] `titleSize` and `textAlign` apply to Classic too (defaults unchanged).
- [x] Plasma sizes the widget from the layout; Hyprland does so while
  `widgetWidth`/`widgetHeight` stay at the 360 × 104 default.
- [x] Plasma and Hyprland settings: layout, title size, alignment, cover size and
  poster options. Orbit and the panel pill are not offered until implemented.

### Phase 6 — card materials and depth

- [x] `surfaceStyle` glass, liquid (clear/frost/cover tint, rim light, inner
  glow, pointer specular), solid and atmosphere (cover palette) in
  `CardMaterial.qml`; the cover background (`artBg`) still wins over them.
- [x] `cardShadow` soft/lifted and `bassPulse` in `CardGlow.qml`; `edgeHighlight`;
  `grain` in `CardGrain.qml`; `autoContrast` dark ink on Solid.
- [x] Every layer is a Canvas painted once per size/setting/cover change (about
  50 ms); the bass pulse only changes opacity per audio frame. The default card
  loads none of them.
- [ ] Not implemented: blur behind glass/liquid (a `NoBackground` plasmoid gets
  no compositor blur; Hyprland users can add a layer blur rule), liquid
  refraction (`glassRefraction` has no effect) and wallpaper sampling.
  soft-light specular and overlay grain are approximated in normal blending.
- Performance note: Qt Canvas `shadowBlur` took up to 5 s for the lifted shadow,
  and per-pixel `ImageData` loops became 100+ s on their second run. Shadows are
  separable Gaussians built from native gradients instead.

### Phase 7 — artwork and controls

- [x] `artShape` sharp, rounded, squircle, circle, vinyl (grooves, round cover
  label, 7 s/turn) and CD (iridescent disc, faint cover print, 3 s/turn). Spins
  advance on audio frames only and stop when paused or with reduced motion.
- [x] `artScale` in every layout, `artBorder` none/subtle/accent, `artGlow`
  (cover-tinted, via `CardGlow`), `artTilt` after 160 ms of cover hover with stationary click targets, `artReflect`,
  `artGrayPaused`, `artFallback` icon/gradient/initials, `artClick` zoom
  (cover and track over the card) or raise the player.
- [x] The progress ring follows the cover shape.
- [x] `dockStyle` glass/bare/accent/hover, `showSkipButtons`,
  `showShuffleRepeat` (`DockToggle.qml`) using Plasma `shuffle`/`loopStatus` and
  Quickshell `shuffle`/`loopState`.
- [ ] Limits: Qt Quick rotations have no perspective, so tilt is flatter than
  the HTML; the reflection and cover images need the GPU scene graph
  (MultiEffect); the zoom view stays inside the card rather than a lightbox; the
  Quickshell loop values (None = 0, Track = 1, Playlist = 2) match the installed
  QML type metadata; real-player shuffle/repeat still need a desktop check.

### Phase 8 — track information

- [x] Player chip (`showSource`) with the player name, player switcher
  (`showPlayerSwitch`: Plasma cycles `Mpris2Model.currentIndex` past its
  automatic row, Hyprland pins the next Quickshell player), `showAlbum`
  (album · year) and `marquee` (titles over 26 characters, 14 s loop on the
  audio clock, off with reduced motion). Classic now uses the shared texts;
  its snapshots are unchanged.
- [x] `hoverDetails`: `tooltip` and `drawer` in a host popup (Plasma
  `PlasmaCore.Dialog`, Quickshell `PopupWindow`), `flip` uses an explicit info button with
  separate front/back faces swapped halfway. A fixed return button and Escape
  restore playback controls; hover never flips the card and hidden/turning faces
  cannot intercept clicks. Reduced motion skips the flip animation. `TrackDetails.qml` shows the
  `detailFields` rows that have data: album (year), track number, genre,
  length, player and a volume bar.
- [x] `showLyrics`: `LyricsSource.qml` asks LRCLIB only while enabled, caches
  hits and misses on disk (LocalStorage; misses retried after a day) and shows
  the current synced line on the card and in the details.
- [ ] Limits: the `format` field is not available (it needs the stream's
  PipeWire node); genre, track number and year come from Quickshell metadata
  and are absent on Plasma, which does not expose them; the popups and player
  switching were compiled and unit-tested but not yet checked on a live
  Plasma or Hyprland desktop; the marquee clips instead of the HTML's edge fade.

### Phase 9 — behaviour

- [x] `idleText` ("Nothing playing / Start music in any player") and
  `idleAmbient` (energy .22, slowed time) while no player is open.
- [x] `dimWhenPaused` (content at .55, card unchanged) and
  `fadeVizWhenPaused` (visualizer at .28, poster texture too).
- [x] `hoverLift` (−3 px, ×1.01) and `scrollVolume` (±4 % player volume per
  notch with a vertical bar beside the card for 1.1 s).
- [x] `batterySaver`: hosts report the power source (Plasma `powermanagement`
  data engine, Quickshell `UPower.onBattery`); on battery the widget polls at
  most 20 Hz and draws no glow. `reducedMotion` and `simpleRender` were already
  wired.
- [ ] Limits: the ambient wave has no audio frames to ride, so it uses a timer
  at the frame rate capped to 20 Hz, only while enabled and idle; the battery
  cap limits drawing, not cava's own capture rate; the volume bar sits outside
  the card and may be clipped by the widget's window; the system reduced-motion
  preference (`Kirigami.Units.longDuration == 0`) is not followed yet; battery
  switching was not checked on a live desktop.

### Phase 10 — panel

- [x] Shared pill (`layouts/Pill.qml`): cover with optional ring, EQ (`off`,
  `static` without redraws, `live` on the audio clock, `wave` mini visualizer),
  Title · Artist / Artist — Title, play or prev/play/next buttons, underline
  progress, width following the content up to `pillMaxWidth`. Panel icon
  (`layouts/PillIcon.qml`): cover with EQ badge, or a mini orbit ring.
- [x] `pillClick`: `popup` asks the host for the full card, `toggle` plays and
  pauses. Without a card the pill gets the hover tint; with one it is fully
  rounded. Hover details use the tooltip popup.
- [x] Plasma: `compactRepresentation` in panels while `autoPillInPanel` is on
  (vertical panels always use the icon); the popup is Classic with a card,
  glass unless a material is chosen, radius ≥ 14 and a lifted shadow.
- [x] Hyprland: `hyprland/PanelPill.qml` bar module (reads `hyprland.json`,
  shares the desktop feeder, reads audio only for live/wave EQ or the open
  popup, popup card below the pill) and `run.sh --waybar` (JSON lines from
  `playerctl`, tested with a fake `playerctl`).
- [x] Plasma and Hyprland settings for the pill keys; `layoutMode` pill/pillicon.
- [ ] Not yet checked in a live Plasma panel or Hyprland bar (the bar module
  loads in Quickshell; the Plasma compact representation passed lint only).

### Phase 11 — studio settings

- [x] Shared `studio/Studio.qml`, hosted by Plasma `configStudio.qml` and
  Hyprland `SettingsPage.qml`: 11 tabs, search across tabs, conditional rows,
  platform notes, tiles, switches, ranges, colours and placement controls.
  Tabs wrap into two visible rows at the normal studio size and extra rows at
  narrow widths; no horizontal scrolling is needed. Changing tabs/search returns
  the settings body to the top. Hyprland position controls live under Behaviour;
  Plasma has no redundant Placement tab. Accent source, colour mode, palettes,
  glow and bloom are grouped under Colours.
- [x] Preview of the draft with synthetic audio capped at 15 Hz, wallpaper,
  playback/error states and zoom; stop preview clocks when the studio is hidden.
  Accent swatches select a custom accent in the draft (disabling system/cover
  accent sources), so Apply persists the colour. The settings-page regression
  verifies the preview, selection indicator and Apply payload.
- [x] 27 built-in looks, category filters, Keep my colours and Surprise me;
  named user presets with removal, JSON copy/import and placement exclusion in
  their own My presets tab next to the built-in Presets tab.
- [x] Diagnostics card runs the existing doctor script through each host.
  Hyprland retains draft/Apply, Reset and persisted overrides; Plasma exposes
  the `cfg_*` properties used by its configuration dialog.
- [x] Fix delegate ID shadowing (`studioRoot` and `sectionRoot`), wait for complete
  preview configurations, and stop queued motion updates during destruction.
- [x] Shuffle/repeat controls respect player support, report their state in
  tooltips and distinguish repeat-track with a “1” badge. Test both Plasma enum
  and Quickshell boolean/enum APIs, unsupported players, and studio clicks.
  Support flags follow the [Quickshell MprisPlayer API](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/).
  The session sandbox cannot connect to the desktop media bus, so live player
  behavior is not verified. The combined flip/shuffle/repeat regression clicks the
  actual view controls and verifies that hovering leaves them available.
- [x] Use controls' implicit heights so tile grids and Saved looks cannot overlap;
  test filtered built-ins and the separate saved-thumbnail form at narrow and
  wide widths.
- [x] Regression coverage for all tabs, cross-tab search, tile selection, preset
  mappings, delayed draft loading and hidden preview clocks. Undefined bindings,
  type/reference errors and binding loops fail the studio/settings tests.
- [x] Inspect offscreen screenshots of Presets, Visualizer, Card and filtered
  Saved looks. These verify layout only; software rendering omits cover effects.
- [ ] Live Plasma Apply/Cancel/defaults and diagnostics interaction; desktop GPU
  screenshots against the HTML, keyboard/accessibility polish and power checks.
  Qt 6.11 still emits `Model size of -1 is less than 0` warnings when opening
  the controls tab; no associated test failure, root cause not yet established.
- [ ] Orbit/Halo/Sunburst are selectable but remain unaccepted pending the orbit
  shader/power follow-up below. Other incomplete rendering features retain their
  earlier limitations.

## Verification and limits

- **Full suite:** `make test` (`python3 tests/run.py`) passes: **338 QML tests**,
  **24 Python feeder tests**, and all **5 shader package rebuild checks**. The 40
  GPU rows skip there because it uses the software renderer.
- **GPU parity:** `make parity` renders every shader row beside WaveCanvas on the
  real desktop GPU and saves the image pairs. All **42 rows pass** on OpenGL; the
  largest differences are the two bloom approximations (Peak Bars glow 0.057,
  Silk Ribbon glow 0.039 RMS). New-row limits are now set from these measurements.
  The earlier fixed 400 ms wait could grab an unpainted Canvas on a cold start;
  the test now waits for the Canvas `painted` signal.
- **Progress styles:** Classic snapshots (45 rows) are identical to the original
  package; styles 5–10 were checked visually in software renders, not yet against
  a browser screenshot.
- **HTML source:** all **53 comparisons are pixel-identical** on Qt's rasterizer:
  ten new styles at regular/mini sizes, reactive palettes, cover/rainbow colours,
  and downward styles 6–8. These comparisons disable optional bloom and inject
  identical final levels, band values, time, particles, peaks and ripples.
- **Classic:** all **43 software snapshots** still match the original package.
  Frame submissions remain about **61/window/second** with synthetic 30 Hz audio,
  for both one and three windows, with software glow disabled. This measures
  scheduling, not screen FPS or watts.
- **Software cost:** short 30 Hz benchmarks with three 320 × 44 waveforms and
  glow reached 90 audio ticks in 3 seconds after batching the approximate halos.
  Radial Burst, Sparkles and Silk Ribbon used approximately 27%, 32% and 31% of
  one CPU core respectively. These are synthetic CPU measurements, not GPU or
  compositor power measurements. The longer Classic A/B run found no sustained
  CPU regression; startup and short-run measurements vary.
- **Browser comparison runs.** `compare_html_visualizers.py --reference chromium
  --extended` now captures headless Chrome (it previously hung on legacy
  `--headless` and the crashpad flags). All 53 pairs render; none are pixel-exact
  (antialiasing), maximum normalized RGB RMSE 0.052. Bloom rows are not yet
  covered, and progress styles 5–10 are not in this harness.
- **Deliberate differences:** existing styles 0–5 preserve the installed widget's
  appearance; production particles are capped at 32 rather than the demo's 220;
  reduced motion freezes decorative phases and hues that the HTML still animates.
  New Canvas bloom uses a bounded set of halo paths; GPU bloom uses analytic light
  falloff. Neither has been accepted as matching the browser's blur.
- **Still required:** actual Plasma/Quickshell previews, GPU parity and browser
  comparison, fresh/upgrade checks, and desktop/compositor power A/B measurements.
  Whole-redesign preset and layout acceptance waits for the remaining phases.

The Plasma cover extraction path was also exercised with the installed Kirigami
module: an invisible Image produced the expected palette and reset to the fallback
after clearing its source. This is a focused component check, not a Plasma preview.

Commands and comparison details are in [workflow.md](./workflow.md#compare-new-visualizers-with-the-html-prototype).
Reproduce the main visual checks with:

```sh
python3 tests/compare_html_visualizers.py --reference qt --extended \
  --output /tmp/audio-html-comparison
python3 tests/compare_view_snapshots.py --baseline-ref <original-revision>
```

Studio continuation artifacts (temporary, not committed):

- Full suite: `/tmp/audio-interaction-full.log`
- Quickshell integration: `/tmp/audio-interaction-hyprland.log`
- Studio screenshots: `/tmp/audio-studio-shots/` (including `saved-looks.png`)

Earlier session artifacts (temporary, not committed):

- HTML report: `/tmp/audio-html-comparison-extended-final/report.html`
- Classic snapshots: `/tmp/audio-styles-classic-regression-final/`
- Test log: `/tmp/audio-styles-tests-final.log`
- Frame benchmark: `/tmp/audio-styles-frames.log`

## Wallpaper and sizing follow-up

- Replaced all six studio backdrops in QML and HTML: two pine-lake images from
  the owner's NixOS setup, plus Midnight Marina, Aurora sound, Moss & mist and
  Silver tide SVG scenes. Midnight Marina follows the theme's teal, electric blue
  and aqua palette, with distant lights and water reflections.
- Shared wallpaper files and tab/catalogue JavaScript through generated Pages
  assets; added asset generation and verification to tests and Pages. Generated
  browser copies are ignored by Git; each SVG/PNG has one tracked original.
- Removed the HTML Plasma/Hyprland toggle; the browser uses a consistent desktop
  presentation. Renderer and controls code remain separate from QML.
- Plasma cards now scale proportionally inside the host's stored rectangle;
  preset switches preserve the preview's shape and scaled button hit targets.
  The outer Plasma rectangle remains controlled by the desktop host.
- Wallpaper load/fallback tests and wide/tall/small sizing and click tests added.
  Final validation: **353 QML passed, 40 GPU-only skipped**, 24 feeder tests,
  Waybar checks, five shader package checks and Quickshell settings persistence
  passed. Asset generation/identity checks, HTML script syntax and QML wallpaper
  capture passed. Logs: `/tmp/audio-wallpapers-final.log` and
  `/tmp/audio-wallpapers-hyprland.log`.
- Chromium capture remains blocked by denied socket operations in this sandbox;
  the HTML script passes Node syntax checking. Live Plasma sizing needs a desktop
  check; the proportional frame is covered by offscreen input tests.

## Next work

Continue with **phase 12: README/gallery and release preparation**. Before release,
complete the live Plasma studio checks, compare the studio and presets with the
HTML on a GPU desktop, and resolve the rendering/power follow-ups below. Chrome
reference capture works; the outstanding browser comparisons remain listed above.

### Open follow-ups (before presets / release)

- [ ] **Orbit shader family** (`viz_orbit.frag`): GPU version of `OrbitDraw.js`
  for bars, wave, dots, ribbon and sparks (≤32 particles as uniforms), added to
  `build_shaders.py`, `WaveShader`-style loader and `make parity` rows. First
  benchmark the Canvas ring against a shader style with `benchmark_rendering.py`;
  if it costs noticeably more, do this before continuing. Must be done before
  the Orbit, Halo and Sunburst presets are accepted (`measure_power.py` A/B).
- [ ] Pulse Orb palette/rainbow differ most from Chrome (RMSE ≈ 0.05); check.
- [ ] Browser comparison for glow rows and progress styles 5–10.
- [ ] If titl option not realizeable remove it but tr ymake it work
- [ ] 
## Retry after all phases

Revisit once phases 9–12 are done:

- [ ] **Orbit shader family** — benchmark first; required before the Orbit, Halo and Sunburst presets.
- [ ] **Pulse Orb palette/rainbow vs Chrome** (RMSE ≈ 0.05).
- [ ] **Browser comparison** for glow rows, progress styles 5–10, layouts, materials and artwork.
- [ ] **Blur behind glass/liquid and liquid refraction** (`glassRefraction` has no effect); wallpaper sampling.
- [ ] **Artwork tilt perspective** (Qt Quick rotations are flat); zoom as a real lightbox instead of in-card.
- [ ] **Soft-light specular and overlay grain** blend modes (approximated in normal blending).
- [ ] **Marquee edge fade** (currently clips).
- [ ] **Track `format` detail** via the stream's PipeWire node; genre/track/year on Plasma.
- [ ] **Live desktop checks**: hover tooltip/drawer popups, player switcher, shuffle/repeat (Quickshell loop values), lyrics network/cache.
- [ ] **Software renderer**: covers, reflection and progress shadows need MultiEffect (GPU only).
- [ ] **Power A/B** (`tests/measure_power.py`) for Classic defaults and the heaviest presets.

### Midnight Marina settings palette

Replaced the neutral/olive studio chrome with colours from the local Midnight
Marina VS Code theme: midnight navy surfaces, aqua selection highlights and
cyan switch gradients. QML and HTML use one palette in `StudioCatalog.js`;
`Theme.js` and generated CSS consume it. Widget colour settings stay independent.
Focused studio checks: 29 passed; QML screenshots captured for visual review.

Palette refinement: restored neutral charcoal page/panel backgrounds, neutral
borders and text. Midnight Marina remains on buttons, enabled switches, sliders
and active selections in both QML and HTML, using the same shared palette.

Fullscreen balance: studio content is centred and capped at 1280px, with a
slightly wider settings column and a preview capped at 420px tall. Fit zoom
shrinks when needed but no longer magnifies cards beyond 1×; explicit 2× zoom
remains available. Applied to QML and HTML.

HTML presentation cleanup: removed Feasibility and Keys navigation, page content,
rendering code and unused styles. The header now uses the original widget PNG
with the product name; the same PNG serves as the favicon. Removed Design Lab
branding and simplified the introduction. Looks and Studio stay reachable on
small screens. The asset build copies `package/icon.png` into ignored outputs.
Validation: HTML structure/IDs, icon identity, JS syntax and asset checks passed.

Preset exchange: added a shared versioned codec for HTML and QML. New exports
include the complete known look; import normalizes compact/art aliases and
track-detail arrays, excludes placement/libraries, accepts legacy JSON and
rejects invalid types. Verified 11 exchange cases, 29 studio checks and a Node
round trip using the actual HTML and main.xml defaults. Removed HTML tab dots.
