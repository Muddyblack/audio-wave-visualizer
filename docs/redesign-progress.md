# Redesign progress

Updated: 2026-09-15. Checklist for [redesign-plan.md](./redesign-plan.md), using
[index.html](./index.html) as the visual reference.

**Phases 1–4 are implemented. Browser visual and desktop power acceptance are still open.**
New configuration keys alone do not mean their features are implemented.

## Roadmap status

| Phase | Plan item | Status |
|---|---|---|
| 1 | Split shared components; add configuration defaults; preserve Classic | Implemented; 43 exact software snapshot comparisons pass |
| 2 | Bass, mid, high, smoothed bass and attack analysis | Implemented; synthetic audio and deterministic analysis tests pass |
| 3 | Visualizers 6–15, direction, colour modes, palettes, bloom, hue drift | Implemented in Canvas and shader families; 53 exact HTML-source comparisons pass on Qt; 42 GPU shader/Canvas rows measured on an OpenGL desktop; browser acceptance pending |
| 4 | Progress styles 5–10 and time format | Implemented in the Classic layout with Plasma and Hyprland settings; Classic snapshots unchanged; browser acceptance pending |
| 5 | Mirrored, inline, hero, stacked, strip, poster and orbit layouts | Not started; Classic extraction provides the shared components |
| 6 | Card materials, glass/liquid, depth and wallpaper sampling | Not started |
| 7 | Artwork shapes/effects and control dock options | Not started; cover colour extraction is already available from phase 3 |
| 8 | Richer track information and opt-in lyrics | Not started |
| 9 | Idle/paused behaviour, interaction and power options | Partial: waveform reduced motion and software selection are wired; remaining behaviour is not implemented |
| 10 | Panel pill/icon and popup; Waybar/Quickshell bar integration | Not started |
| 11 | Studio settings, search, preview, presets and diagnostics | Not started; current settings pages expose the new waveform controls |
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
- [x] Cover ring (`CoverRing.qml`) replaces the bar around the cover, which shrinks
  by 6 px; without a cover the bar falls back to style 0.
- [x] `showTimes` and `timeFormat` (`-2:27` remaining), including the HTML's
  reduced bar heights without labels; Time only keeps its labels.
- [x] Plasma and Hyprland settings expose the new styles and time options.

## Verification and limits

- **Full suite:** `make test` (`python3 tests/run.py`) passes: **258 QML tests**,
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

Current session artifacts (temporary, not committed):

- HTML report: `/tmp/audio-html-comparison-extended-final/report.html`
- Classic snapshots: `/tmp/audio-styles-classic-regression-final/`
- Test log: `/tmp/audio-styles-tests-final.log`
- Frame benchmark: `/tmp/audio-styles-frames.log`

## Next work

Fix the Chrome reference capture so phases 3–4 can be compared with the browser,
then continue with **phase 5: layouts** (mirrored, inline, hero, stacked, strip,
poster, orbit). The studio settings interface and presets are still future phases.
