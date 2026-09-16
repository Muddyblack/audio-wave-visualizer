'use strict';
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];

/* ─── page tab switcher ─── */
(function() {
  const pages = $$('main div[data-page]');
  const navLinks = $$('nav.jump a[data-page]');
  function showPage(id) {
    pages.forEach(p => { p.hidden = p.dataset.page !== id; });
    navLinks.forEach(a => {
      if (a.dataset.page === id) a.setAttribute('aria-current', 'page');
      else a.removeAttribute('aria-current');
    });
    window.scrollTo(0, 0);
    requestAnimationFrame(() => { fitStage(); fitPresets(); fitHero(); });
  }
  window.showPage = showPage;
  $$('a[data-page]').forEach(a => {
    a.addEventListener('click', e => { e.preventDefault(); showPage(a.dataset.page); });
  });
})();

/* ─── config model & schema ─────────────────────────────────────── */
const HYPR = { monitor: '', verticalPosition: 0.60, desktopLayer: true, pauseWhenCovered: true, hAnchor: 'center', dockMode: 'none', dockMargin: 8, barHeight: 36, widthExpansion: true, dockPosition: 'auto' };
const SCHEMA_ENTRIES = typeof ConfigSchema !== 'undefined' ? ConfigSchema : {};
const EXISTING = {};
for (const [k, v] of Object.entries(SCHEMA_ENTRIES)) {
  EXISTING[k] = v.default;
}
const LOOK_DEFAULTS = { ...EXISTING, ...HYPR };
// The HTML renderer uses compact/art aliases; shared QML modules use the
// canonical settings. Convert only at that boundary, including list fields.
const DEFAULTS = PresetCodec.browser(LOOK_DEFAULTS);
function nativeState(state) {
  return {
    ...state,
    layoutMode: state.layoutMode === 'compact' ? (state._cardLayout || 'classic') : state.layoutMode,
    showMpris: state.layoutMode !== 'compact',
    surfaceStyle: state.surfaceStyle === 'art' ? (state._cardSurface || 'color') : state.surfaceStyle,
    artBg: state.surfaceStyle === 'art',
    detailFields: Schema.fields(state.detailFields)
  };
}

const VIZ = Schema.VIZ;
const PBS = Schema.PBS;
const ORBITS = Schema.ORBITS;
const PALETTES = Schema.PALETTES;
const SWATCHES = Schema.SWATCHES;
const BGSWATCHES = Schema.BGSWATCHES;
const PILLS = ['pill', 'pillicon'];
const isPill = s => Schema.isPill(s);
const SIZES = Layouts.SIZES;
const sizeOf = s => Layouts.size(nativeState(s));
const notPill = s => !isPill(s);
const pct = Schema.pct;
const PRESETS = Schema.PRESETS.map(p => ({ ...p, s: PresetCodec.browser(p.s) }));
const COLOR_KEYS = Schema.COLOR_KEYS;

/* ─── sample music ─────────────────────────────────────────────── */
const svgUrl = s => `url('data:image/svg+xml,${encodeURIComponent(s).replace(/'/g, '%27')}')`;
const TRACKS = [
  { title: 'A Little Further', artist: 'Northbound', album: 'Open Horizons', year: 2026, len: 238, app: 'Spotify', genre: 'Indie folk', no: 3, of: 11, format: 'Ogg Vorbis · 320 kbps',
    lyrics: ['Take the long road home tonight', 'where the hills forget the light', 'just a little further now', 'I can hear the morning somehow'],
    pal: { accent: '#bfdc9f', p1: '#c9c48a', p2: '#4d6a58', p3: '#17271f' },
    svg: `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs><linearGradient id='g' x1='0' y1='0' x2='.6' y2='1'><stop offset='0' stop-color='#f1e6bd'/><stop offset='.5' stop-color='#8fa78c'/><stop offset='1' stop-color='#1d332c'/></linearGradient></defs><rect width='100' height='100' fill='url(#g)'/><circle cx='66' cy='32' r='11' fill='#fbf3d5' opacity='.9'/><path d='M0 66Q28 48 58 62T100 56V100H0Z' fill='#4f6b57'/><path d='M0 80Q42 62 100 78V100H0Z' fill='#1a2f27'/><text x='8' y='14' font-size='6' fill='#fff' letter-spacing='1.5' font-family='sans-serif'>OPEN HORIZONS</text></svg>` },
  { title: 'Neon Hours', artist: 'Velvet Static', album: 'Afterglow City', year: 2025, len: 204, app: 'Tidal', genre: 'Synthwave', no: 1, of: 9, format: 'FLAC · 44.1 kHz · 16-bit',
    lyrics: ['City lights in violet rain', 'every signal calls your name', 'we were neon, we were gold', 'running hot and never old'],
    pal: { accent: '#ff6fb0', p1: '#ff3d8b', p2: '#5b2cff', p3: '#140b30' },
    svg: `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs><radialGradient id='g' cx='.3' cy='.3' r='.9'><stop offset='0' stop-color='#ff4f9a'/><stop offset='.45' stop-color='#6a2cff'/><stop offset='1' stop-color='#120a2c'/></radialGradient></defs><rect width='100' height='100' fill='url(#g)'/><g fill='none' stroke='#fff' stroke-opacity='.45'><circle cx='30' cy='32' r='10'/><circle cx='30' cy='32' r='22' stroke-opacity='.25'/><circle cx='30' cy='32' r='36' stroke-opacity='.12'/></g><g stroke='#ff9fd0' stroke-opacity='.5'><path d='M0 74H100M0 84H100M0 94H100'/><path d='M50 64L20 100M50 64L80 100M50 64V100' stroke-opacity='.3'/></g></svg>` },
  { title: 'After the Rain', artist: 'Lumen Coast', album: 'Tidewater', year: 2026, len: 262, app: 'Elisa', genre: 'Ambient pop', no: 7, of: 12, format: 'FLAC · 96 kHz · 24-bit',
    lyrics: ['Salt on the window, sun on the sea', 'the storm took the noise away from me', 'after the rain there is only the tide', 'and everything quiet we held inside'],
    pal: { accent: '#f5b26b', p1: '#f2a65a', p2: '#1f6f78', p3: '#0b2328' },
    svg: `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs><linearGradient id='g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#f7c57e'/><stop offset='.5' stop-color='#e0775a'/><stop offset='.51' stop-color='#1f6f78'/><stop offset='1' stop-color='#0b2c33'/></linearGradient></defs><rect width='100' height='100' fill='url(#g)'/><circle cx='50' cy='50' r='16' fill='#ffe0a6'/><rect y='50' width='100' height='50' fill='#1f6f78' opacity='.9'/><g stroke='#ffd9a0' stroke-opacity='.55' stroke-linecap='round'><path d='M38 58h24M32 66h36M40 74h20M30 82h14M56 82h14'/></g></svg>` },
];
TRACKS.forEach(t => t.cover = svgUrl(t.svg));
const LONG = { title: 'Everything We Said Before the Summer Ended (Extended Night Version)', artist: 'Northbound feat. Ada Lin' };

const P = { playing: true, pos: 91, track: 0, shuffle: false, repeat: false, volume: .8, sysAccent: '#5ef2c1' };
const fmtTime = s => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
const esc = s => String(s || '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const initials = s => (s || '').split(/\s+/).slice(0, 2).map(w => w[0]).join('').toUpperCase();
const hashHue = s => { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360; return h; };
const ICONS = {
  play: 'M8 5v14l11-7z', pause: 'M6 19h4V5H6v14zm8-14v14h4V5h-4z',
  prev: 'M6 6h2v12H6zm3.5 6 8.5 6V6z', next: 'M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z',
  shuffle: 'M10.59 9.17 5.41 4 4 5.41l5.17 5.17 1.42-1.41zM14.5 4l2.04 2.04L4 18.59 5.41 20 17.96 7.46 20 9.5V4h-5.5zm.33 9.42-1.41 1.41 3.13 3.13L14.5 20H20v-5.5l-2.04 2.04-3.13-3.12z',
  repeat: 'M7 7h10v3l4-4-4-4v3H5v6h2V7zm10 10H7v-3l-4 4 4 4v-3h12v-6h-2v4z',
  note: 'M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z',
};
const icon = name => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${ICONS[name] || ''}"/></svg>`;
const appName = d => d.t.app || 'Player';
const lyricIndexAt = t => Math.min(t.lyrics.length - 1, Math.floor(P.pos / (t.len / t.lyrics.length)));
const lyricAt = t => t.lyrics[lyricIndexAt(t)];

let colorTime = 0;
function derive(s, status) {
  const t = TRACKS[P.track];
  const hasPlayer = status !== 'idle';
  const playing = hasPlayer && (status === 'demo' || (status !== 'paused' && P.playing));
  const surf = s.showBg ? s.surfaceStyle : 'none';
  const light = surf === 'solid';
  const ink = '#1e241d';
  const accent = s.accentFromArt ? t.pal.accent : s.useSystemAccent ? P.sysAccent : s.customColor;
  const text = s.useSystemText ? (light && s.autoContrast ? ink : '#eff0f1') : s.customTextColor;
  const baseControl = s.useSystemControls ? (light && s.autoContrast ? ink : '#ffffff') : s.customControlColor;
  const dock = s.useSystemDockBg ? (light ? '#2a33241a' : '#00000047') : `color-mix(in srgb,${s.customDockBgColor} 55%,transparent)`;
  const stops = s.controlsColorSource === 'visualizer' || s.progressColorSource === 'visualizer'
    ? WaveMath.colorStops(accent, s.vizColorMode, s.vizPalette, t.pal.p1, t.pal.p2, s.hueReactive, bands(colorTime).high, colorTime, s.reducedMotion) : [accent];
  const linked = ColourStyle.resolve(s, accent, baseControl, s.useSystemControls ? accent : baseControl,
    s.useSystemControls ? (light ? accent : '#ffffff') : baseControl, stops);
  const control = ColourStyle.hex(linked.control), controlAccent = ColourStyle.hex(linked.controlAccent);
  const progress = ColourStyle.hex(linked.progressWave), pg1 = ColourStyle.hex(linked.start), pg2 = ColourStyle.hex(linked.end);
  const pgStops = linked.progressStops.map(ColourStyle.hex);
  return { t, hasPlayer, playing, surf, light, accent, text, control, controlAccent, progress, dock, pg1, pg2, pgStops };
}
const colorVars = d => `--accent:${d.accent};--text:${d.text};--control:${d.control};--control-accent:${d.controlAccent};--progress:${d.progress};--dock:${d.dock};--pg1:${d.pg1};--pg2:${d.pg2};${d.pgStops.length ? `--pg-fill:linear-gradient(90deg,${(d.pgStops.length === 1 ? [d.pgStops[0], d.pgStops[0]] : d.pgStops).join(',')});--ring-fill:conic-gradient(${d.pgStops.map((c,i) => `${c} calc(var(--p) * ${i / Math.max(1,d.pgStops.length-1)*360}deg)`).join(',')},#ffffff26 0);` : ''}`;

function artHTML(s, d, size, o) {
  const shape = s.artShape, cls = ['art', shape, 'b-' + s.artBorder];
  if (!o.coverOK) cls.push('empty', 'fb-' + s.artFallback);
  if ((shape === 'vinyl' || shape === 'cd') && d.playing && o.coverOK) cls.push('spin');
  if (s.artGlow && o.coverOK) cls.push('glow');
  if (s.artTilt) cls.push('tilt');
  if (s.artReflect && !o.small) cls.push('reflect');
  if (s.artGrayPaused && d.hasPlayer && !d.playing) cls.push('gray');
  if (s.artClick === 'zoom' && o.coverOK) cls.push('zoomable');
  let inner = '';
  if (!o.coverOK) inner = s.artFallback === 'letters' && o.title ? `<b>${esc(initials(o.title))}</b>` : s.artFallback === 'gradient' && o.title ? '' : icon('note');
  const act = s.artClick !== 'none' && o.coverOK && !o.small ? 'data-act="art"' : '';
  const art = `<div class="${cls.join(' ')}" ${act} style="--a:${size}px;--fh:${hashHue(o.title || 'x')}">${inner}</div>`;
  if (!o.ring) return art;
  const wr = ['circle', 'vinyl', 'cd'].includes(shape) ? 'round' : shape === 'squircle' ? 'sq' : '';
  return `<div class="artwrap ${wr}" style="--a:${size}px">${art}<i class="rg"></i></div>`;
}
function dockHTML(s, playing) {
  const b = (n, cls = '') => `<button class="${cls}" data-act="${n}" aria-label="${n}">${icon(n)}</button>`;
  return `<div class="dock ${s.dockStyle}">${s.showShuffleRepeat ? b('shuffle', 'xs' + (P.shuffle ? ' on' : '')) : ''}${s.showSkipButtons ? b('prev') : ''}<button class="play" data-act="play" aria-label="${playing ? 'Pause' : 'Play'}">${icon(playing ? 'pause' : 'play')}</button>${s.showSkipButtons ? b('next') : ''}${s.showShuffleRepeat ? b('repeat', 'xs' + (P.repeat ? ' on' : '')) : ''}</div>`;
}
function pbHTML(style, o, on, len, fixed) {
  const rem = o.timeFormat === 'remaining';
  const el = fixed == null ? fmtTime(P.pos) : '1:31';
  const tot = rem ? '-' + fmtTime(len - (fixed == null ? P.pos : 91)) : fmtTime(len);
  return `<div class="pb pb${style} ${o.showTimes ? '' : 'notimes'} ${on ? 'on' : ''} ${o.textAlign === 'center' ? 'center' : ''}" data-act="seek" ${fixed != null ? `style="--p:${fixed}"` : ''}><div class="track"><div class="fill"><i class="sweep"></i></div><i class="knob"></i></div><canvas data-c="seek"></canvas><div class="times"><span ${fixed == null ? 'data-el' : ''}>${el}</span><span ${fixed == null && rem ? 'data-rem' : ''}>${tot}</span></div></div>`;
}
function detailRows(s, d) {
  const t = d.t, map = {
    album: ['Album', `${esc(t.album)} (${t.year})`], track: ['Track', `${t.no} of ${t.of}`], genre: ['Genre', t.genre],
    length: ['Length', fmtTime(t.len)], format: ['Format', t.format], player: ['Player', appName(d)],
    volume: ['Volume', `<span class="vb" style="--v:${P.volume}"><i></i></span>`],
  };
  return Schema.fields(s.detailFields).filter(k => map[k]).map(k => `<dt>${map[k][0]}</dt><dd>${map[k][1]}</dd>`).join('');
}
function surfHTML(s, cls, fill) {
  const liquid = cls === 'liquid';
  const extra = liquid ? ` t-${s.glassTint}${s.glassRefraction > .02 ? ' refract' : ''}` : '';
  return `<div class="surf s-${cls}${extra}" style="opacity:${s.artBgTransparency};--bgc:${fill};--blur:${(s.artBgBlur * 24).toFixed(1)}px;--dim:${s.artBgDim}">${cls === 'art' ? '<i class="cover"></i><i class="scrim"></i>' : ''}${liquid ? '<i class="spec"></i>' : ''}<i class="edge ${s.edgeHighlight ? 'hl' : ''}"></i>${s.grain ? '<i class="grain"></i>' : ''}</div>`;
}

function widgetHTML(s, status, opt = {}) {
  const d = derive(s, status);
  const mode = s.layoutMode;
  const [W, H] = sizeOf(s);
  const bg = d.surf !== 'none';
  const pill = isPill(s);
  const radius = pill ? H / 2 : s.bgRadius;
  const base = `--W:${W}px;--H:${H}px;--r:${radius}px;`;
  if (status === 'idle' && !s.alwaysVisible)
    return `<div class="w" style="${base}${pill ? 'width:120px' : ''}"><div class="ghostw">${pill ? 'Hidden' : 'Hidden while nothing plays<br>(“Keep visible” is off)'}</div></div>`;

  let title = d.t.title, artist = d.t.artist, tcls = '', acls = '';
  if (status === 'long') ({ title, artist } = LONG);
  if (status === 'nometa') { title = 'No track metadata'; artist = 'Direct YouTube stream'; tcls = 'unknown'; acls = 'hint'; }
  if (status === 'idle') { title = s.idleText ? 'Nothing playing' : ''; artist = s.idleText ? 'Start music in any player' : ''; tcls = 'idle'; }
  const coverOK = status !== 'nometa' && status !== 'idle';
  const surfCls = d.surf === 'art' && !coverOK ? 'color' : d.surf;
  const artIsBg = d.surf === 'art' && coverOK;
  const fill = d.hasPlayer ? s.bgColor : '#ffffff0f';
  const surf = bg ? surfHTML(s, surfCls, fill) + (s.bassPulse ? '<i class="bglow"></i>' : '') : '';
  const hoverMode = opt.noHover || !d.hasPlayer || status === 'nometa' ? 'off' : s.hoverDetails;
  const hc = hoverMode === 'tooltip' || hoverMode === 'drawer' || (hoverMode === 'flip' && (pill || mode === 'strip'))
    ? `<div class="hc ${hoverMode === 'drawer' ? 'drawer' : ''} ${opt.hcAbove ? 'above' : ''}"><div class="hc-head">${artHTML(s, d, 40, { coverOK, title, small: true })}<div><b>${esc(title)}</b><span>${esc(artist)}</span></div></div><dl>${detailRows(s, d)}</dl>${s.showLyrics ? `<div class="ly" data-ly style="margin-top:8px;font-size:10.5px">${esc(lyricAt(d.t))}</div>` : ''}</div>` : '';
  const vol = s.scrollVolume ? `<div class="vol" data-vol><i style="--v:${P.volume}"></i></div>` : '';
  const cls = ['w', `L-${mode}`, bg && s.cardShadow !== 'none' ? `sh-${s.cardShadow}` : '', s.hoverLift ? 'lift' : '',
    s.dimWhenPaused && d.hasPlayer && !d.playing ? 'dim' : '', pill && !bg ? 'nobg' : '', s.bassPulse || (mode === 'orbit' && s.orbitCoverPulse) ? 'bass' : '',
    s.surfaceStyle === 'liquid' && s.glassSpecular ? 'specular' : ''];
  const vars = `${base}${colorVars(d)}--ts:${s.titleSize}px;--cover:${coverOK ? d.t.cover : 'none'};--p1:${d.t.pal.p1};--p2:${d.t.pal.p2};--p3:${d.t.pal.p3}`;

  /* ── panel pill ── */
  if (pill) {
    const ring = s.pillProgress === 'ring' && d.hasPlayer;
    const eq = s.pillEq === 'off' || !d.hasPlayer ? '' : s.pillEq === 'wave' ? `<span style="position:relative;width:${mode === 'pillicon' ? 0 : 64}px;height:20px;flex-shrink:0"><canvas data-c="wave" style="position:absolute;inset:0;width:100%;height:100%"></canvas></span>` : `<span class="eq ${s.pillEq === 'live' && d.playing ? 'live' : ''} ${d.playing ? '' : 'paused'}"><i></i><i></i><i></i><i></i></span>`;
    let body;
    if (mode === 'pillicon' && s.pillEq === 'wave') {
      body = `<div class="picon"><canvas data-c="orbit" data-r=".45"></canvas>${artHTML(s, d, 18, { coverOK, title, ring, small: true })}</div>`;
    } else if (mode === 'pillicon') {
      body = `<div style="position:relative;display:flex">${artHTML(s, d, 22, { coverOK, title, ring, small: true })}${eq}</div>`;
    } else {
      const t1 = title || 'No media', a1 = artist;
      const parts = s.pillContent === 'title' || !a1 ? `<span class="pt">${esc(t1)}</span>`
        : s.pillContent === 'artist-title' ? `<span class="pt">${esc(a1)}</span><span class="psep">—</span><span class="pa">${esc(t1)}</span>`
        : `<span class="pt">${esc(t1)}</span><span class="psep">·</span><span class="pa">${esc(a1)}</span>`;
      const b = n => `<button data-act="${n}" aria-label="${n}">${icon(n)}</button>`;
      const ctl = !d.hasPlayer || s.pillControls === 'none' ? '' : `<span class="pctl">${s.pillControls === 'all' ? b('prev') : ''}${b(d.playing ? 'pause' : 'play').replace('data-act="pause"', 'data-act="play"')}${s.pillControls === 'all' ? b('next') : ''}</span>`;
      body = `${s.pillArt ? artHTML(s, d, 20, { coverOK, title, ring, small: true }) : ''}${eq}<span class="ptxt ${tcls}">${parts}</span>${ctl}`;
    }
    const line = s.pillProgress === 'underline' && d.hasPlayer ? '<i class="pline"><i></i></i>' : '';
    return `<div class="${cls.join(' ')}" style="${vars};--pad:0"><div class="face">${surf}</div><div class="L" data-act="pill">${body}</div>${line}${hc}${vol}</div>`;
  }

  /* ── cards ── */
  const ringMode = s.progressBarStyle === 10;
  const showArt = mode !== 'compact' && mode !== 'poster' && s.showArtThumb && (!artIsBg || s.artBgKeepThumb);
  const pbStyle = ringMode && !showArt ? 0 : s.progressBarStyle;
  const art = size => showArt ? artHTML(s, d, Math.round(size), { coverOK, title, ring: ringMode && d.hasPlayer }) : '';
  const scaled = (def, cap) => Math.min(cap, def * s.artScale / 100);
  const dock = () => d.hasPlayer ? dockHTML(s, d.playing) : '';
  const faded = s.fadeVizWhenPaused && d.hasPlayer && !d.playing;
  const wave = `<div style="overflow:${s.vizVerticalOffset ? 'hidden' : 'visible'}" class="wavebox ${faded ? 'faded' : ''} ${[1, 6, 7, 8].includes(s.visualizerType) && s.vizDirection === 'down' ? 'dir-down' : ''}"><canvas data-c="wave" style="translate:0 ${Math.max(-1, Math.min(1, s.vizVerticalOffset || 0)) * 100}%"></canvas>${status === 'backend' ? '<div class="bmsg"><span>cava is not installed</span><code>sudo pacman -S cava</code></div>' : ''}</div>`;
  const pb = d.hasPlayer && (!(ringMode && showArt) || s.showTimes) ? pbHTML(ringMode && showArt ? 9 : pbStyle, s, d.playing, d.t.len) : '';
  const marq = s.marquee && title.length > 26;
  const titleInner = marq ? `<span class="mi"><span>${esc(title)}</span><span>${esc(title)}</span></span>` : esc(title);
  const srcOn = (s.showSource || s.showPlayerSwitch) && d.hasPlayer;
  const src = srcOn ? `<div class="src"><i></i>${status === 'nometa' ? 'Firefox' : appName(d)}${s.showPlayerSwitch ? '<button data-act="player" title="Switch player">3 ▾</button>' : ''}</div>` : '';
  const texts = `<div class="texts ${s.textAlign}">${src}<div class="tt ${tcls} ${marq ? 'marq' : ''}" title="${esc(title)}">${titleInner || '&nbsp;'}</div><div class="ta ${acls}">${esc(artist) || '&nbsp;'}</div>${s.showAlbum && coverOK ? `<div class="tal">${esc(d.t.album)} · ${d.t.year}</div>` : ''}${s.showLyrics && coverOK ? `<div class="ly" data-ly>${esc(lyricAt(d.t))}</div>` : ''}</div>`;

  let pad, body;
  switch (mode) {
    case 'classic': case 'mirrored': {
      pad = bg ? '4px 10px 0' : '0';
      const a = scaled(72, Math.min(72, H - (bg ? 4 : 0) - (d.hasPlayer ? 30 : 0)) - (ringMode ? 6 : 0));
      const col = `<div class="artcol">${showArt ? art(a) : '<i class="g2"></i>'}${dock()}${showArt ? '' : '<i class="g1"></i>'}</div>`;
      body = `<div class="L ${mode === 'mirrored' ? 'rev' : ''}">${col}<div class="maincol">${wave}${pb}${texts}</div></div>`;
      break;
    }
    case 'inline': {
      pad = bg ? '8px 12px 6px 8px' : '0';
      const a = scaled(H - (bg ? 16 : 8), H - (bg ? 14 : 4)) - (ringMode ? 8 : 0);
      body = `<div class="L">${showArt ? `<div class="artcol">${art(a)}</div>` : ''}<div class="maincol">${texts}${wave}<div class="pbrow">${pb}${dock()}</div></div></div>`;
      break;
    }
    case 'hero':
      pad = bg ? '12px 14px 10px' : '0';
      body = `<div class="L col" style="gap:6px">${wave}${pb}<div class="mid">${art(scaled(34, 44))}${texts}${dock()}</div></div>`;
      break;
    case 'stacked':
      pad = bg ? '18px 20px 14px' : '4px';
      body = `<div class="L col" style="gap:10px"><div class="top">${art(scaled(64, 84))}${texts}</div>${wave}<div>${pb}<div class="center" style="margin-top:4px">${dock()}</div></div></div>`;
      break;
    case 'poster': {
      pad = bg ? '12px 16px 10px' : '4px 2px';
      const meta = [artist, s.showAlbum && coverOK ? d.t.album : ''].filter(Boolean).map(esc).join(' · ');
      const viz = s.posterVizBehind ? wave.replace('class="wavebox', 'class="wavebox po-viz') : '';
      const clock = s.posterClock && d.hasPlayer ? `<span class="po-clock" data-el>${fmtTime(P.pos)}</span>` : '';
      const pbP = d.hasPlayer ? pbHTML(pbStyle, { ...s, showTimes: s.posterClock ? false : s.showTimes }, d.playing, d.t.len) : '';
      body = `<div class="L col po ${s.posterAlign === 'center' ? 'center' : ''}" style="--pvo:${s.posterVizOpacity};--pl:${s.posterLines}">${viz}<div class="po-meta ${acls}"><i></i>${meta || '&nbsp;'}</div><div class="po-title ${tcls}" title="${esc(title)}">${esc(title) || '&nbsp;'}</div><div class="po-foot">${pbP}${clock}${dock()}</div></div>`;
      break;
    }
    case 'orbit': {
      pad = bg ? '14px 16px 12px' : '4px';
      const box = W - (bg ? 60 : 28);
      const a = Math.round(Math.min(box * .56, box * .38 * s.artScale / 100)) - (ringMode ? 8 : 0);
      body = `<div class="L col" style="gap:8px"><div class="orbit ${s.orbitCoverPulse ? 'pulse' : ''}" style="width:${box}px;height:${box}px"><canvas data-c="orbit" data-r="${((a + (ringMode ? 8 : 0)) / box).toFixed(3)}"></canvas>${showArt ? art(a) : ''}</div>${texts}<div class="pbx">${pb}</div>${dock()}</div>`;
      break;
    }
    case 'strip':
      pad = bg ? '6px 8px 6px 6px' : '2px';
      body = `<div class="L">${art(H - (bg ? 12 : 4) - (ringMode ? 6 : 0))}${texts}${wave}${dock()}</div>`;
      break;
    case 'lyrics': {
      pad = bg ? '18px 20px' : '10px';
      const idx = lyricIndexAt(d.t);
      const nowColor = s.lyricsHighlight === 'accent' ? 'var(--accent)' : s.lyricsHighlight === 'custom' ? s.lyricsHighlightColor : 'currentColor';
      const head = s.lyricsShowHeader ? `<div class="lyr-head">${esc([title, artist].filter(Boolean).join(' · ')) || '&nbsp;'}</div>` : '';
      const verses = d.t.lyrics.map((line, i) => `<div class="lyr-line ${i === idx ? 'now' : i < idx ? 'past' : 'future'}" data-i="${i}">${esc(line)}</div>`).join('');
      body = `<div class="lyr-wrap ${s.lyricsAlign}" style="--lyr-size:${s.lyricsFontSize}px;--lyr-now-c:${nowColor};--lyr-past:${s.lyricsPastOpacity};--lyr-future:${s.lyricsFutureOpacity}">${head}<div class="lyr-scroll">${verses}</div></div>`;
      break;
    }
    default:
      pad = bg ? '4px 10px 0' : '0';
      body = `<div class="L col" style="gap:0">${wave}${pb}${texts}</div>`;
  }
  const front = `<div class="face front">${surf}${body}</div>`;
  if (hoverMode === 'flip' && mode !== 'strip') {
    const back = `<div class="face back">${surfHTML(s, bg && surfCls !== 'art' ? surfCls : 'glass', fill)}<div class="bk">${artHTML(s, d, Math.min(62, H - 22), { coverOK, title, small: true })}<dl><div class="bt">${esc(title)}</div>${detailRows(s, d)}</dl></div></div>`;
    return `<div class="${cls.join(' ')} flip" style="${vars};--pad:${pad}"><div class="flipin">${front}${back}</div>${vol}</div>`;
  }
  return `<div class="${cls.join(' ')}" style="${vars};--pad:${pad}">${front}${hc}${vol}</div>`;
}

function panelHTML(inner, env, popupHTML, width) {
  const mh = env === 'kde' ? 44 : 36;
  const pop = popupHTML ? `<div class="popup">${popupHTML}</div>` : '';
  const slot = `<div class="slot">${inner}${pop}</div>`;
  const clock = env === 'kde' ? '<div class="pm-clock">16:42<small>Tue 15 Sep</small></div>' : '<div class="pm-clock"> 16:42</div>';
  const tray = '<div class="pm-tray"><i></i><i style="border-radius:50%"></i><i></i></div>';
  const body = env === 'kde'
    ? `<div class="pm-ico"><i style="background:radial-gradient(circle,#fff 0 22%,#3daee9 24%);border-radius:50%"></i></div><div class="pm-ico act"><i style="background:linear-gradient(135deg,#ff9a3d,#e4572e)"></i></div><div class="pm-ico"><i style="background:linear-gradient(135deg,#5bd08b,#1f8f57)"></i></div><div class="pm-ico"><i style="background:linear-gradient(135deg,#8f9bff,#4a50c9)"></i></div><div class="pm-sp"></div>${slot}${tray}${clock}`
    : `<div class="pm-ws"><i></i><i class="on"></i><i></i><i></i></div><div class="pm-sp"></div>${slot}<div class="pm-sp"></div>${tray}${clock}`;
  return { html: `<div class="pmock pm-${env}" style="height:${mh}px;width:${width}px">${body}</div>`, mh };
}
const popupState = s => ({ ...s, layoutMode: 'classic', showBg: true, surfaceStyle: s.showBg ? s.surfaceStyle : 'glass', bgRadius: Math.max(14, s.bgRadius), cardShadow: 'lifted', hoverDetails: 'off' });

/* ─── audio analysis & wave rendering ──────────────────────────── */
function hexRgb(hex) {
  const h = hex.replace('#', '');
  const n = parseInt(h.length === 3 ? h.split('').map(c => c + c).join('') : h.slice(0, 6), 16);
  return [n >> 16 & 255, n >> 8 & 255, n & 255];
}
const hexRgba = (hex, a) => { const [r, g, b] = hexRgb(hex); return `rgba(${r},${g},${b},${a})`; };

function bands(t) {
  const bass = Math.pow(.5 + .5 * Math.sin(t * 7.4), 7);
  return { bass, mid: .5 + .5 * Math.sin(t * 1.3), high: .5 + .5 * Math.sin(t * 5.1 + 1), attack: bass > .86 };
}
function spectrum(i, n, t) {
  const p = n > 1 ? i / (n - 1) : .5;
  const env = Math.pow(Math.sin(p * Math.PI), .85);
  const beat = Math.pow(.5 + .5 * Math.sin(t * 7.4), 7);
  const a = .5 + .5 * Math.sin(t * 2.3 + i * .61 + Math.sin(t * .7 + i * .13) * 2);
  const b = .5 + .5 * Math.sin(t * 3.9 - i * .37);
  return env * (.16 + .58 * a * b + .34 * beat * env);
}
function colorStops(s, d, t) {
  return WaveMath.colorStops(d.accent, s.vizColorMode, s.vizPalette,
    d.t.pal.p1, d.t.pal.p2, s.hueReactive, bands(t).high, t, s.reducedMotion);
}

function paintFor(ctx, stops, w) {
  if (stops.length === 1) return stops[0];
  const g = ctx.createLinearGradient(0, 0, w, 0);
  stops.forEach((c, i) => g.addColorStop(i / (stops.length - 1), c));
  return g;
}

let registry = [];
const memo = new Map();
function mount(container, html, cfg) {
  container.innerHTML = html;
  $$('.w', container).forEach(el => { el._studioState = cfg.getS; el._studioStatus = cfg.getStatus; });
  $$('canvas[data-c]', container).forEach((el, i) => registry.push({ el, kind: el.dataset.c, ...cfg, key: `${cfg.key}:${el.dataset.c}:${i}` }));
}
function prepCanvas(e) {
  const c = e.el, w = c.clientWidth, h = c.clientHeight;
  if (!w || !h) return null;
  const k = (window.devicePixelRatio || 1) * (e.scale ? e.scale() : 1);
  const bw = Math.round(w * k), bh = Math.round(h * k);
  if (c.width !== bw || c.height !== bh) { c.width = bw; c.height = bh; }
  const ctx = c.getContext('2d');
  if (!ctx.createConicalGradient && ctx.createConicGradient) {
    // Qt measures conical gradients counter-clockwise; Canvas is clockwise.
    ctx.createConicalGradient = (x, y, angle) => {
      const gradient = ctx.createConicGradient(-angle, x, y);
      const addStop = gradient.addColorStop.bind(gradient);
      gradient.addColorStop = (position, color) => addStop(1 - position, color);
      return gradient;
    };
  }
  ctx.setTransform(k, 0, 0, k, 0, 0);
  ctx.clearRect(0, 0, w, h);
  return { ctx, w, h, k };
}
function rr(ctx, x, y, w, h, r) {
  if (ctx.roundRect) ctx.roundRect(x, y, w, h, Math.max(0, Math.min(r, w / 2, h / 2))); else ctx.rect(x, y, w, h);
}
function smoothTrace(ctx, pts, move) {
  if (move) ctx.moveTo(pts[0][0], pts[0][1]); else ctx.lineTo(pts[0][0], pts[0][1]);
  for (let i = 1; i < pts.length - 1; i++) ctx.quadraticCurveTo(pts[i][0], pts[i][1], (pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2);
  ctx.lineTo(pts[pts.length - 1][0], pts[pts.length - 1][1]);
}

function drawWave(e, t) {
  const s = e.getS(), status = e.getStatus(), d = derive(s, status);
  const cv = prepCanvas(e); if (!cv) return;
  const { ctx, w, h, k } = cv;
  let st = memo.get(e.key);
  if (!st) memo.set(e.key, st = { v: new Float32Array(200), peak: new Float32Array(200), energy: 0, parts: [], ripples: [], amp: 0 });
  const idle = status === 'idle';
  const target = d.playing && status !== 'backend' ? 1 : idle && s.idleAmbient ? .22 : 0;
  st.energy += (target - st.energy) * .08;
  const type = e.viz ?? s.visualizerType;
  if (st.type !== type) { st.parts = []; st.ripples = []; st.type = type; }
  const n = Math.max(6, Math.min(s.numBars, Math.floor(w / ([4, 5, 7, 12, 14, 21].includes(type) ? 4 : 2.5))));
  const sm = .3 + .62 * s.noiseReduction;
  const tt = idle ? t * .35 : t;
  for (let i = 0; i < n; i++) {
    const tg = Math.min(1, spectrum(i, n, tt) * st.energy * s.sensitivity / 100);
    st.v[i] = st.v[i] * sm + tg * (1 - sm);
  }
  const B = bands(tt), stops = colorStops(s, d, t), paint = paintFor(ctx, stops, w);
  const lw = s.lineWidth, c = h / 2, amp = i => st.v[i] * (c - lw);
  const glow = s.glowWave && !s.batterySaver ? s.bloom : 0;
  ctx.lineJoin = 'round'; ctx.lineCap = 'round';
  if (glow > 0) { ctx.shadowColor = typeof paint === 'string' ? paint : stops[Math.floor(stops.length / 2)]; ctx.shadowBlur = 7 * glow * k; }
  ctx.strokeStyle = paint; ctx.fillStyle = paint; ctx.lineWidth = lw;

  const step = Math.min(3, Math.max(0, (t - (st.time ?? t - 1 / 30)) * 30));
  st.time = t;
  for (let i = 0; i < n; i++) st.peak[i] = Math.max(st.v[i], st.peak[i] - .01 * step);
  if (s.reducedMotion || target === 0) { st.parts = []; st.ripples = []; }
  else {
    if (type === 14) {
      const slot = w / n;
      for (let i = 0; i < n; i++) if (Math.random() < st.v[i] * .22 * step && st.parts.length < 32)
        st.parts.push({ x: (i + .5) * slot, y: c + (Math.random() - .5) * st.v[i] * h, vy: -(.2 + Math.random() * .8), r: .6 + Math.random() * 1.4, life: 1 });
      st.parts = st.parts.filter(p => { p.y += p.vy * step; return (p.life -= .025 * step) > 0; });
    }
    if (type === 21) {
      const slot = w / n;
      for (let i = 0; i < n; i++) if (Math.random() < st.v[i] * .22 * step && st.parts.length < 32)
        st.parts.push({ x: (i + .5) * slot, y: c + (Math.random() - .5) * st.v[i] * h, vx: (Math.random() - .5) * 2, vy: -(.2 + Math.random() * .8), r: .6 + Math.random() * 1.4, life: 1 });
      st.parts = st.parts.filter(p => { p.vx += Math.sin(p.y * .055 + t * 2 + p.x * .023) * .035 * step; p.x += p.vx * step; p.vy += .018 * step; p.y += p.vy * step; return (p.life -= .025 * step) > 0; });
    }
    if (type === 15 && B.attack && !st.attack && st.energy > .5 && st.ripples.length < 4)
      st.ripples.push({ x: w * (.2 + Math.random() * .6), age: 0 });
    st.ripples = st.ripples.filter(p => (p.age += .03 * step) < 1);
  }
  st.beatPulse = s.reducedMotion ? 0 : B.attack && !st.attack ? 1 : (st.beatPulse || 0) * Math.exp(-step / 4.5);
  st.attack = B.attack;
  st.previousStereo = st.stereoSamples || [];
  // Synthetic preview only: desktop scopes receive real signed stereo PCM.
  st.stereoSamples = Array.from({length:32}, (_, i) => [Math.sin(i / 31 * Math.PI * 4) * .75, Math.sin(i / 31 * Math.PI * 4 + Math.sin(t) * 1.4) * .75]);

  // Delegate styles 6-21 to shared WaveDraw module when available
  if (type >= 6 && typeof WaveDraw !== 'undefined') {
    ctx.save();
    ctx.shadowBlur = 0;
    if (s.vizDirection === 'down' && [6, 7, 8].includes(type)) { ctx.translate(0, h); ctx.scale(1, -1); }
    WaveDraw.draw(ctx, {
      width: w, height: h, lineWidth: lw, levels: st.v.subarray(0, n), peaks: st.peak.subarray(0, n),
      stereoSamples: st.stereoSamples, previousStereo: st.previousStereo, beatPulse: st.beatPulse,
      particles: st.parts, ripples: st.ripples, time: tt, stops, type, glow: glow > 0, fill: s.fillWave,
      reducedMotion: s.reducedMotion, energy: st.energy, bass: B.bass, mid: B.mid, high: B.high,
      colorMode: s.vizColorMode, bloom: s.bloom, curvature: s.ribbonCurvature, fullness: s.ribbonFullness,
      hueShifted: s.hueReactive
    });
    ctx.restore();
    ctx.shadowBlur = 0;
    return;
  }

  switch (type) {
    case 0: case 10: {
      const layers = type === 10 ? [[1, 0, 1], [.7, 1.3, .55], [.45, 2.6, .3]] : [[1, 0, 1]];
      for (const [scaleA, phase, alpha] of layers) {
        const up = [], dn = [];
        for (let i = 0; i < n; i++) {
          const x = lw + i / (n - 1) * (w - 2 * lw);
          const a = amp(i) * scaleA * (type === 10 ? .75 + .25 * Math.sin(t * 2 + i * .3 + phase) : 1);
          up.push([x, c - a]); dn.push([x, c + a]);
        }
        ctx.globalAlpha = alpha;
        if (s.fillWave && alpha === 1) {
          ctx.save(); ctx.shadowBlur = 0; ctx.beginPath(); smoothTrace(ctx, up, true); smoothTrace(ctx, [...dn].reverse(), false); ctx.closePath();
          ctx.globalAlpha = .32; ctx.fill(); ctx.restore();
        }
        ctx.beginPath(); smoothTrace(ctx, up, true); ctx.stroke();
        ctx.beginPath(); smoothTrace(ctx, dn, true); ctx.stroke();
      }
      ctx.globalAlpha = 1;
      break;
    }
    case 1: case 2: {
      const slot = w / n, bw = Math.max(1.5, slot * .58);
      ctx.beginPath();
      for (let i = 0; i < n; i++) {
        const bh = Math.max(Math.min(lw, 2), st.v[i] * h * .96);
        rr(ctx, i * slot + (slot - bw) / 2, type === 2 ? c - bh / 2 : h - bh, bw, bh, bw / 2);
      }
      if (s.fillWave) ctx.globalAlpha = .75;
      ctx.fill(); ctx.globalAlpha = 1;
      break;
    }
    case 3: {
      const slot = w / n;
      for (const sign of [-1, 1]) {
        ctx.beginPath(); ctx.moveTo(0, c);
        for (let i = 0; i < n; i++) { const y = c + sign * amp(i); ctx.lineTo(i * slot, y); ctx.lineTo((i + 1) * slot, y); }
        ctx.lineTo(w, c); ctx.lineJoin = 'miter'; ctx.stroke();
      }
      break;
    }
    case 4: case 5: {
      const bold = type === 5, r = (bold ? 1.7 : 1.05) * Math.max(.8, lw / 1.8), slot = w / n;
      ctx.beginPath();
      for (let i = 0; i < n; i++) {
        const x = (i + .5) * slot, a = st.v[i] * (c - r);
        ctx.moveTo(x + r, c - a); ctx.arc(x, c - a, r, 0, 7);
        ctx.moveTo(x + r, c + a); ctx.arc(x, c + a, r, 0, 7);
        if (bold && a > 4 * r) { ctx.moveTo(x + r * .7, c - a / 2); ctx.arc(x, c - a / 2, r * .7, 0, 7); ctx.moveTo(x + r * .7, c + a / 2); ctx.arc(x, c + a / 2, r * .7, 0, 7); }
      }
      ctx.fill();
      ctx.shadowBlur = 0; ctx.globalAlpha = .25; ctx.beginPath();
      for (let i = 0; i < n; i += 2) { const x = (i + .5) * slot; ctx.moveTo(x + r * .6, c); ctx.arc(x, c, r * .6, 0, 7); }
      ctx.fill(); ctx.globalAlpha = 1;
      break;
    }
  }
  ctx.shadowBlur = 0;
}

function drawOrbit(e, t) {
  const s = e.getS(), status = e.getStatus(), d = derive(s, status);
  const cv = prepCanvas(e); if (!cv) return;
  const { ctx, w, h, k } = cv;
  let st = memo.get(e.key);
  if (!st) memo.set(e.key, st = { v: new Float32Array(160), energy: 0, parts: [] });
  const target = d.playing && status !== 'backend' ? 1 : status === 'idle' && s.idleAmbient ? .22 : 0;
  st.energy += (target - st.energy) * .08;
  const style = e.orbit ?? ORBITS.map(o => o.toLowerCase()).indexOf(s.orbitStyle);
  const S0 = Math.min(w, h) / 2, small = S0 < 30;
  const half = Math.max(12, Math.min(small ? 14 : 48, s.numBars)), n = half * 2;
  const sm = .3 + .62 * s.noiseReduction;
  for (let i = 0; i < half; i++) {
    const tg = Math.min(1, spectrum(i * .5 + half * .5, half * 2, t) * st.energy * s.sensitivity / 100);
    st.v[i] = st.v[i] * sm + tg * (1 - sm);
  }
  const cx = w / 2, cy = h / 2;
  const R = S0 * Number(e.el.dataset.r || .38) + (small ? 1.5 : 4);
  const reach = Math.max(2, (S0 - R - 2) * 1.3 * s.orbitReach);
  const rot = s.orbitRotate && !s.reducedMotion ? t * .2 : 0;
  const stops = colorStops(s, d, t);
  const glow = s.glowWave && !s.batterySaver ? s.bloom : 0;
  const ang = j => j / n * Math.PI * 2 + rot - Math.PI / 2;
  const step = Math.min(3, Math.max(0, (t - (st.time ?? t - 1 / 30)) * 30));
  st.time = t;
  if (s.reducedMotion || target === 0) st.parts = [];
  else if (style === 4) {
    for (let j = 0; j < n; j++) if (Math.random() < st.v[j < half ? j : n - 1 - j] * .12 * step && st.parts.length < 64)
      st.parts.push({ a: ang(j), r: R + 3, v: (.4 + Math.random()) * (small ? .3 : 1), life: 1, s: .6 + Math.random() });
    st.parts = st.parts.filter(p => { p.r += p.v * step; return (p.life -= .02 * step) > 0 && p.r < S0; });
  }
  // Delegate to OrbitDraw if available
  if (typeof OrbitDraw !== 'undefined') {
    OrbitDraw.draw(ctx, {
      width: w, height: h, values: st.v.subarray(0, half), R, reach, lineWidth: s.lineWidth, t,
      rot, stops, particles: st.parts, style: ORBITS[style] ? ORBITS[style].toLowerCase() : 'bars', glow, fill: s.fillWave,
      reducedMotion: s.reducedMotion
    });
    ctx.shadowBlur = 0; ctx.globalAlpha = 1;
    return;
  }
}

function seedHeights(key, n) {
  let seed = 0;
  for (let c = 0; c < key.length; c++) seed = (seed * 31 + key.charCodeAt(c)) >>> 0;
  const out = [];
  for (let i = 0; i < n; i++) {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    out.push(.15 + (seed >>> 16) / 65535 * .85 * Math.sin((n > 1 ? i / (n - 1) : 0) * Math.PI));
  }
  return out;
}
function drawSeek(e, t) {
  const s = e.getS(), d = derive(s, e.getStatus());
  const style = e.pbs ?? s.progressBarStyle;
  if (![4, 5, 7].includes(style)) return;
  const cv = prepCanvas(e); if (!cv) return;
  const { ctx, w, h } = cv;
  const prog = e.fixedP ?? P.pos / d.t.len, px = prog * w;
  let st = memo.get(e.key); if (!st) memo.set(e.key, st = { amp: 0 });
  if (style === 4) {
    const n = Math.floor(w / 5), hs = seedHeights(d.t.title + d.t.artist, n);
    for (let i = 0; i < n; i++) {
      const x = i * 5, played = x + 1.5 < px, bh = Math.max(2, hs[i] * h * (played ? 1 : .45));
      ctx.fillStyle = played ? (d.pgStops.length ? paintFor(ctx, d.pgStops, Math.max(1, px)) : hexRgba(d.progress, .9)) : hexRgba(d.text, .25);
      ctx.beginPath(); rr(ctx, x, (h - bh) / 2, 3, bh, 1.5); ctx.fill();
    }
    if (prog > 0 && prog < 1) { ctx.fillStyle = hexRgba(d.control, .95); ctx.fillRect(px - 1, 0, 2, h); }
  } else if (style === 5) {
    st.amp += ((d.playing && !s.reducedMotion ? 2.2 : 0) - st.amp) * .1;
    ctx.lineWidth = 2; ctx.lineCap = 'round';
    ctx.strokeStyle = d.pgStops.length ? paintFor(ctx, d.pgStops, Math.max(1, px)) : hexRgba(d.pg1, 1); ctx.beginPath();
    for (let x = 1; x <= px; x += 1) { const y = h / 2 + Math.sin(x * .38 - t * 6) * st.amp; x > 1 ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
    ctx.stroke();
    ctx.strokeStyle = hexRgba(d.text, .25); ctx.beginPath(); ctx.moveTo(Math.min(w - 1, px + 5), h / 2); ctx.lineTo(w - 1, h / 2); ctx.stroke();
    ctx.fillStyle = d.control; ctx.beginPath(); rr(ctx, px - 1.5, 0, 3, h, 1.5); ctx.fill();
  } else {
    for (let x = 3; x < w; x += 6) {
      const played = x < px;
      ctx.fillStyle = played ? (d.pgStops.length ? paintFor(ctx, d.pgStops, Math.max(1, px)) : d.progress) : hexRgba(d.text, .3);
      ctx.beginPath(); ctx.arc(x, h / 2, played ? 1.6 : 1.1, 0, 7); ctx.fill();
    }
    ctx.fillStyle = d.control; ctx.beginPath(); ctx.arc(Math.max(3, Math.min(w - 3, px)), h / 2, 3.2, 0, 7); ctx.fill();
  }
}

let lastT = performance.now();
function frame(now) {
  const dt = Math.min(.1, (now - lastT) / 1000); lastT = now;
  const t = now / 1000;
  colorTime = t;
  if (P.playing && stageStatus !== 'idle' && stageStatus !== 'paused') {
    P.pos += dt;
    if (P.pos >= TRACKS[P.track].len) { P.pos = 0; if (!P.repeat) P.track = (P.track + 1) % TRACKS.length; renderPlayers(); }
  }
  registry = registry.filter(e => e.el.isConnected);
  for (const e of registry) {
    const s = e.getS(), fps = s.batterySaver ? Math.min(20, s.framerate) : s.framerate;
    if (now - (e.last || 0) < 1000 / fps - 3) continue;
    e.last = now;
    if (e.kind === 'wave') drawWave(e, t);
    else if (e.kind === 'orbit') drawOrbit(e, t);
    else if (e.el.offsetParent) drawSeek(e, t);
  }
  const tr = TRACKS[P.track], prog = String(P.pos / tr.len), txt = fmtTime(P.pos), rem = '-' + fmtTime(tr.len - P.pos), ly = lyricAt(tr);
  const bass = P.playing && stageStatus !== 'idle' ? bands(t).bass : 0;
  $$('.w').forEach(el => {
    el.style.setProperty('--p', prog);
    if (!el._studioState) return;
    const state = el._studioState();
    if (state.controlsColorSource !== 'visualizer' && state.progressColorSource !== 'visualizer') return;
    const d = derive(state, el._studioStatus());
    // Keep markup and playback controls intact while updating animated colours.
    for (const declaration of colorVars(d).split(';')) {
      const colon = declaration.indexOf(':');
      if (colon !== -1) el.style.setProperty(declaration.slice(0, colon), declaration.slice(colon + 1));
    }
  });
  $$('.w.bass').forEach(el => el.style.setProperty('--bass', bass.toFixed(3)));
  $$('.w [data-el]').forEach(el => { if (el.textContent !== txt) el.textContent = txt; });
  $$('.w [data-rem]').forEach(el => { if (el.textContent !== rem) el.textContent = rem; });
  $$('.w [data-ly]').forEach(el => { if (el.textContent !== ly) el.textContent = ly; });
  const lyi = lyricIndexAt(tr);
  $$('.w .lyr-line').forEach(el => {
    const i = +el.dataset.i;
    el.classList.toggle('now', i === lyi);
    el.classList.toggle('past', i < lyi);
    el.classList.toggle('future', i > lyi);
  });
  requestAnimationFrame(frame);
}

/* ─── main stage ───────────────────────────────────────────────── */
let S = load() || structuredClone(DEFAULTS);
const env = 'kde';
let stageStatus = 'normal', zoom = 'fit', backdrop = 'dusk', popupOpen = true, activePreset = null, activeTab = 'presets', query = '', presetFilter = 'all';
function load() {
  try { const o = JSON.parse(localStorage.getItem('pav-lab4')); if (o && typeof o === "object" && !Array.isArray(o)) return PresetCodec.browser({ ...DEFAULTS, ...o }); } catch (e) { }
  return null;
}
function save() { try { localStorage.setItem('pav-lab4', JSON.stringify(S)); } catch (e) { } }

function renderMain() {
  const scaled = $('#mainWidget');
  const isP = isPill(S);
  let html, W, H;
  if (isP) {
    const pW = Math.max(520, sizeOf(S)[0] + 330);
    const pop = popupOpen && S.pillClick === 'popup' ? widgetHTML(popupState(S), stageStatus, { noHover: true, hcAbove: true }) : '';
    const pm = panelHTML(widgetHTML(S, stageStatus), env, pop, pW);
    html = pm.html; W = pW; H = pm.mh;
  } else {
    html = widgetHTML(S, stageStatus);
    [W, H] = sizeOf(S);
  }
  scaled._size = [W, H];
  mount(scaled, html, { key: 'main', getS: () => S, getStatus: () => stageStatus, scale: () => Number(scaled.dataset.scale || 1) });
  fitStage();
  const d = derive(S, 'demo');
  $('#panel').setAttribute('style', colorVars(d) + '--cover:' + d.t.cover + ';--p1:' + d.t.pal.p1 + ';--p2:' + d.t.pal.p2 + ';--p3:' + d.t.pal.p3 + ';--ts:11px;--p:.58');
  $('#panel').classList.toggle('dir-down', S.vizDirection === 'down');
  $('#lgMap').setAttribute('scale', (S.glassRefraction * 80).toFixed(0));
  const info = `${W} × ${H} px · ${isP ? (env === 'kde' ? 'Plasma panel mock' : 'Hyprland bar mock') : S.layoutMode}`;
  $('#sizeInfo').textContent = info;
  $('#hint').hidden = !isP || S.pillClick !== 'popup';
  if (!isP) $('#hint').textContent = '';
  else $('#hint').innerHTML = `Clicking the pill <b>toggles the popup card</b> · <a href="#" data-poptoggle>${popupOpen ? 'Hide popup' : 'Show popup'}</a>`;
}

function stagePlacement(stageWidth, stageHeight, width, height, topInset, bottomInset, requestedScale, above = 0) {
  const availableWidth = Math.max(1, stageWidth - 40);
  const availableHeight = Math.max(1, stageHeight - topInset - bottomInset);
  const scale = Math.max(.01, Math.min(requestedScale, availableWidth / width, availableHeight / (height + above)));
  return {
    scale,
    left: (stageWidth - width * scale) / 2,
    top: topInset + (availableHeight - (height + above) * scale) / 2 + above * scale
  };
}
function fitStage() {
  const scaled = $('#mainWidget'); if (!scaled || !scaled._size) return;
  const [W, H] = scaled._size;
  const stage = $('#stage'), scaler = $('#scaler');
  if (!stage.clientWidth || !stage.clientHeight) return;
  const topInset = ($('.bar.top', stage)?.offsetHeight || 32) + 24;
  const bottomInset = ($('.bar.bottom', stage)?.offsetHeight || 32) + 24;
  const above = isPill(S) && popupOpen && S.pillClick === 'popup' ? sizeOf(popupState(S))[1] + 12 : 0;
  const placement = stagePlacement(stage.clientWidth, stage.clientHeight, W, H, topInset, bottomInset, zoom === '2' ? 2 : 1, above);
  const sc = placement.scale;
  scaled.dataset.scale = sc;
  scaler.style.width = W * sc + 'px'; scaler.style.height = H * sc + 'px';
  scaler.style.left = placement.left + 'px'; scaler.style.top = placement.top + 'px';
  scaled.style.cssText = `width:${W}px;height:${H}px;transform:scale(${sc});transform-origin:0 0`;
}
window.addEventListener('resize', () => { fitStage(); fitPresets(); fitHero(); });
new ResizeObserver(() => fitStage()).observe($('#stage'));

/* ─── stage event bindings ─────────────────────────────────────── */
$('#statusSel').onchange = e => { stageStatus = e.target.value; P.playing = !['paused', 'idle'].includes(stageStatus); renderPlayers(); };
$$('#zoomPicker button').forEach(b => b.onclick = () => {
  zoom = b.dataset.z; $$('#zoomPicker button').forEach(x => x.setAttribute('aria-pressed', x === b)); fitStage();
});
$('#bdPicker').innerHTML = '<span class="lbl">Wallpaper</span>' + StudioCatalog.wallpapers.map(w => `<button class="bdsw" data-bd="${w.id}" title="${esc(w.label)}" aria-label="${esc(w.label)} wallpaper" aria-pressed="${w.id === backdrop}"><span class="bd bd-${w.id}" aria-hidden="true"></span></button>`).join('');
$('#bdPicker').addEventListener('click', e => {
  const b = e.target.closest('[data-bd]'); if (!b) return;
  backdrop = b.dataset.bd;
  $('#stageBd').className = `bd bd-${backdrop}`;
  $$('#bdPicker [data-bd]').forEach(x => x.setAttribute('aria-pressed', x === b));
});


$('#accentPicker').innerHTML = '<span class="lbl">Accent</span>' + SWATCHES.map(c => `<button class="sw" data-acc="${c}" style="background:${c}" aria-label="${c}"></button>`).join('');
$('#accentPicker').addEventListener('click', e => {
  const b = e.target.closest('[data-acc]'); if (!b) return;
  update({ customColor: b.dataset.acc, useSystemAccent: false, accentFromArt: false });
});

document.addEventListener('click', e => {
  const act = e.target.closest('[data-act]');
  if (act) {
    const a = act.dataset.act;
    if (a === 'play') {
      P.playing = !P.playing;
      if (stageStatus === 'paused' && P.playing) stageStatus = 'normal';
      else if (stageStatus === 'normal' && !P.playing) stageStatus = 'paused';
      $('#statusSel').value = stageStatus;
    }
    else if (a === 'next') { P.track = (P.track + 1) % TRACKS.length; P.pos = 0; }
    else if (a === 'prev') { P.track = (P.track - 1 + TRACKS.length) % TRACKS.length; P.pos = 0; }
    else if (a === 'shuffle') P.shuffle = !P.shuffle;
    else if (a === 'repeat') P.repeat = !P.repeat;
    else if (a === 'player') { P.track = (P.track + 1) % TRACKS.length; P.pos = 0; }
    else if (a === 'pill') {
      if (S.pillClick === 'toggle') P.playing = !P.playing;
      else if (S.pillClick === 'popup') popupOpen = !popupOpen;
    } else if (a === 'art') {
      if (S.artClick === 'zoom') {
        const lb = $('#lightbox'); lb.hidden = false;
        lb.innerHTML = `<div class="lb-in"><div class="lb-art" style="background-image:${TRACKS[P.track].cover}"></div><button class="ghost" data-lbclose>Close</button></div>`;
      }
    }
    renderPlayers();
  }
  if (e.target.closest('[data-poptoggle]')) { e.preventDefault(); popupOpen = !popupOpen; renderMain(); }
  if (e.target.closest('[data-lbclose]')) $('#lightbox').hidden = true;
});

document.addEventListener('pointerdown', e => {
  const pb = e.target.closest('.pb[data-act="seek"]');
  if (!pb) return;
  const r = pb.getBoundingClientRect();
  const setP = ev => {
    const p = Math.max(0, Math.min(1, (ev.clientX - r.left) / r.width));
    P.pos = p * TRACKS[P.track].len;
    $$('.w').forEach(el => el.style.setProperty('--p', String(p)));
    $$('.w [data-el]').forEach(el => el.textContent = fmtTime(P.pos));
  };
  setP(e);
  const move = ev => setP(ev);
  const up = () => { window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
  window.addEventListener('pointermove', move); window.addEventListener('pointerup', up);
});

document.addEventListener('wheel', e => {
  const w = e.target.closest('.w'); if (!w || !S.scrollVolume) return;
  e.preventDefault();
  P.volume = Math.max(0, Math.min(1, P.volume + (e.deltaY < 0 ? .05 : -.05)));
  $$('.w [data-vol] i').forEach(el => el.style.setProperty('--v', String(P.volume)));
}, { passive: false });

document.addEventListener('pointermove', e => {
  const w = e.target.closest('.w.specular'); if (!w) return;
  const r = w.getBoundingClientRect();
  w.style.setProperty('--mx', ((e.clientX - r.left) / r.width * 100).toFixed(1) + '%');
  w.style.setProperty('--my', ((e.clientY - r.top) / r.height * 100).toFixed(1) + '%');
});

/* ─── presets ──────────────────────────────────────────────────── */
const FILTERS = Schema.FILTERS;
$('#filters').innerHTML = FILTERS.map(([k, l]) => `<button data-f="${k}" aria-pressed="${k === presetFilter}">${l}</button>`).join('');
$('#filters').addEventListener('click', e => {
  const b = e.target.closest('[data-f]'); if (!b) return;
  presetFilter = b.dataset.f; $$('[data-f]').forEach(x => x.setAttribute('aria-pressed', x === b)); renderPresets();
});
const presetState = p => ({ ...DEFAULTS, ...p.s });
function presetScene(p, ps, status) {
  if (!isPill(ps)) { const [W, H] = sizeOf(ps); return { html: widgetHTML(ps, status, { noHover: true }), W, H }; }
  const W = Math.max(520, sizeOf(ps)[0] + 330), pm = panelHTML(widgetHTML(ps, status, { noHover: true }), p.env || 'kde', '', W);
  return { html: pm.html, W, H: pm.mh };
}
function renderPresets() {
  const list = PRESETS.filter(p => presetFilter === 'all' || p.cat.includes(presetFilter));
  $('#presets').innerHTML = list.map(p => `<article class="pcard ${activePreset === p.id ? 'active' : ''}" data-preset="${p.id}">
    <div class="pv" title="Apply ${p.name}"><span class="bd bd-${p.bd}"></span><div class="fit"><div class="fi"></div></div></div>
    <div class="meta"><div><h3>${p.name}</h3><p>${p.note}</p><div class="tags">${(p.tags || []).map(([t, k]) => `<span class="new ${k || ''}">${k === 'exist' || k === 'hypr' ? t : 'New · ' + t}</span>`).join('')}</div></div><button class="use">${activePreset === p.id ? 'Applied' : 'Use'}</button></div></article>`).join('');
  $$('.pcard').forEach(card => {
    const p = PRESETS.find(x => x.id === card.dataset.preset), ps = presetState(p);
    const fi = $('.fi', card);
    const getStatus = () => (stageStatus === 'paused' ? 'paused' : 'normal');
    const sc = presetScene(p, ps, getStatus());
    card._size = [sc.W, sc.H];
    mount(fi, sc.html, { key: 'preset-' + p.id, getS: () => ps, getStatus, scale: () => Number(fi.dataset.scale || 1) });
  });
  fitPresets();
}
function fitPresets() {
  $$('.pcard').forEach(card => {
    const [W, H] = card._size || [360, 104];
    const pv = $('.pv', card), fi = $('.fi', card), fit = $('.fit', card);
    if (!pv.clientWidth || !pv.clientHeight) return;
    const sc = Math.max(.01, Math.min(1.25, (pv.clientWidth - 32) / W, (pv.clientHeight - 28) / H));
    fi.dataset.scale = sc;
    fit.style.width = W * sc + 'px'; fit.style.height = H * sc + 'px';
    fi.style.cssText = `width:${W}px;height:${H}px;transform:scale(${sc});transform-origin:0 0`;
  });
}
function renderHero() {
  const p = PRESETS.find(x => x.id === 'liquid'), ps = presetState(p);
  const getStatus = () => (stageStatus === 'paused' ? 'paused' : 'normal');
  const sc = presetScene(p, ps, getStatus());
  const fi = $('#heroFi');
  fi._size = [sc.W, sc.H];
  mount(fi, sc.html, { key: 'hero', getS: () => ps, getStatus, scale: () => Number(fi.dataset.scale || 1) });
  fitHero();
}
function fitHero() {
  const fi = $('#heroFi'); if (!fi || !fi._size) return;
  const [W, H] = fi._size, fit = $('#heroFit'), card = fi.closest('.hero-card');
  if (!card || !card.clientWidth || !card.clientHeight) return;
  const sc = Math.max(.01, Math.min(1.35, (card.clientWidth - 40) / W, (card.clientHeight - 40) / H));
  fi.dataset.scale = sc;
  fit.style.width = W * sc + 'px'; fit.style.height = H * sc + 'px';
  fi.style.cssText = `width:${W}px;height:${H}px;transform:scale(${sc});transform-origin:0 0`;
}
$('#presets').addEventListener('click', e => {
  if (e.target.closest('.w [data-act]')) return;
  const card = e.target.closest('[data-preset]'); if (!card || !(e.target.closest('.use') || e.target.closest('.pv'))) return;
  applyPreset(PRESETS.find(x => x.id === card.dataset.preset));
  showPage('studio');
});

/* ─── presets in settings studio ───────────────────────────────── */
let keepColors = false, pickFilter = 'all', playerRev = 0, presetDirty = false;

function applyPreset(p) {
  const next = { ...DEFAULTS, ...p.s, autoDailyLook: S.autoDailyLook, dailyLookApplied: S.dailyLookApplied };
  if (keepColors) for (const k of COLOR_KEYS) next[k] = S[k];
  for (const k of Object.keys(HYPR)) next[k] = S[k];
  next.hAnchor = S.hAnchor;
  S = next; activePreset = p.id; presetDirty = false;
  popupOpen = true;
  onChange(); renderPresets();
  toast(`Applied “${p.name}”${keepColors ? ' · kept your colours' : ''}`);
}

function presetTile(p, ps, extra) {
  const sc = presetScene(p, ps, 'normal');
  const k = Math.min(1, 138 / sc.W, 58 / sc.H);
  return {
    sc, k,
    html: `<div class="pp" role="button" tabindex="0" data-pid="${p.id}"><div class="ppv"><span class="bd bd-${p.bd || 'breeze'}"></span><div class="fit" style="width:${sc.W * k}px;height:${sc.H * k}px"><div class="fi" style="width:${sc.W}px;height:${sc.H}px;transform:scale(${k});transform-origin:0 0"></div></div></div><div class="tl"><span>${esc(p.name)}</span>${extra || ''}</div></div>`,
  };
}
function fillGrid(grid, list, keyPrefix, extraFn) {
  const tiles = list.map(p => { const ps = presetState(p); return { p, ps, t: presetTile(p, ps, extraFn ? extraFn(p) : '') }; });
  grid.innerHTML = tiles.map(o => o.t.html).join('') || '<div class="rd" style="padding:6px 2px">Nothing saved yet — tune a look, name it below and save.</div>';
  const getStatus = () => (stageStatus === 'paused' ? 'paused' : 'normal');
  tiles.forEach((o, i) => mount($('.fi', grid.children[i]), o.t.sc.html, { key: keyPrefix + o.p.id, getS: () => o.ps, getStatus, scale: () => o.t.k }));
}
function activateOnKey(grid, find) {
  grid.addEventListener('keydown', e => {
    if (e.target.closest('button') || (e.key !== 'Enter' && e.key !== ' ')) return;
    const t = e.target.closest('[data-pid]'); if (!t) return;
    e.preventDefault(); applyPreset(find(t.dataset.pid));
  });
}

function dailyPreset() {
  const p = Schema.dailyLook(Schema.localDay());
  return {...p, s: PresetCodec.browser(p.s)};
}
function savedPresets() { return loadUser().map(p => ({...p, bd: 'breeze', cat: ['mine']})); }
function favoriteIds() { try { return Schema.favoriteIds(localStorage.getItem('pav-favorites')); } catch (_) { return []; } }
function favoriteButton(p) {
  const on = favoriteIds().includes(p.id);
  return `<button class="favorite" data-favorite="${esc(p.id)}" aria-label="${on ? 'Remove from' : 'Add to'} favourites" aria-pressed="${on}">${on ? '★' : '☆'}</button>`;
}
function saveDaily() {
  const p = dailyPreset(), all = loadUser();
  if (!all.some(u => u.id === p.id)) { all.push({id:p.id, name:p.name, s:p.s}); saveUser(all); }
}
function toggleFavorite(id) {
  if (id === dailyPreset().id) saveDaily();
  const ids = favoriteIds();
  try { localStorage.setItem('pav-favorites', JSON.stringify(ids.includes(id) ? ids.filter(x => x !== id) : [...ids, id])); }
  catch (error) { toast('Could not save favourites in this browser'); }
  syncSettings();
}
const projectCounts = {};
function renderProjectInfo(el) {
  el.innerHTML = `<div class="project-info">
    <div class="project-heading"><img src="assets/studio/icon.png" alt="Plasma Audio Visualizer project icon"><h3>${ProjectInfo.name}</h3></div>
    <div class="project-author"><span class="profile-image"><span aria-hidden="true">M</span><img alt="Muddyblack’s profile picture" hidden></span><div><a href="${ProjectInfo.profile}" target="_blank" rel="noopener">Created by ${ProjectInfo.author} ↗</a></div></div>
    <p>An open-source music visualizer for Plasma and Hyprland. Explore the project, get updates, or help improve it.</p>
    <div class="project-links">${ProjectInfo.links.map(([label, url]) => `<a class="ghost-link" href="${url}" target="_blank" rel="noopener">${label} ↗</a>`).join('')}</div>
    <div class="project-stats">${ProjectInfo.statistics.map(stat => `<div data-project-stat="${stat.id}" hidden><b></b><span>${stat.label}</span></div>`).join('')}</div>
    <p>Enjoying the visualizer? A star on GitHub helps others discover it. Thank you for supporting the project.</p>
    <a class="ghost-link star-link" href="${ProjectInfo.repository}" target="_blank" rel="noopener">☆ Star on GitHub ↗</a>
    <p>Have a design idea? Open an issue — I might add it. A sketch, mockup, or annotated screenshot helps explain what you have in mind.</p>
    <a class="ghost-link" href="${ProjectInfo.repository}/issues/new" target="_blank" rel="noopener">Suggest a design ↗</a></div>`;
  const avatar = $('.profile-image img', el);
  avatar.onload = () => { avatar.hidden = false; };
  avatar.onerror = () => { avatar.hidden = true; };
  return () => {
    if (activeTab !== 'about' && !query) return;
    if (!avatar.hasAttribute('src')) avatar.src = ProjectInfo.avatar;
    for (const stat of ProjectInfo.statistics) {
      const item = $(`[data-project-stat="${stat.id}"]`, el), value = projectCounts[stat.id];
      item.hidden = !value;
      $('b', item).textContent = value || '';
    }
  };
}

function renderPresetPicker(el) {
  el.innerHTML = `<div class="pp-top"><select class="sel" data-preset-category aria-label="Preset category">${FILTERS.map(([k, l]) => `<option value="${k}">${k === 'all' ? 'All categories' : l}</option>`).join('')}</select><label class="keep"><input type="checkbox" class="switch" data-keep>Keep my colours</label></div>
    <p class="rd" data-daily-note hidden></p><div class="pp-grid"></div>
    <button class="ghost" data-save-daily hidden>Save today’s look</button>
    <label class="keep daily-auto" data-auto-row hidden><input type="checkbox" class="switch" data-auto-daily>Apply today’s look automatically</label>
    <p class="rd" data-auto-note hidden>Once per day when opened or left running. Manual changes stay until tomorrow. In this web studio, this affects only this browser.</p>`;
  const grid = $('.pp-grid', el);
  let builtFor = '';
  const list = () => pickFilter === 'daily' ? [dailyPreset()] : pickFilter === 'favorites'
    ? [...PRESETS, ...savedPresets()].filter(p => favoriteIds().includes(p.id))
    : PRESETS.filter(p => pickFilter === 'all' || p.cat.includes(pickFilter));
  const find = id => list().find(p => p.id === id);
  $('[data-preset-category]', el).onchange = e => { pickFilter = e.target.value; syncSettings(); };
  $('[data-keep]', el).onchange = e => { keepColors = e.target.checked; };
  $('[data-save-daily]', el).onclick = () => { saveDaily(); syncSettings(); toast('Saved to My presets'); };
  $('[data-auto-daily]', el).onchange = e => { S.autoDailyLook = e.target.checked; save(); checkDailyLook(); syncSettings(); };
  grid.addEventListener('click', e => {
    const star = e.target.closest('[data-favorite]');
    if (star) { toggleFavorite(star.dataset.favorite); return; }
    const t = e.target.closest('[data-pid]'); if (t) applyPreset(find(t.dataset.pid));
  });
  activateOnKey(grid, find);
  return () => {
    const want = pickFilter + ':' + playerRev + ':' + Schema.localDay() + ':' + JSON.stringify(favoriteIds()) + ':' + JSON.stringify(loadUser());
    if (builtFor !== want) {
      builtFor = want;
      fillGrid(grid, list(), 'pick-', favoriteButton);
      if (!list().length) grid.innerHTML = '<p class="rd">Star a built-in or saved look to find it here.</p>';
    }
    $('[data-preset-category]', el).hidden = ['daily', 'favorites'].includes(pickFilter);
    $('[data-preset-category]', el).value = pickFilter;
    $('[data-keep]', el).checked = keepColors;
    $('[data-daily-note]', el).hidden = pickFilter !== 'daily';
    $('[data-daily-note]', el).textContent = dailyPreset().note + '. One look all day. Save it to keep it.';
    $('[data-save-daily]', el).hidden = pickFilter !== 'daily';
    $('[data-save-daily]', el).disabled = loadUser().some(p => p.id === dailyPreset().id);
    $('[data-auto-row]', el).hidden = pickFilter !== 'daily';
    $('[data-auto-note]', el).hidden = pickFilter !== 'daily';
    $('[data-auto-daily]', el).checked = !!S.autoDailyLook;
    $$('[data-pf]', el).forEach(b => b.setAttribute('aria-pressed', b.dataset.pf === pickFilter));
    $$('[data-pid]', grid).forEach(t => t.setAttribute('aria-pressed', t.dataset.pid === activePreset && !presetDirty));
  };
}

const loadUser = () => { try { return JSON.parse(localStorage.getItem('pav-user-presets')) || []; } catch (e) { return []; } };
const saveUser = list => { try { localStorage.setItem('pav-user-presets', JSON.stringify(list)); } catch (e) { } };
const diffOf = st => PresetCodec.browser(PresetCodec.decode(PresetCodec.encode('Saved look', st, LOOK_DEFAULTS, true), LOOK_DEFAULTS, false).settings);

function renderUserPresets(el) {
  el.innerHTML = `<div class="pp-top"><label class="keep"><input type="checkbox" class="switch" data-keep>Keep my colours</label></div><div class="pp-grid"></div>
    <div class="saverow"><input placeholder="Name this look…" maxlength="32" aria-label="Preset name"><button class="primary" data-save>Save current</button></div>
    <div class="saverow"><button class="ghost" data-export>Copy current as JSON</button><button class="ghost" data-import>Import JSON…</button></div>
    <p class="rd share-help">To share a saved look, select it, then Copy current as JSON. Others can use Import JSON. Custom QML files are not included. To suggest a built-in preset for everyone, contribute the JSON and a screenshot in a pull request. <a href="${Schema.SHARE_URL}" target="_blank" rel="noopener">How to contribute ↗</a></p>`;
  const grid = $('.pp-grid', el), name = $('.saverow input', el);
  $('[data-keep]', el).onchange = e => { keepColors = e.target.checked; };
  let builtFor = '';
  const list = () => loadUser().map(u => ({ ...u, bd: 'breeze', cat: ['mine'] }));
  const find = id => list().find(u => u.id === id);
  $('[data-save]', el).onclick = () => {
    const all = loadUser(), n = name.value.trim() || `My look ${all.length + 1}`;
    all.push({ id: 'u' + Date.now().toString(36), name: n, s: diffOf(S) });
    saveUser(all);
    name.value = ''; activePreset = all[all.length - 1].id; presetDirty = false;
    syncSettings(); toast(`Saved “${n}”`);
  };
  name.onkeydown = e => { if (e.key === 'Enter') $('[data-save]', el).click(); };
  $('[data-export]', el).onclick = async () => {
    const txt = PresetCodec.encode(name.value.trim() || 'Shared look', S, LOOK_DEFAULTS, true);
    try { await navigator.clipboard.writeText(txt); toast('Look copied as JSON'); } catch (e) { prompt('Copy this JSON', txt); }
  };
  $('[data-import]', el).onclick = () => {
    const txt = prompt('Paste a look (JSON)'); if (!txt) return;
    try {
      const o = PresetCodec.decode(txt, LOOK_DEFAULTS, true), all = loadUser();
      const u = { id: 'u' + Date.now().toString(36), name: o.name || 'Imported look', s: o.settings };
      all.push(u); saveUser(all); applyPreset(u);
    } catch (e) { toast(e.message || 'That is not a valid look'); }
  };
  grid.addEventListener('click', e => {
    const star = e.target.closest('[data-favorite]');
    if (star) { toggleFavorite(star.dataset.favorite); return; }
    const del = e.target.closest('[data-del]');
    if (del) { e.stopPropagation(); saveUser(loadUser().filter(u => u.id !== del.dataset.del)); syncSettings(); return; }
    const t = e.target.closest('[data-pid]'); if (t) applyPreset(find(t.dataset.pid));
  });
  activateOnKey(grid, find);
  return () => {
    $('[data-keep]', el).checked = keepColors;
    const L = list(), want = JSON.stringify(L) + ':' + playerRev + ':' + JSON.stringify(favoriteIds());
    if (builtFor !== want) { builtFor = want; fillGrid(grid, L, 'mine-', u => `${favoriteButton(u)}<button class="del" data-del="${u.id}" aria-label="Delete ${esc(u.name)}">×</button>`); }
    $$('[data-pid]', grid).forEach(t => t.setAttribute('aria-pressed', t.dataset.pid === activePreset && !presetDirty));
  };
}

/* ─── studio diagrams & sections ───────────────────────────────── */
function renderDiagSVG(k) {
  const shapes = (typeof Diagrams !== 'undefined' && Diagrams.shapes[k]) || [];
  return shapes.map(s => `<${s.tag} class="${s.cls || ''}" ${Object.entries(s).filter(([attr]) => attr !== 'tag' && attr !== 'cls').map(([attr, val]) => `${attr}="${val}"`).join(' ')}/>`).join('');
}
const diag = k => `<svg class="diag" viewBox="0 0 64 36" aria-hidden="true">${renderDiagSVG(k)}</svg>`;
const TABS = Schema.MAIN_TABS.filter(tab => !tab.nativeOnly).map(tab => ({ ...tab, ic: `<path d="${tab.icon}"/>` }));

function platformNote(topic) {
  const kde = env === 'kde';
  const who = kde ? 'On Plasma' : 'On Hyprland';
  let body;
  if (topic === 'card') {
    const m = S.showBg ? S.surfaceStyle : 'none';
    body = m === 'art' ? `${who}: album cover backdrop is <b>fully supported</b> with live blur &amp; dimming.`
      : m === 'glass' ? `${who}: acrylic blur works on desktop surfaces.`
      : m === 'liquid' ? `${who}: liquid refraction active with specular hover highlights.`
      : `${who}: styled cards render smoothly across both frontends.`;
  } else if (topic === 'pill') {
    body = `${who}: pills live in panels and taskbars, offering lightweight playback status.`;
  } else if (topic === 'place') {
    body = 'Configure window layer and screen anchor offsets.';
  } else if (topic === 'lyrics') {
    body = '<b>Sample verses</b> — LRCLIB synced lyrics are available in full lyrics layout.';
  } else {
    body = `${who}: custom settings active.`;
  }
  return `<div class="note"><i>◇</i><div>${body}</div></div>`;
}

function renderAnchor(el) {
  const spots = [];
  for (const v of [.08, .5, .92]) for (const h of ['left', 'center', 'right']) spots.push([h, v]);
  el.innerHTML = `<div class="monitor"><div class="anch">${spots.map(([h, v], i) => `<button data-i="${i}" aria-label="${h} ${v}"><span></span></button>`).join('')}</div></div>`;
  const btns = $$('button', el);
  btns.forEach(b => b.onclick = () => { const [h, v] = spots[b.dataset.i]; update({ hAnchor: h, verticalPosition: v }); });
  return s => btns.forEach(b => { const [h, v] = spots[b.dataset.i]; b.setAttribute('aria-pressed', s.hAnchor === h && Math.abs(s.verticalPosition - v) < .21); });
}

/* ─── settings builder from Schema.SECTIONS ────────────────────── */
let rows = [];
function buildRow(r) {
  const el = document.createElement('div');
  el.className = 'row' + (r.full ? ' full' : '');
  const options = r.opts === 'audioSources' ? [['auto', 'Default output monitor (desktop app lists live sources)']] : r.opts === 'screens' ? [['', 'First available display'], ['all', 'Every monitor']] : (r.opts || []);
  const optLabels = options.map(o => Array.isArray(o) ? o[1] : (o.label || ''));
  el.dataset.search = `${r.label || ''} ${r.desc || ''} ${r.k || ''} ${optLabels.join(' ')}`.toLowerCase();
  const get = state => Schema.rowValue(r, nativeState(state));
  const set = value => PresetCodec.browser(Schema.rowPatch(r, value, nativeState(S)));
  const isNew = r.isNew || (r.k && SCHEMA_ENTRIES[r.k] && !['visualizerType', 'progressBarStyle', 'numBars', 'sensitivity', 'framerate', 'noiseReduction', 'inputMethod', 'showMpris', 'alwaysVisible', 'useSystemAccent', 'customColor', 'lineWidth', 'fillWave', 'showBg', 'bgColor', 'bgRadius', 'glowWave', 'useSystemText', 'customTextColor', 'useSystemControls', 'customControlColor', 'useSystemDockBg', 'customDockBgColor', 'artBg', 'artBgDim', 'artBgBlur', 'artBgTransparency', 'showArtThumb', 'artBgKeepThumb'].includes(r.k));
  const isHypr = r.isHypr || (r.k && HYPR.hasOwnProperty(r.k));
  const badges = `${isNew ? '<span class="new">New</span>' : ''}${isHypr ? '<span class="new hypr">Hyprland</span>' : ''}`;
  const head = r.label ? `<div class="rh"><div class="rt">${r.label}${badges}</div>${r.desc ? `<div class="rd">${r.desc}</div>` : ''}</div>` : '';
  let sync = () => { };

  const fmt = value => Schema.format(r.fmt, value);

  if (r.type === 'switch') {
    el.innerHTML = head + `<div class="rc"><input type="checkbox" class="switch" aria-label="${r.label}"></div>`;
    const inp = $('input', el);
    inp.onchange = () => update(set(inp.checked));
    sync = s => { inp.checked = !!get(s); };
  } else if (r.type === 'range') {
    el.innerHTML = head + `<div class="rc range"><input type="range" min="${r.min}" max="${r.max}" step="${r.step}" aria-label="${r.label}"><output></output></div>`;
    const inp = $('input', el), out = $('output', el);
    inp.oninput = () => update(set(Number(inp.value)));
    sync = s => { const v = get(s); if (document.activeElement !== inp) inp.value = v; out.textContent = fmt ? fmt(v) : v; inp.style.setProperty('--f', (v - r.min) / (r.max - r.min) * 100 + '%'); };
  } else if (r.type === 'seg') {
    el.innerHTML = head + `<div class="rc"><div class="seg" role="group" aria-label="${r.label}">${r.opts.map(([v, l, n], i) => `<button data-i="${i}">${l}${n ? '<span class="new">New</span>' : ''}</button>`).join('')}</div></div>`;
    const btns = $$('button', el);
    btns.forEach(b => b.onclick = () => update(set(r.opts[b.dataset.i][0])));
    sync = s => btns.forEach(b => b.setAttribute('aria-pressed', r.opts[b.dataset.i][0] === get(s)));
  } else if (r.type === 'chips') {
    el.innerHTML = head + `<div class="chips">${r.opts.map(([v, l]) => `<button data-v="${v}">${l}</button>`).join('')}</div>`;
    const btns = $$('button', el);
    btns.forEach(b => b.onclick = () => {
      const cur = Schema.fields(get(S)), v = b.dataset.v;
      const next = cur.includes(v) ? cur.filter(x => x !== v) : r.opts.map(o => o[0]).filter(x => cur.includes(x) || x === v);
      update(set(next.join(',')));
    });
    sync = s => { const cur = Schema.fields(get(s)); btns.forEach(b => b.setAttribute('aria-pressed', cur.includes(b.dataset.v))); };
  } else if (r.type === 'select') {
    el.innerHTML = head + `<div class="rc"><select class="sel" aria-label="${r.label}">${options.map(([v, l]) => `<option value="${v}">${l}</option>`).join('')}</select></div>`;
    const sel = $('select', el);
    sel.onchange = () => update(set(sel.value));
    sync = s => { sel.value = get(s); };
  } else if (r.type === 'color') {
    const sws = r.swatches || SWATCHES;
    el.innerHTML = head + `<div class="rc swatches">${sws.map(c => `<button class="sw" data-c="${c}" style="background:${c}" aria-label="${c}"></button>`).join('')}<label class="swc" title="Pick any colour"><input type="color" aria-label="${r.label}"></label></div>`;
    const btns = $$('.sw', el), inp = $('input', el);
    btns.forEach(b => b.onclick = () => update(set(b.dataset.c)));
    inp.oninput = () => update(set(inp.value));
    sync = s => { const v = String(get(s) || '').toLowerCase(); btns.forEach(b => b.setAttribute('aria-pressed', b.dataset.c === v)); if (document.activeElement !== inp) inp.value = v; };
  } else if (r.type === 'tiles') {
    const opts = r.opts.map((o, i) => {
      const v = typeof o === 'object' ? o.v : o[0];
      const label = typeof o === 'object' ? o.label : o[1];
      const pvKind = typeof o === 'object' ? o.pv : 'diagram';
      let pvHtml = '';
      if (pvKind === 'dock') pvHtml = `<span class="dockpv" data-v="${v}"></span>`;
      else if (pvKind === 'diagram') pvHtml = diag(v);
      else if (pvKind === 'viz') pvHtml = `<canvas data-c="wave" data-i="${v}"></canvas>`;
      else if (pvKind === 'progress') pvHtml = v === 10 ? '<div class="artwrap" style="--a:32px"><div class="art" style="--a:32px"></div><i class="rg"></i></div>' : `<div class="pbwrap">${pbHTML(v, { showTimes: true, timeFormat: 'total' }, v === 0 || v === 2, 238, .58)}</div>`;
      else if (pvKind === 'orbit') pvHtml = `<canvas data-c="orbit" data-i="${v}"></canvas>`;
      else pvHtml = o.pv || '';
      return { v, label, pvHtml, isNew: o.isNew };
    });
    el.innerHTML = head + `<div class="tiles" style="--tw:${r.tw || 112}px">${opts.map((o, i) => `<button class="tile" data-i="${i}"><span class="tpv">${o.pvHtml}</span><span class="tl">${o.label}${o.isNew ? '<span class="new">New</span>' : ''}</span></button>`).join('')}</div>`;
    const btns = $$('.tile', el);
    btns.forEach(b => b.onclick = e => { if (!e.target.closest('[data-act]')) update(set(opts[b.dataset.i].v)); });
    $$('canvas[data-c]', el).forEach(c => {
      const ti = Number(c.closest('.tile').dataset.i);
      const optV = opts[ti].v;
      if (c.dataset.c === 'wave') registry.push({ el: c, kind: 'wave', key: 'tile-viz-' + ti, viz: optV, getS: () => S, getStatus: () => 'demo' });
      else if (c.dataset.c === 'orbit') registry.push({ el: c, kind: 'orbit', key: 'tile-orbit-' + ti, orbit: ti, getS: () => S, getStatus: () => 'demo' });
      else registry.push({ el: c, kind: 'seek', key: 'tile-seek-' + ti, pbs: optV, fixedP: .58, getS: () => S, getStatus: () => 'demo' });
    });
    sync = s => {
      btns.forEach(b => b.setAttribute('aria-pressed', opts[b.dataset.i].v === get(s)));
      $$('.dockpv', el).forEach(dp => { const html = dockHTML({ ...s, dockStyle: dp.dataset.v }, true); if (dp.innerHTML !== html) dp.innerHTML = html; });
    };
  } else if (r.type === 'presets') {
    sync = renderPresetPicker(el);
  } else if (r.type === 'projectInfo') {
    sync = renderProjectInfo(el);
  } else if (r.type === 'userPresets') {
    sync = renderUserPresets(el);
  } else if (r.type === 'note') {
    el.innerHTML = '<div class="nt"></div>';
    const box = $('.nt', el);
    sync = () => { const html = r.html ? r.html() : platformNote(r.note); if (box.innerHTML !== html) box.innerHTML = html; };
  } else if (r.type === 'customStyle') {
    el.innerHTML = `<details><summary>${r.label}</summary><div class="note">${r.desc || ''} (QML desktop feature).</div></details>`;
  } else if (r.type === 'anchor') {
    sync = renderAnchor(el);
  } else if (r.type === 'diagnostics') {
    el.innerHTML = '<div class="note">Browser demo: sample audio and playback. Run diagnostics in the desktop widget to check real audio capture.</div>';
  } else if (r.type === 'custom') {
    el.innerHTML = head + '<div class="cust"></div>';
    sync = r.render($('.cust', el));
  }
  return { el, r, sync };
}

function renderSettings() {
  $('#tabs').innerHTML = TABS.map(t => `<button role="tab" data-tab="${t.id}" aria-selected="${t.id === activeTab}"><svg viewBox="0 0 24 24">${t.ic}</svg>${t.label}</button>`).join('');
  const body = $('#pbody');
  if (!$('#subtabs')) $('#tabs').insertAdjacentHTML('afterend', '<div id="subtabs" class="studio-subtabs"></div>');
  body.innerHTML = '';
  rows = [];
  for (const sec of Schema.SECTIONS) {
    const wrap = document.createElement('div');
    wrap.className = 'sec'; wrap.dataset.tab = sec.tab; wrap._sec = sec;
    wrap.innerHTML = `<h4>${sec.title}</h4><div class="card"></div>`;
    for (const r of sec.rows) { const row = buildRow(r); $('.card', wrap).appendChild(row.el); rows.push(row); }
    body.appendChild(wrap);
  }
  body.insertAdjacentHTML('beforeend', '<div class="empty-search" hidden>No settings match that search.</div>');
}

function syncSettings() {
  $$('[data-acc]').forEach(b => b.setAttribute('aria-pressed', !S.useSystemAccent && !S.accentFromArt && b.dataset.acc === S.customColor));
  const q = query.trim().toLowerCase();
  for (const row of rows) {
    const vis = row.r.when ? row.r.when(nativeState(S), env) : true;
    row.el.hidden = !vis || (q && !row.el.dataset.search.includes(q));
    row.el.classList.toggle('disabled', !!(row.r.disabled && row.r.disabled(nativeState(S), env)));
    if (!row.el.hidden) row.sync(S);
  }
  let any = false;
  $$('.sec', $('#pbody')).forEach(sec => {
    const inTab = q ? true : sec.dataset.tab === activeTab;
    const visRows = $$('.row', sec).filter(r => !r.hidden);
    sec.hidden = !inTab || !visRows.length || (sec._sec.when && !sec._sec.when(nativeState(S), env));
    $$('.row', sec).forEach(r => r.classList.remove('first'));
    if (visRows[0]) visRows[0].classList.add('first');
    if (!sec.hidden) any = true;
  });
  $('.empty-search').hidden = any;
  const group = Schema.tabGroup(activeTab);
  $$('#tabs [data-tab]').forEach(b => b.setAttribute('aria-selected', !q && b.dataset.tab === group));
  const sub = $('#subtabs');
  sub.hidden = !!q || !['presets', 'appearance'].includes(group);
  const choices = group === 'presets' ? Schema.PRESET_VIEWS : StudioCatalog.tabs.filter(t => Schema.APPEARANCE_TABS.includes(t.id)).map(t => [t.id, t.label, t.icon]);
  const selected = group === 'presets' ? activeTab === 'saved' ? 'mine' : ['daily', 'favorites'].includes(pickFilter) ? pickFilter : 'all' : activeTab;
  const signature = group + ':' + selected;
  if (sub.dataset.signature !== signature) {
    sub.dataset.signature = signature;
    sub.innerHTML = `<div class="seg">${choices.map(([id, label, icon]) => `<button data-sub="${id}" aria-pressed="${id === selected}">${icon ? `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${icon}"/></svg>` : ""}${label}</button>`).join('')}</div>`;
    sub.onclick = e => {
      const button = e.target.closest('[data-sub]'); if (!button) return;
      if (group === 'presets') { pickFilter = button.dataset.sub; activeTab = pickFilter === 'mine' ? 'saved' : 'presets'; }
      else activeTab = button.dataset.sub;
      $('#pbody').scrollTop = 0; syncSettings();
    };
    const keep = $('[data-keep]', sub);
    if (keep) keep.onchange = e => { keepColors = e.target.checked; };
  }
  if ($('[data-keep]', sub)) $('[data-keep]', sub).checked = keepColors;
}
$('#tabs').addEventListener('click', e => {
  const b = e.target.closest('[data-tab]'); if (!b) return;
  activeTab = b.dataset.tab === 'appearance' ? 'viz' : b.dataset.tab; query = ''; $('#pbody').scrollTop = 0; $('#search').value = ''; syncSettings();
});
$('#search').addEventListener('input', e => { query = e.target.value; syncSettings(); });
document.addEventListener('keydown', e => {
  if (e.key === '/' && !/INPUT|SELECT|TEXTAREA/.test(document.activeElement.tagName)) { e.preventDefault(); $('#search').focus(); }
  if (e.key === 'Escape') $('#lightbox').hidden = true;
});

/* ─── config diff ──────────────────────────────────────────────── */
function configEntries() {
  const out = [];
  const eq = (a, b) => typeof a === 'number' ? Math.abs(a - b) < 1e-6 : JSON.stringify(a) === JSON.stringify(b);
  const canonical = nativeState(S);
  for (const [k, def] of Object.entries(EXISTING)) {
    const v = canonical[k];
    if (!eq(v, def)) out.push([k, v, '']);
  }
  for (const [k, def] of Object.entries(HYPR)) if (!eq(S[k], def)) out.push([k, S[k], 'ishypr']);
  return out;
}
const fmtVal = v => typeof v === 'number' && !Number.isInteger(v) ? String(Math.round(v * 100) / 100) : String(v);
function renderConfig() {
  const list = configEntries();
  const preset = PRESETS.find(p => p.id === activePreset);
  $('#cfgTitle').innerHTML = `Changed settings <span>· ${list.length}${preset ? ` · based on ${preset.name}` : ''}</span>`;
  $('#cfg').innerHTML = list.length ? list.map(([k, v, c]) => `<span class="kv ${c}"><b>${k}</b>${esc(fmtVal(v))}</span>`).join('') : '<span class="none">Everything is at its default — this is the widget exactly as it ships today.</span>';
}
$('#copyCfg').onclick = async () => {
  const txt = '[General]\n' + configEntries().map(([k, v]) => `${k}=${fmtVal(v)}`).join('\n');
  try { await navigator.clipboard.writeText(txt); toast('Config copied'); } catch (e) { toast('Clipboard blocked — see the list above'); }
};
$('#resetAll').onclick = () => { S = structuredClone(DEFAULTS); activePreset = 'classic'; onChange(); renderPresets(); toast('Back to the shipped defaults'); };
$('#shuffle').onclick = () => {
  const pick = a => a[Math.floor(Math.random() * a.length)], coin = p => Math.random() < p;
  S = { ...DEFAULTS, autoDailyLook: S.autoDailyLook, dailyLookApplied: S.dailyLookApplied,
    layoutMode: pick(['classic', 'classic', 'mirrored', 'inline', 'hero', 'stacked', 'strip', 'pill', 'orbit', 'orbit', 'poster', 'lyrics']), vizDirection: pick(['up', 'up', 'down']), orbitStyle: pick(['bars', 'wave', 'dots', 'ribbon', 'sparks']), visualizerType: Math.floor(Math.random() * VIZ.length), progressBarStyle: Math.floor(Math.random() * PBS.length),
    showBg: coin(.8), surfaceStyle: pick(['color', 'art', 'glass', 'liquid', 'atmosphere', 'solid']), bgRadius: pick([10, 14, 18, 22, 26]),
    artShape: pick(['sharp', 'rounded', 'squircle', 'circle', 'vinyl', 'cd']), dockStyle: pick(['glass', 'bare', 'accent']),
    accentFromArt: coin(.5), vizColorMode: pick(['solid', 'gradient', 'cover', 'palette', 'rainbow']), vizPalette: pick(Object.keys(PALETTES)),
    fillWave: coin(.5), glowWave: coin(.6), cardShadow: pick(['none', 'soft', 'lifted']), edgeHighlight: coin(.5), artGlow: coin(.4),
    showSource: coin(.4), showAlbum: coin(.4), hoverDetails: pick(['off', 'tooltip', 'flip']), pillEq: pick(['static', 'live', 'wave']), pillProgress: pick(['off', 'underline', 'ring']) };
  activePreset = null; popupOpen = true; onChange(); renderPresets();
};

/* ─── gallery statistics ─── */
$('#stats').innerHTML = [[VIZ.length, 'visualizers'], [PBS.length, 'progress bars'], [Layouts.MODES.length + 1, 'layouts'], [PRESETS.length, 'presets']].map(([n, l]) => `<div class="stat-item"><b>${n}</b>${l}</div>`).join('');

// Shields uses the same download sources as the README and supports browser requests.
async function loadProjectCounts() {
  const sources = Object.fromEntries(ProjectInfo.statistics.map(stat => [stat.id, stat.url]));
  await Promise.allSettled(Object.entries(sources).map(async ([key, url]) => {
    try {
      const response = await fetch(url, {signal: AbortSignal.timeout(8000)});
      if (!response.ok) return;
      const count = ProjectInfo.count(await response.text());
      if (!count) return;
      projectCounts[key] = count;
      $$(`[data-count="${key}"]`).forEach(node => {
        node.textContent = count;
        node.setAttribute('aria-label', `${count} ${key === 'stars' ? 'stars' : 'downloads'}`);
      });
      syncSettings();
    } catch (_) { /* Keep unavailable counts hidden; links remain usable. */ }
  }));
}
loadProjectCounts();

/* ─── glue ─────────────────────────────────────────────────────── */
let toastTimer;
function toast(msg) { const t = $('#toast'); t.textContent = msg; t.classList.add('on'); clearTimeout(toastTimer); toastTimer = setTimeout(() => t.classList.remove('on'), 1800); }
function update(patch) {
  Object.assign(S, patch);
  presetDirty = true;
  if (activePreset) { $$('.pcard.active').forEach(c => c.classList.remove('active')); $$('.pcard .use').forEach(b => b.textContent = 'Use'); }
  onChange();
}
function onChange() {
  save();
  document.body.classList.toggle('rm', S.reducedMotion);
  renderMain(); syncSettings(); renderConfig();
}
function renderPlayers() { playerRev++; renderMain(); renderPresets(); renderHero(); syncSettings(); }

function checkDailyLook() {
  const next = Schema.dailyUpdate(LOOK_DEFAULTS, nativeState(S), Schema.localDay());
  if (!next) return;
  S = PresetCodec.browser(next);
  activePreset = dailyPreset().id;
  presetDirty = false;
  onChange();
}
setInterval(() => { checkDailyLook(); syncSettings(); }, 30000);
document.addEventListener('visibilitychange', () => {
  if (!document.hidden) { checkDailyLook(); syncSettings(); }
});

renderSettings();
checkDailyLook();
onChange();
renderPresets();
renderHero();
requestAnimationFrame(frame);
