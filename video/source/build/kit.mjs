// What the film builders share: colours, type, cuts, the cursor, drawn windows and the footage element.
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
export const VIDEO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const r3 = x => +(+x).toFixed(3), J = JSON.stringify;
export const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
// the app's own status colours (Frame.swift, Mood)
export const MOOD = { asleep: '#A9A4F0', idle: '#45D4E8', working: '#48D97F', done: '#FFC83D', needsYou: '#FF5F87' };
export const GROUND = '#EEF0F7', INK = '#191B24', SOFT = 'rgba(25,27,36,.6)', NIGHT = '#101119';
export const scope = css => css.replace(/(^|})\s*([^{}@]+)\{/g, (m, a, sel) => a + '\n' + sel.split(',').map(x => x.trim()).map(x => x.startsWith('#root') ? x : '#root ' + x).join(', ') + ' {');
export const take = (dir, n) => JSON.parse(fs.readFileSync(path.join(VIDEO, 'assets', dir, n, 'take.json'), 'utf8'));
export const linker = OUT => (from, to) => { const dst = path.join(OUT, 'assets', to); fs.mkdirSync(path.dirname(dst), { recursive: true }); if (fs.existsSync(dst)) fs.rmSync(dst); try { fs.linkSync(from, dst); } catch { fs.copyFileSync(from, dst); } };

export const CSS = `
@font-face { font-family: "JetBrains Mono"; src: url("assets/fonts/jetbrains-mono-var-latin.woff2") format("woff2"); font-weight: 400 700; font-display: block; }
#root { position: absolute; inset: 0; overflow: hidden; background: ${GROUND}; color: ${INK}; font-family: "Inter", sans-serif; }
#root * { box-sizing: border-box; margin: 0; padding: 0; }
.gl { position: absolute; width: 1700px; height: 1700px; margin: -850px 0 0 -850px; border-radius: 50%; z-index: 4; }
.ln { position: absolute; font-weight: 900; letter-spacing: -0.03em; line-height: 1.04; z-index: 20; }
.ln .row { display: block; white-space: nowrap; }
.kw { display: inline-block; }
.kw + .kw { margin-left: .22em; }
.pill { display: inline-block; padding: 0 .16em; margin-left: -.16em; border-radius: .16em; }
.win { position: absolute; border-radius: 22px; background: #FFFFFF; box-shadow: 0 50px 110px -40px rgba(40,44,80,.38), 0 0 0 1.5px rgba(25,27,36,.07); overflow: hidden; }
.bar { height: 62px; display: flex; align-items: center; gap: 11px; padding: 0 24px; border-bottom: 1.5px solid rgba(25,27,36,.07); font-family: "JetBrains Mono", monospace; font-weight: 500; font-size: 26px; color: ${SOFT}; }
.bar b { width: 15px; height: 15px; border-radius: 50%; background: rgba(25,27,36,.14); }
.bar span { margin-left: 14px; }
.bar em { position: relative; width: 18px; height: 18px; margin-left: auto; }
.bar em i { position: absolute; inset: 0; border-radius: 50%; }
.code { position: absolute; left: 34px; top: 96px; }
.code u { display: block; height: 17px; border-radius: 9px; margin-bottom: 21px; background: rgba(25,27,36,.11); transform-origin: 0 50%; }
.dark { background: #1B1D29; box-shadow: 0 50px 110px -40px rgba(0,0,0,.7), 0 0 0 1.5px rgba(255,255,255,.08); }
.dark .bar { border-bottom-color: rgba(255,255,255,.07); color: rgba(255,255,255,.5); }
.dark .bar b { background: rgba(255,255,255,.16); }
.dark .code u { background: rgba(255,255,255,.14); }
.warm { background: #FFF8EC; }
.warm .bar { border-bottom-color: rgba(120,80,20,.1); }
.card { position: absolute; border-radius: 18px; background: #FFFFFF; box-shadow: 0 0 0 1.5px rgba(120,80,20,.1); }
.card s { position: absolute; left: 22px; right: 22px; top: 22px; height: 46%; border-radius: 11px; }
.card u { position: absolute; left: 22px; height: 14px; border-radius: 7px; background: rgba(25,27,36,.12); }
.full { position: absolute; inset: 0; z-index: 3; background: #FFF8EC; }
.full .tool { position: absolute; left: 0; right: 0; top: 0; height: 70px; background: #F6ECD9; border-bottom: 1.5px solid rgba(120,80,20,.1); }
.vw { position: absolute; z-index: 6; }
.vw video { position: absolute; left: 0; top: 0; width: 100%; height: 100%; }
.bub { position: absolute; left: 1210px; top: 62px; width: 600px; height: 460px; z-index: 8; }
.bub img { position: absolute; left: 0; top: 0; width: 100%; height: 100%; transform-origin: 50% 87%; }
.cur { position: absolute; left: 0; top: 0; width: 124px; height: 124px; z-index: 80; filter: drop-shadow(0 6px 10px rgba(0,0,0,.3)); transform-origin: 21.7% 10.8%; }
.cur svg { width: 100%; height: 100%; display: block; }
.rip { position: absolute; left: 0; top: 0; width: 150px; height: 150px; margin: -75px 0 0 -75px; border: 7px solid ${MOOD.needsYou}; border-radius: 50%; z-index: 9; }
.disc { position: absolute; width: 400px; height: 70px; border-radius: 50%; background: radial-gradient(ellipse at center, rgba(255,255,255,.95) 0%, rgba(255,255,255,0) 70%); z-index: 2; }
.mono { font-family: "JetBrains Mono", monospace; font-weight: 600; color: ${SOFT}; white-space: nowrap; }
`;

export const CUR = id => `<div class="cur" id="${id}" data-layout-allow-occlusion data-layout-allow-overflow><svg viewBox="0 0 24 24"><path d="M5.2 2.6V19.4L9.6 15.3L12.6 21.6L15.2 20.4L12.3 14.3H18.4Z" fill="#FFFFFF" stroke="#191B24" stroke-width="1.3" stroke-linejoin="round"/></svg></div>`;
export const cp = (x, y) => ({ x: r3(x - 26.9), y: r3(y - 13.4) });   // the arrow's tip, not its box
export const curTo = (id, x, y, at, dur = 0.75, ease = 'power3.out') => `tl.to("#${id}", ${J({ ...cp(x, y), duration: dur, ease })}, ${r3(at)});\n`;
export const tap = (id, at) => `tl.to("#${id}", { scale: 0.84, duration: 0.1, ease: "power2.in" }, ${r3(at - 0.05)});\ntl.to("#${id}", { scale: 1, duration: 0.22, ease: "power2.out" }, ${r3(at + 0.05)});\n`;

/** A line of type in rows; the size fits the longest row into `width`. `pill: [row, colour]` sets one row on a colour.
 *  Returns its markup, its word count and where each row's words start. */
export function line(id, rws, { cap = 150, width = 880, cy = 540, top = null, left = 120, factor = 0.66, color = null, pill = null, weight = 900 } = {}) {
  const longest = Math.max(...rws.map(r => r.length)), fs_ = Math.min(cap, Math.floor(width / (longest * factor)));
  const h = rws.length * fs_ * 1.04, y = top ?? Math.round(cy - h / 2); let i = 0; const starts = [];
  const html = `<div class="ln" id="${id}" style="left:${left}px;top:${y}px;font-size:${fs_}px;font-weight:${weight}${color ? ';color:' + color : ''}">` + rws.map((r, ri) => { starts.push(i); const ws = r.split(' ').map(w => `<span class="kw" id="${id}-${i++}">${esc(w)}</span>`).join(''); return `<span class="row">${pill && pill[0] === ri ? `<span class="pill" id="${id}-pill" style="background:${pill[1]}">${ws}</span>` : ws}</span>`; }).join('') + '</div>';
  return { html, n: i, starts: [...starts, i], size: fs_, top: y, height: h, id, pill: pill ? id + '-pill' : null };
}
// arrival cascade from below; word-by-word cuts along the film's current (leftward), with a little blur on the fast part
export const wfIn = (id, n, at, { dy = 80, gap = 0.07, dur = 0.22, from = 0 } = {}) => { let s = '', a = at; for (let i = from; i < n; i++) { s += `gsap.set("#${id}-${i}", { opacity: 0 });\ntl.set("#${id}-${i}", { opacity: 1 }, ${r3(a)});\ntl.fromTo("#${id}-${i}", { y: ${dy} }, { y: 0, duration: ${dur}, ease: "power4.out", immediateRender: false }, ${r3(a)});\n`; a += gap * Math.pow(0.88, i - from); } return s; };
export const cutOut = (id, n, at, d = -230, from = 0) => { let s = ''; for (let i = from; i < n; i++) { const a = r3(at + (i - from) * 0.022); s += `tl.to("#${id}-${i}", { x: ${d}, filter: "blur(9px)", duration: 0.34, ease: "power4.in" }, ${a});\ntl.to("#${id}-${i}", { opacity: 0, duration: 0.18, ease: "none" }, ${a});\n`; } return s; };
export const cutIn = (id, n, at, d = 230, from = 0) => { let s = '', a = at; for (let i = from; i < n; i++) { s += `gsap.set("#${id}-${i}", { x: ${d}, opacity: 0, filter: "blur(9px)" });\ntl.set("#${id}-${i}", { opacity: 0.35 }, ${r3(a)});\ntl.to("#${id}-${i}", { x: 0, filter: "blur(0px)", duration: 0.3, ease: "power4.out" }, ${r3(a)});\ntl.to("#${id}-${i}", { opacity: 1, duration: 0.14, ease: "none" }, ${r3(a)});\n`; a += 0.05 * Math.pow(0.84, i - from); } return s; };
export const pieceIn = (sel, at, d = 230) => `gsap.set("${sel}", { x: ${d}, opacity: 0 });\ntl.set("${sel}", { opacity: 0.35 }, ${r3(at)});\ntl.to("${sel}", { x: 0, duration: 0.3, ease: "power4.out" }, ${r3(at)});\ntl.to("${sel}", { opacity: 1, duration: 0.14, ease: "none" }, ${r3(at)});\n`;
export const pieceOut = (sel, at, d = -230) => `tl.to("${sel}", { x: ${d}, duration: 0.34, ease: "power4.in" }, ${r3(at)});\ntl.to("${sel}", { opacity: 0, duration: 0.18, ease: "none" }, ${r3(at)});\n`;
export const popIn = (sel, at, from = 0.5) => `gsap.set("${sel}", { opacity: 0 });\ntl.set("${sel}", { opacity: 1 }, ${r3(at)});\ntl.fromTo("${sel}", { scale: ${from} }, { scale: 1, duration: 0.28, ease: "back.out(1.6)", immediateRender: false }, ${r3(at)});\n`;
/** the status-coloured light behind the buddy, following the footage's own record of its mood */
export function glows(id, tk, cx, cy) {
  const moods = [...new Set(tk.track.map(e => e.mood))]; let html = '', js = '';
  for (const m of moods) html += `<div class="gl" id="${id}-g-${m}" data-layout-ignore style="left:${cx}px;top:${cy}px;background:radial-gradient(circle, ${MOOD[m]}8C 0%, ${MOOD[m]}33 34%, ${MOOD[m]}00 62%)"></div>`;
  js += moods.map(m => `gsap.set("#${id}-g-${m}", { opacity: ${m === tk.track[0].mood ? 1 : 0} });\n`).join('');
  let cur = tk.track[0].mood;
  for (const e of tk.track) if (e.mood !== cur) { js += `tl.to("#${id}-g-${cur}", { opacity: 0, duration: 0.5, ease: "power2.out" }, ${r3(e.t)});\ntl.to("#${id}-g-${e.mood}", { opacity: 1, duration: 0.35, ease: "power2.out" }, ${r3(e.t)});\n`; cur = e.mood; }
  return { html, js, moods };
}
// lines of "code": plain strokes, seeded so every build draws the same ones
export const strokes = (seed, n) => { let x = seed; const rnd = () => (x = (x * 16807) % 2147483647) / 2147483647; return Array.from({ length: n }, (_, i) => ({ w: Math.round(150 + rnd() * 330), ind: [0, 0, 34, 34, 68, 34, 0][i % 7], tint: rnd() })); };
export const code = (id, seed, n, k = 1) => `<div class="code">` + strokes(seed, n).map((s, i) => `<u id="${id}-${i}" style="width:${Math.round(s.w * k)}px;margin-left:${s.ind}px${s.tint > 0.72 ? ';background:rgba(72,217,127,.55)' : s.tint < 0.16 ? ';background:rgba(69,212,232,.6)' : ''}"></u>`).join('') + '</div>';
export const win = (id, title, body, { x, y, w, h, cls = '', z = '', dot = '' }) => `<div class="win ${cls}" id="${id}" data-layout-ignore style="left:${x}px;top:${y}px;width:${w}px;height:${h}px${z !== '' ? ';z-index:' + z : ''}"><div class="bar"><b></b><b></b><b></b><span>${title}</span>${dot}</div>${body}</div>`;
export const cards = (id, step = 364, cw = 340) => [[0, 0, '#FFE0A8'], [1, 0, '#CFE9FF'], [0, 1, '#E3D8FF'], [1, 1, '#C9F2DA']].map(([c, r, col], i) => `<div class="card" id="${id}-${i}" style="left:${48 + c * step}px;top:${106 + r * 262}px;width:${cw}px;height:238px"><s style="background:${col}"></s><u style="top:67%;width:62%"></u><u style="top:80%;width:38%"></u></div>`).join('');
export const vertex = (id, dir, src, dur, x, y, w, h, start = 0, track = 1) => `<div class="vw" id="${id}w" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px" data-layout-allow-occlusion><video id="${id}" class="clip" src="assets/${dir}/${src}.webm" muted playsinline data-start="${start}" data-duration="${dur}" data-track-index="${track}" data-layout-allow-occlusion></video></div>`;
