// Vertex Buddy launch film, 16:9. Writes the HyperFrames project in source/film/ from the README and the footage.
// Run: video/source/bin/make build
//
// Every sentence on screen comes from the repository README.md word for word: say() stops the build if one does not.
// Vertex is footage recorded from the app itself (bin/make footage). Windows behind it are plain drawings, not a real app.
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';

const VIDEO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const P = 'film', OUT = path.join(VIDEO, 'source', P);
const W = 1920, H = 1080, BPM = 100, B = 60 / BPM;
const r3 = x => +(+x).toFixed(3), J = JSON.stringify;
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');

// ---- the words: only what the README says
const README = fs.readFileSync(path.resolve(VIDEO, '../README.md'), 'utf8').replace(/\*\*|`/g, '').replace(/\s+/g, ' ');
const used = [];
const say = s => { if (!README.includes(s)) throw new Error('Not in the README, word for word: "' + s + '"'); used.push(s); return s; };
const rows = (text, ...cuts) => { say(text); const out = []; let rest = text; for (const c of cuts) { if (!rest.startsWith(c)) throw new Error('row "' + c + '" does not continue "' + rest + '"'); out.push(c); rest = rest.slice(c.length).trim(); } if (rest) out.push(rest); return out; };

// ---- colours: the app's own status colours (Frame.swift, Mood)
const MOOD = { asleep: '#A9A4F0', idle: '#45D4E8', working: '#48D97F', done: '#FFC83D', needsYou: '#FF5F87' };
const GROUND = '#EEF0F7', INK = '#191B24', SOFT = 'rgba(25,27,36,.6)';
const REPO = 'github.com/mahakrishan21/vertex-buddy';

// ---- footage: each take's own record of what the engine was doing, frame by frame
const take = n => JSON.parse(fs.readFileSync(path.join(VIDEO, 'assets/footage', n, 'take.json'), 'utf8'));
const DAY = take('day'), CLOSE = take('close');

// ---- assets: hard links into the project, so the masters stay in video/assets
function asset(from, to) { const dst = path.join(OUT, 'assets', to); fs.mkdirSync(path.dirname(dst), { recursive: true }); if (fs.existsSync(dst)) fs.rmSync(dst); try { fs.linkSync(from, dst); } catch { fs.copyFileSync(from, dst); } }
const SFX = { click: ['click-soft.mp3', 0.37], whooshA: ['whoosh-short.mp3', 0.57], whooshB: ['whoosh.mp3', 0.57], pop: ['pop.mp3', 0.72] };
const sfx = []; const snd = (t, key, vol) => sfx.push({ t: r3(t), key, vol });

// ---- look
const CSS = `
@font-face { font-family: "JetBrains Mono"; src: url("assets/fonts/jetbrains-mono-var-latin.woff2") format("woff2"); font-weight: 400 700; font-display: block; }
#root { position: absolute; inset: 0; overflow: hidden; background: ${GROUND}; color: ${INK}; font-family: "Inter", sans-serif; }
#root * { box-sizing: border-box; margin: 0; padding: 0; }
.gl { position: absolute; width: 1700px; height: 1700px; margin: -850px 0 0 -850px; border-radius: 50%; z-index: 4; }
.ln { position: absolute; left: 120px; font-weight: 900; letter-spacing: -0.03em; line-height: 1.07; z-index: 20; }
.ln .row { display: block; white-space: nowrap; }
.kw { display: inline-block; }
.kw + .kw { margin-left: .24em; }
.kk { position: absolute; left: 124px; z-index: 20; display: flex; align-items: center; gap: 16px; font-family: "JetBrains Mono", monospace; font-weight: 600; font-size: 30px; letter-spacing: .14em; text-transform: uppercase; color: ${SOFT}; white-space: nowrap; }
.kk i { width: 24px; height: 24px; border-radius: 50%; box-shadow: 0 0 0 5px rgba(255,255,255,.7); }
.win { position: absolute; left: 1040px; top: 140px; width: 800px; height: 640px; border-radius: 22px; background: #FFFFFF; box-shadow: 0 50px 110px -40px rgba(40,44,80,.38), 0 0 0 1.5px rgba(25,27,36,.07); overflow: hidden; }
.bar { height: 62px; display: flex; align-items: center; gap: 11px; padding: 0 24px; border-bottom: 1.5px solid rgba(25,27,36,.07); font-family: "JetBrains Mono", monospace; font-weight: 500; font-size: 26px; color: ${SOFT}; }
.bar b { width: 15px; height: 15px; border-radius: 50%; background: rgba(25,27,36,.14); }
.bar span { margin-left: 14px; }
.bar em { position: relative; width: 18px; height: 18px; margin-left: auto; }
.bar em i { position: absolute; inset: 0; border-radius: 50%; }
.code { position: absolute; left: 34px; top: 96px; }
.code u { display: block; height: 17px; border-radius: 9px; margin-bottom: 21px; background: rgba(25,27,36,.11); transform-origin: 0 50%; }
.warm { background: #FFF8EC; }
.warm .bar { border-bottom-color: rgba(120,80,20,.1); }
.card { position: absolute; border-radius: 18px; background: #FFFFFF; box-shadow: 0 0 0 1.5px rgba(120,80,20,.1); }
.card s { position: absolute; left: 22px; right: 22px; top: 22px; height: 46%; border-radius: 11px; }
.card u { position: absolute; left: 22px; height: 14px; border-radius: 7px; background: rgba(25,27,36,.12); }
.full { position: absolute; inset: 0; z-index: 3; background: #FFF8EC; }
.full .tool { position: absolute; left: 0; right: 0; top: 0; height: 70px; background: #F6ECD9; border-bottom: 1.5px solid rgba(120,80,20,.1); }
.vw { position: absolute; z-index: 6; }
.vw video { position: absolute; left: 0; top: 0; width: 100%; height: 100%; }
.zz { position: absolute; z-index: 7; font-family: "JetBrains Mono", monospace; font-weight: 700; color: #7D77DB; }
.bub { position: absolute; left: 1210px; top: 62px; width: 600px; height: 460px; z-index: 8; }
.bub img { position: absolute; left: 0; top: 0; width: 100%; height: 100%; transform-origin: 50% 87%; }
.cur { position: absolute; left: 0; top: 0; width: 124px; height: 124px; z-index: 80; filter: drop-shadow(0 6px 10px rgba(0,0,0,.3)); transform-origin: 21.7% 10.8%; }
.cur svg { width: 100%; height: 100%; display: block; }
.rip { position: absolute; left: 0; top: 0; width: 150px; height: 150px; margin: -75px 0 0 -75px; border: 7px solid ${MOOD.needsYou}; border-radius: 50%; z-index: 9; }
.disc { position: absolute; width: 400px; height: 70px; border-radius: 50%; background: radial-gradient(ellipse at center, rgba(255,255,255,.95) 0%, rgba(255,255,255,0) 70%); z-index: 2; }
.nm { position: absolute; top: 816px; width: 520px; text-align: center; z-index: 20; font-family: "JetBrains Mono", monospace; font-weight: 600; font-size: 31px; color: ${SOFT}; white-space: nowrap; }
.bh { position: absolute; left: 0; right: 0; top: 902px; text-align: center; z-index: 20; }
.bh-k { top: 880px; left: 0; right: 0; justify-content: center; font-size: 26px; }
.bh-w { position: absolute; left: 0; right: 0; top: 918px; text-align: center; z-index: 20; font-weight: 900; font-size: 84px; letter-spacing: -0.03em; line-height: 1; }
.mark { position: absolute; left: 900px; top: 528px; z-index: 20; font-weight: 900; font-size: 132px; letter-spacing: -0.04em; line-height: 1; white-space: nowrap; }
.url { position: absolute; left: 906px; top: 690px; z-index: 20; font-family: "JetBrains Mono", monospace; font-weight: 600; font-size: 36px; color: ${SOFT}; white-space: nowrap; }
`;
const scope = css => css.replace(/(^|})\s*([^{}@]+)\{/g, (m, a, sel) => a + '\n' + sel.split(',').map(x => x.trim()).map(x => x.startsWith('#root') ? x : '#root ' + x).join(', ') + ' {');

// ---- markup helpers
const CUR = id => `<div class="cur" id="${id}" data-layout-allow-occlusion data-layout-allow-overflow><svg viewBox="0 0 24 24"><path d="M5.2 2.6V19.4L9.6 15.3L12.6 21.6L15.2 20.4L12.3 14.3H18.4Z" fill="#FFFFFF" stroke="#191B24" stroke-width="1.3" stroke-linejoin="round"/></svg></div>`;
const cp = (x, y) => ({ x: r3(x - 26.9), y: r3(y - 13.4) });   // the arrow's tip, not its box
/** a line of type in rows; the size fits the longest row into `width`. Returns its markup and word count. */
function line(id, rws, { cap = 104, width = 880, cy = 560, top = null, left = 120, kicker = null, dot = null } = {}) {
  const longest = Math.max(...rws.map(r => r.length)), fs_ = Math.min(cap, Math.floor(width / (longest * 0.52)));
  const h = rws.length * fs_ * 1.07, y = top ?? Math.round(cy - h / 2); let i = 0;
  let html = `<div class="ln" id="${id}" style="left:${left}px;top:${y}px;font-size:${fs_}px">` + rws.map(r => `<span class="row">${r.split(' ').map(w => `<span class="kw" id="${id}-${i++}">${esc(w)}</span>`).join('')}</span>`).join('') + '</div>';
  if (kicker) html += `<div class="kk" id="${id}k-0" style="left:${left + 4}px;top:${y - 64}px" data-layout-ignore><i style="background:${dot}"></i>${esc(kicker)}</div>`;
  return { html, n: i, kicker: !!kicker };
}
// arrival cascade from below, and the word-by-word cut along the film's current (leftward)
const wfIn = (id, n, at, { dy = 72, gap = 0.075, dur = 0.2 } = {}) => { let s = '', a = at; for (let i = 0; i < n; i++) { s += `gsap.set("#${id}-${i}", { opacity: 0 });\ntl.set("#${id}-${i}", { opacity: 1 }, ${r3(a)});\ntl.fromTo("#${id}-${i}", { y: ${dy} }, { y: 0, duration: ${dur}, ease: "power4.out", immediateRender: false }, ${r3(a)});\n`; a += gap * Math.pow(0.88, i); } return s; };
const cutOut = (id, n, at, d = -230) => { let s = ''; for (let i = 0; i < n; i++) { const a = r3(at + i * 0.022); s += `tl.to("#${id}-${i}", { x: ${d}, duration: 0.34, ease: "power4.in" }, ${a});\ntl.to("#${id}-${i}", { opacity: 0, duration: 0.18, ease: "none" }, ${a});\n`; } return s; };
const cutIn = (id, n, at, d = 230) => { let s = '', a = at; for (let i = 0; i < n; i++) { s += `gsap.set("#${id}-${i}", { x: ${d}, opacity: 0 });\ntl.set("#${id}-${i}", { opacity: 0.35 }, ${r3(a)});\ntl.to("#${id}-${i}", { x: 0, duration: 0.3, ease: "power4.out" }, ${r3(a)});\ntl.to("#${id}-${i}", { opacity: 1, duration: 0.14, ease: "none" }, ${r3(a)});\n`; a += 0.05 * Math.pow(0.84, i); } return s; };
const lineIn = (id, L, at, first = false) => (L.kicker ? cutIn(id + 'k', 1, at) : '') + (first ? wfIn(id, L.n, at) : cutIn(id, L.n, at));
const lineOut = (id, L, at) => (L.kicker ? cutOut(id + 'k', 1, at) : '') + cutOut(id, L.n, at);
/** a group that arrives or leaves as one piece along the current */
const pieceIn = (sel, at, d = 230) => `gsap.set("${sel}", { x: ${d}, opacity: 0 });\ntl.set("${sel}", { opacity: 0.35 }, ${r3(at)});\ntl.to("${sel}", { x: 0, duration: 0.3, ease: "power4.out" }, ${r3(at)});\ntl.to("${sel}", { opacity: 1, duration: 0.14, ease: "none" }, ${r3(at)});\n`;
const pieceOut = (sel, at, d = -230) => `tl.to("${sel}", { x: ${d}, duration: 0.34, ease: "power4.in" }, ${r3(at)});\ntl.to("${sel}", { opacity: 0, duration: 0.18, ease: "none" }, ${r3(at)});\n`;
/** the status-coloured light behind the buddy, following the footage's own record of its mood */
function glows(id, tk, cx, cy) {
  const moods = [...new Set(tk.track.map(e => e.mood))]; let html = '', js = '';
  for (const m of moods) html += `<div class="gl" id="${id}-g-${m}" data-layout-ignore style="left:${cx}px;top:${cy}px;background:radial-gradient(circle, ${MOOD[m]}8C 0%, ${MOOD[m]}33 34%, ${MOOD[m]}00 62%)"></div>`;
  js += moods.map(m => `gsap.set("#${id}-g-${m}", { opacity: ${m === tk.track[0].mood ? 1 : 0} });\n`).join('');
  let cur = tk.track[0].mood;
  for (const e of tk.track) if (e.mood !== cur) { js += `tl.to("#${id}-g-${cur}", { opacity: 0, duration: 0.5, ease: "power2.out" }, ${r3(e.t)});\ntl.to("#${id}-g-${e.mood}", { opacity: 1, duration: 0.35, ease: "power2.out" }, ${r3(e.t)});\n`; cur = e.mood; }
  return { html, js };
}
// lines of "code": grey strokes, seeded so every build draws the same ones
const strokes = (seed, n) => { let x = seed; const rnd = () => (x = (x * 16807) % 2147483647) / 2147483647; return Array.from({ length: n }, (_, i) => ({ w: Math.round(150 + rnd() * 330), ind: [0, 0, 34, 34, 68, 34, 0][i % 7], tint: rnd() }));
};
const code = (id, seed, n) => `<div class="code">` + strokes(seed, n).map((s, i) => `<u id="${id}-${i}" style="width:${s.w}px;margin-left:${s.ind}px${s.tint > 0.72 ? ';background:rgba(72,217,127,.5)' : s.tint < 0.16 ? ';background:rgba(69,212,232,.55)' : ''}"></u>`).join('') + '</div>';
const win = (id, title, body, dot = '') => `<div class="win" id="${id}" data-layout-ignore><div class="bar"><b></b><b></b><b></b><span>${title}</span>${dot}</div>${body}</div>`;
const cards = id => [[0, 0, '#FFE0A8'], [1, 0, '#CFE9FF'], [0, 1, '#E3D8FF'], [1, 1, '#C9F2DA']].map(([c, r, col], i) => `<div class="card" id="${id}-${i}" style="left:${48 + c * 364}px;top:${106 + r * 262}px;width:340px;height:238px"><s style="background:${col}"></s><u style="top:67%;width:62%"></u><u style="top:80%;width:38%"></u></div>`).join('');
const vertex = (id, src, dur, x, y, w, h) => `<div class="vw" id="${id}w" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px" data-layout-allow-occlusion><video id="${id}" class="clip" src="assets/footage/${src}.webm" muted playsinline data-start="0" data-duration="${dur}" data-track-index="1" data-layout-allow-occlusion></video></div>`;

const scenes = [];
const add = (id, beats, fn) => { const start = scenes.reduce((a, s) => a + s.beats, 0); scenes.push({ id, beats, start: r3(start * B), dur: r3(beats * B), ...fn(r3(start * B), r3(beats * B)) }); };

// ================= 1. the day: one continuous shot, asleep to "needs you" =================
add('day', 44, (T0, D) => {
  const VX = 1150, VY = 300, CX = VX + 360, CY = 690;   // the footage box, and the buddy's chest
  const L = [
    ['d1', rows('Vertex is a little 3D buddy that floats above every app on your Mac', 'Vertex is a little 3D', 'buddy that floats above'), {}, 0.35, 4.5],
    ['d2', rows('Sessions open, nothing to do', 'Sessions open,'), { kicker: say('Aqua'), dot: MOOD.idle }, 4.72, 8.12],
    ['d3', rows('Claude is working'), { kicker: say('Green'), dot: MOOD.working }, 8.32, 11.0],
    ['d4', rows('every Space, full-screen apps too', 'every Space,'), {}, 11.2, 14.12],
    ['d5', rows('A session finished: your turn', 'A session finished:'), { kicker: say('Sunny yellow'), dot: MOOD.done }, 14.32, 20.12],
    ['d6', rows('A session needs your answer', 'A session needs'), { kicker: say('Rose pink'), dot: MOOD.needsYou }, 20.32, 22.3],
    ['d7', rows('Click the buddy: jumps to the waiting session', 'Click the buddy:', 'jumps to the'), {}, 22.5, D - 0.36],
  ].map(([id, rws, o, tin, tout]) => ({ id, tin, tout, ...line(id, rws, o) }));
  const G = glows('d', DAY, CX, 640);
  let body = `<div class="win" id="d-w1" data-layout-ignore><div class="bar"><b></b><b></b><b></b><span>website</span></div>${code('d-c1', 7, 14)}</div>
<div class="win warm" id="d-w2" data-layout-ignore><div class="bar"><b></b><b></b><b></b><span>notes</span></div>${cards('d-k')}</div>
<div class="full" id="d-full" data-layout-ignore><div class="tool"></div><div style="position:absolute;left:1040px;top:140px;width:800px;height:640px">${cards('d-f')}</div></div>
${G.html}
${win('d-w3', 'api', code('d-c3', 23, 14), `<em><i style="background:${MOOD.needsYou}"></i><i id="d-w3ok" style="background:${MOOD.working}"></i></em>`).replace('class="win"', 'class="win" style="z-index:5"')}
<span class="zz" id="d-z0" style="left:1716px;top:452px;font-size:54px" data-layout-ignore>z</span><span class="zz" id="d-z1" style="left:1748px;top:426px;font-size:42px" data-layout-ignore>z</span><span class="zz" id="d-z2" style="left:1700px;top:470px;font-size:34px" data-layout-ignore>z</span>
${vertex('d-v', 'day', D, VX, VY, 720, 652)}
<div class="bub clip" id="d-b1" data-start="15" data-duration="5.4" data-track-index="2" data-layout-allow-occlusion><img id="d-b1i" src="assets/footage/bubble-done.png" alt=""></div>
<div class="bub clip" id="d-b2" data-start="20.4" data-duration="3.15" data-track-index="2" data-layout-allow-occlusion><img id="d-b2i" src="assets/footage/bubble-needs.png" alt=""></div>
<div class="rip" id="d-rip" data-layout-ignore></div>
${L.map(l => l.html).join('\n')}
${CUR('d-cur')}`;
  let js = G.js;
  L.forEach((l, i) => { js += lineIn(l.id, l, l.tin, i === 0); js += lineOut(l.id, l, l.tout); });
  // asleep: z's drift up from the hood
  [[0, 0.1, 2], [1, 0.6, 1], [2, 1.1, 1]].forEach(([i, at, rep]) => { js += `gsap.set("#d-z${i}", { opacity: 0 });\ntl.to("#d-z${i}", { keyframes: [{ y: -44, x: 10, opacity: 1, duration: 0.5, ease: "none" }, { y: -128, x: 28, opacity: 0, duration: 1.0, ease: "none" }], repeat: ${rep} }, ${at});\n`; });
  // working: the window fills in line by line
  js += `gsap.set("#d-w1 .code u", { scaleX: 0 });\n` + strokes(7, 14).map((s, i) => i < 4 ? `gsap.set("#d-c1-${i}", { scaleX: 1 });\n` : `tl.to("#d-c1-${i}", { scaleX: 1, duration: 0.2, ease: "power2.out" }, ${r3(8.5 + (i - 4) * 0.21)});\n`).join('');
  // "every app": another app takes the place of the first along the current, then goes full screen. Vertex stays where it is.
  js += pieceOut('#d-w1', 10.8) + pieceIn('#d-w2', 11.0);
  js += `gsap.set("#d-full", { opacity: 0, clipPath: "inset(140px 80px 300px 1040px round 22px)" });\ntl.set("#d-full", { opacity: 1 }, 12.3);\ntl.set("#d-w2", { opacity: 0 }, 12.3);\ntl.to("#d-full", { clipPath: "inset(0px 0px 0px 0px round 0px)", duration: 0.55, ease: "power3.inOut" }, 12.3);\n`;
  // your turn: the real bubble pops from its tail
  js += `tl.fromTo("#d-b1i", { scale: 0.45, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.3, ease: "back.out(1.6)" }, 15);\n`; snd(T0 + 15.0, 'pop', 0.6);
  js += `tl.fromTo("#d-b2i", { scale: 0.9 }, { scale: 1, duration: 0.22, ease: "back.out(1.6)" }, 20.4);\n`; snd(T0 + 20.4, 'pop', 0.5);
  // the click: cursor in from off screen, tap on the buddy, and the waiting session's window jumps forward
  const CLICK = 23.4;
  js += `gsap.set("#d-cur", ${J(cp(-170, 1020))});\ntl.to("#d-cur", ${J({ ...cp(CX - 10, CY), duration: 0.9, ease: 'power3.out' })}, ${r3(CLICK - 0.95)});\n`;
  js += `tl.to("#d-cur", { scale: 0.84, duration: 0.1, ease: "power2.in" }, ${r3(CLICK - 0.05)});\ntl.to("#d-cur", { scale: 1, duration: 0.22, ease: "power2.out" }, ${r3(CLICK + 0.05)});\n`; snd(T0 + CLICK, 'click', 0.8);
  js += `gsap.set("#d-rip", { x: ${CX}, y: ${CY}, scale: 0.3, opacity: 0 });\ntl.fromTo("#d-rip", { scale: 0.3, opacity: 0.9 }, { scale: 1.7, opacity: 0, duration: 0.5, ease: "power2.out", immediateRender: false }, ${CLICK});\n`;
  js += `tl.to("#d-b2i", { scale: 0.6, opacity: 0, duration: 0.12, ease: "power2.in" }, ${CLICK});\n`;
  js += `gsap.set("#d-w3", { opacity: 0, scale: 0.2, transformOrigin: "68% 86%" });\ngsap.set("#d-w3ok", { opacity: 0 });\ngsap.set("#d-w3 .code u", { scaleX: 0 });\ntl.set("#d-w3", { opacity: 1 }, ${CLICK});\ntl.to("#d-w3", { scale: 1, duration: 0.45, ease: "power4.out" }, ${CLICK});\ntl.to("#d-w3ok", { opacity: 1, duration: 0.2 }, 23.7);\n`;
  js += strokes(23, 14).map((s, i) => i < 5 ? `tl.set("#d-c3-${i}", { scaleX: 1 }, ${CLICK});\n` : `tl.to("#d-c3-${i}", { scaleX: 1, duration: 0.2, ease: "power2.out" }, ${r3(24.0 + (i - 5) * 0.2)});\n`).join('');
  js += `tl.to("#d-cur", ${J({ ...cp(2080, 1010), duration: 0.6, ease: 'power2.in' })}, 24.3);\n`;
  // out along the current, carried by the buddy
  js += pieceOut('#d-vw', D - 0.34) + pieceOut('#d-w3', D - 0.34);
  snd(T0 + D - 0.22, 'whooshA', 0.5);
  return { body, js, words: L.map(l => l.id) };
});

// ================= 2. the cast: four characters, the same behaviours =================
add('cast', 14, (T0, D) => {
  const NAMES = [['cloud', say('Cloud Vertex')], ['pixel', say('Pixel Vertex')], ['robo', say('Robo Vertex')], ['cozy', say('Cozy Vertex')]];
  const BEH = [[0, say('Idle')], [1.8, say('Working')], [3.6, say('Happy')], [5.4, say('Curious')], [7.2, say('Thinking')]];
  const c1 = line('c1', rows('Vertex comes as four characters.'), { cap: 92, width: 1640, top: 112 });
  const c2 = line('c2', rows('They all do every behaviour and pull every face; only the body differs.', 'They all do every behaviour and pull every face;'), { cap: 64, width: 1640, top: 100 });
  let body = c1.html + c2.html, js = '';
  NAMES.forEach(([k, name], i) => { const x = 45 + i * 445;
    body += `<div class="disc" style="left:${x + 60}px;top:734px" data-layout-ignore></div><div class="vw" id="c-${k}w" style="left:${x}px;top:330px;width:520px;height:472px" data-layout-allow-occlusion><video id="c-${k}" class="clip" src="assets/footage/cast-${k}.webm" muted playsinline data-start="0" data-duration="${D}" data-track-index="${1 + i}" data-layout-allow-occlusion></video></div><div class="nm" id="c-n${i}" style="left:${x}px">${name}</div>`;
    js += pieceIn(`#c-${k}w`, 0.02 + i * 0.06) + pieceIn(`#c-n${i}`, 0.3 + i * 0.06) + pieceOut(`#c-${k}w`, D - 0.34 + i * 0.012) + pieceOut(`#c-n${i}`, D - 0.34 + i * 0.012); });
  body += `<div class="kk bh-k" id="c-bk" data-layout-ignore>${say('Behaviour')}</div>` + BEH.map(([, w], i) => `<div class="bh-w" id="c-b${i}">${w}</div>`).join('');
  js += pieceIn('#c-bk', 0.4) + pieceOut('#c-bk', D - 0.34);
  BEH.forEach(([at, ], i) => { const a = Math.max(at, 0.45); js += `gsap.set("#c-b${i}", { opacity: 0 });\ntl.set("#c-b${i}", { opacity: 1 }, ${a});\ntl.fromTo("#c-b${i}", { y: 44 }, { y: 0, duration: 0.22, ease: "power4.out", immediateRender: false }, ${a});\n` + (i < BEH.length - 1 ? `tl.set("#c-b${i}", { opacity: 0 }, ${BEH[i + 1][0]});\n` : pieceOut(`#c-b${i}`, D - 0.34)); if (i) snd(T0 + at, 'pop', 0.32); });
  js += lineIn('c1', c1, 0.04) + lineOut('c1', c1, 3.3) + lineIn('c2', c2, 3.5) + lineOut('c2', c2, D - 0.36);
  snd(T0 + D - 0.22, 'whooshB', 0.5);
  return { body, js, words: ['c1', 'c2'] };
});

// ================= 3. the close: what it touches, why it exists, the name =================
add('close', 18, (T0, D) => {
  const VX = 1150, VY = 300;
  const e1 = line('e1', rows('It needs no hooks and no changes to Claude settings, and only reads the files, never writes them.', 'It needs no hooks and', 'no changes to Claude settings,', 'and only reads the files,'), { cap: 68, width: 1000 });
  const e2 = line('e2', rows('telling you is the whole point.', 'telling you is'), {});
  const G = glows('e', CLOSE, VX + 360, 640);
  let body = `${G.html}${vertex('e-v', 'close', D, VX, VY, 720, 652)}${e1.html}${e2.html}
<div class="mark" id="e-mark">${say('Vertex Buddy')}</div><div class="url" id="e-url">${REPO}</div>`;
  let js = G.js + pieceIn('#e-vw', 0.02);
  js += lineIn('e1', e1, 0.06) + lineOut('e1', e1, 5.0) + lineIn('e2', e2, 5.2) + lineOut('e2', e2, 7.95);
  // the end card: the buddy carries itself to the left, the name wipes in beside it
  js += `tl.to("#e-vw", { x: -860, duration: 0.7, ease: "power3.inOut" }, 8.0);\ntl.to('[id^="e-g-"]', { x: -860, duration: 0.7, ease: "power3.inOut" }, 8.0);\n`;
  js += `gsap.set("#e-mark", { clipPath: "inset(0% 100% -10% 0%)" });\ntl.to("#e-mark", { clipPath: "inset(0% 0% -10% 0%)", duration: 0.4, ease: "power3.out" }, 8.35);\n`;
  js += `gsap.set("#e-url", { opacity: 0 });\ntl.set("#e-url", { opacity: 1 }, 8.75);\ntl.fromTo("#e-url", { y: 40 }, { y: 0, duration: 0.24, ease: "power4.out", immediateRender: false }, 8.75);\n`;
  snd(T0 + 8.35, 'pop', 0.4);
  return { body, js, words: ['e1', 'e2'] };
});

// ================= write the project =================
fs.mkdirSync(path.join(OUT, 'compositions'), { recursive: true });
for (const n of ['day', 'cast-cloud', 'cast-pixel', 'cast-robo', 'cast-cozy', 'close']) asset(path.join(VIDEO, 'assets/footage', n + '.webm'), `footage/${n}.webm`);
for (const n of ['bubble-done.png', 'bubble-needs.png']) asset(path.join(VIDEO, 'assets/footage', n), 'footage/' + n);
for (const [f] of Object.values(SFX)) asset(path.join(VIDEO, 'assets/audio/sfx', f), 'audio/sfx/' + f);
for (const f of ['jetbrains-mono-var-latin.woff2', 'OFL.txt']) asset(path.join(VIDEO, 'assets/fonts', f), 'fonts/' + f);
const MUSIC = ['vertex.mp3', 'vertex.wav'].map(f => path.join(VIDEO, 'assets/audio/music', f)).find(f => fs.existsSync(f));
if (MUSIC) asset(MUSIC, 'audio/music/' + path.basename(MUSIC));

const DUR = r3(scenes.reduce((a, s) => a + s.beats, 0) * B);
for (const s of scenes) fs.writeFileSync(path.join(OUT, 'compositions', s.id + '.html'),
  `<template>\n<style>\n${scope(CSS)}\n</style>\n<div id="root" data-composition-id="${s.id}" data-width="${W}" data-height="${H}">\n${s.body}\n</div>\n<script>\n(function () {\n  const tl = gsap.timeline({ paused: true });\n${s.js.split('\n').map(l => '  ' + l).join('\n')}\n  window.__timelines["${s.id}"] = tl;\n})();\n</script>\n</template>\n`);
const hosts = scenes.map(s => `      <div id="${s.id}" data-composition-id="${s.id}" data-composition-src="compositions/${s.id}.html" data-start="${s.start}" data-duration="${s.dur}" data-track-index="0" data-track-kind="graphics" data-width="${W}" data-height="${H}"></div>`).join('\n');
sfx.sort((a, b) => a.t - b.t); const ends = []; const lane = (st, d) => { let i = ends.findIndex(e => e <= st + 1e-6); if (i < 0) { i = ends.length; ends.push(0); } ends[i] = st + d; return 12 + i; };
const fx = sfx.map((e, i) => { const [f, d] = SFX[e.key]; return `      <audio id="sfx-${i}-${e.key}" class="clip" src="assets/audio/sfx/${f}" data-start="${e.t}" data-duration="${d}" data-volume="${e.vol}" data-track-index="${lane(e.t, d)}"></audio>`; }).join('\n');
const music = MUSIC ? `      <audio id="music-bed" class="clip" src="assets/audio/music/${path.basename(MUSIC)}" data-start="0" data-duration="${DUR}" data-volume="0.8" data-fade-out="1.2" data-track-index="10" data-timeline-role="music"></audio>\n` : '';
fs.writeFileSync(path.join(OUT, 'index.html'), `<!doctype html>
<html lang="en" data-resolution="landscape">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=${W}, height=${H}" />
    <title>Vertex Buddy launch film, 16:9</title>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { margin: 0; width: ${W}px; height: ${H}px; overflow: hidden; background: ${GROUND}; }
    </style>
  </head>
  <body>
    <!-- Generated by video/source/build/film.mjs. Edit the builder, then run: video/source/bin/make build -->
    <div id="root" data-composition-id="main" data-start="0" data-duration="${DUR}" data-width="${W}" data-height="${H}">
${hosts}
${music}${fx}
    </div>
    <script>
      window.__timelines = window.__timelines || {};
      window.__timelines["main"] = gsap.timeline({ paused: true });
    </script>
  </body>
</html>
`);
const put = (f, s) => { if (!fs.existsSync(path.join(OUT, f))) fs.writeFileSync(path.join(OUT, f), s); };
put('hyperframes.json', J({ $schema: 'https://hyperframes.heygen.com/schema/hyperframes.json', registry: 'https://raw.githubusercontent.com/heygen-com/hyperframes/main/registry', paths: { blocks: 'compositions', components: 'compositions/components', assets: 'assets' }, media: { autoProxy: true } }, null, 2) + '\n');
put('meta.json', J({ id: P, name: 'vertex-buddy-launch', createdAt: '2026-11-21T00:00:00.000Z' }, null, 2) + '\n');
put('package.json', J({ name: P, private: true, type: 'module' }, null, 2) + '\n');

// ---- the storyboard and the list of every sentence used, written from the same numbers
const mmss = x => `${Math.floor(x / 60)}:${(x % 60).toFixed(1).padStart(4, '0')}`;
fs.mkdirSync(path.join(VIDEO, 'storyboard'), { recursive: true });
fs.writeFileSync(path.join(VIDEO, 'storyboard/timeline-film.json'), J({ film: 'Vertex Buddy launch film, 16:9', width: W, height: H, fps: 30, bpm: BPM, duration: DUR, music: MUSIC ? path.basename(MUSIC) : null,
  scenes: scenes.map(s => ({ id: s.id, start: s.start, dur: s.dur, beats: s.beats })), sfx: sfx.map(e => ({ t: e.t, sound: SFX[e.key][0], volume: e.vol })), words: [...new Set(used)] }, null, 1));
console.log(`${P}: ${scenes.length} scenes | ${DUR} s | ${[...new Set(used)].length} README lines, all word for word | sfx ${sfx.length} | music ${MUSIC ? path.basename(MUSIC) : 'none'}`);
for (const s of scenes) console.log(`  ${s.id.padEnd(6)} ${mmss(s.start)}  ${s.dur.toFixed(1)} s`);
