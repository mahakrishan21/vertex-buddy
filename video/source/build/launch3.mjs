// Vertex Buddy launch film, version 3: narrated, 56 s, 16:9. Writes the HyperFrames project in source/launch2/.
// Run: video/source/bin/make build
//
// Version 3 is version 2 cut faster and hit harder: every cut punches in, big moments flash and shake, bursts and rings
// mark the wins, small labels add detail, and there is one more shot (drag it anywhere). The additions are in FX below.
// Made after studying a reference (docs/reference-lovio.md): a flowing narration, type that picks out key words instead of
// repeating the voice, and a new "world" every two or three seconds. Sixteen shots, each its own scene with its own ground.
// Vertex and its speech bubble are recorded from the app itself (bin/make footage). Windows are plain drawings, not a real app.
import fs from 'node:fs'; import path from 'node:path';
import { VIDEO, r3, J, esc, MOOD, GROUND, INK, SOFT, NIGHT, CSS, scope, take, linker, CUR, cp, curTo, tap, line, wfIn, cutOut, cutIn, pieceIn, pieceOut, popIn, glows, strokes, code, win, cards, vertex } from './kit.mjs';

const P = 'launch3', OUT = path.join(VIDEO, 'source', P), FOOT = 'footage-launch2';
const W = 1920, H = 1080, BPM = 120, B = 60 / BPM;
const REPO = 'github.com/mahakrishan21/vertex-buddy';
const asset = linker(OUT);
const VO = JSON.parse(fs.readFileSync(path.join(VIDEO, 'assets/audio/voice', P, 'manifest.json'), 'utf8')).lines;
const voDur = Object.fromEntries(VO.map(l => [l.id, l.duration]));
const SFX = { click: ['click-soft.mp3', 0.37], key: ['key-press.mp3', 0.43], whooshA: ['whoosh-short.mp3', 0.57], whooshB: ['whoosh.mp3', 0.57], pop: ['pop.mp3', 0.72], impact: ['impact-bass-1.mp3', 2.12], riser: ['riser.mp3', 4.0, 0.7] };
const sfx = [], vo = [], copy = [];
const snd = (t, key, vol) => sfx.push({ t: r3(t), key, vol });
const speak = (t, id) => vo.push({ id, at: r3(t), duration: voDur[id] });
const say = s => { copy.push(s); return s; };
const NAVY = '#0B0F2A', DEEP = { working: '#27A85B', done: '#D79A00', needsYou: '#E23766' };

const EXTRA = `
.cam { position: absolute; inset: 0; }
.shot { position: absolute; inset: 0; }
.flash { position: absolute; inset: 0; background: #FFFFFF; z-index: 90; }
.grid { position: absolute; inset: -40px; background-image: radial-gradient(rgba(25,27,36,.10) 1.6px, transparent 1.8px); background-size: 34px 34px; }
.cf { position: absolute; border-radius: 4px; z-index: 12; }
.ringfx { position: absolute; border-radius: 50%; border: 10px solid #fff; z-index: 2; }
.streak { position: absolute; top: 0; width: 7px; height: 420px; border-radius: 4px; background: rgba(25,27,36,.22); z-index: 5; }
.chipm { position: absolute; z-index: 21; padding: 14px 28px; border-radius: 40px; background: rgba(255,255,255,.93); color: #191B24; font-size: 30px; box-shadow: 0 16px 40px -18px rgba(20,24,60,.45); }
.lst { position: absolute; left: 124px; z-index: 21; display: flex; align-items: center; gap: 16px; font-size: 32px; color: #191B24; }
.lst i { width: 20px; height: 20px; border-radius: 50%; }
.menubar { position: absolute; left: 0; right: 0; top: 0; height: 46px; z-index: 4; background: rgba(255,255,255,.72); display: flex; align-items: center; gap: 26px; padding: 0 26px; }
.menubar b { width: 20px; height: 20px; border-radius: 6px; background: rgba(25,27,36,.5); }
.menubar span { width: 64px; height: 10px; border-radius: 5px; background: rgba(25,27,36,.28); }
.menubar em { margin-left: auto; width: 150px; height: 10px; border-radius: 5px; background: rgba(25,27,36,.22); }
.blob { position: absolute; width: 1500px; height: 1500px; margin: -750px 0 0 -750px; border-radius: 50%; }
.veil { position: absolute; inset: 0; background: ${NIGHT}; z-index: 5; }
.ctr { left: 0; right: 0; text-align: center; }
.ghost { position: absolute; left: 0; right: 0; text-align: center; font-weight: 900; letter-spacing: -0.05em; line-height: 1; white-space: nowrap; z-index: 3; }
.word { position: absolute; font-weight: 900; letter-spacing: -0.05em; line-height: .9; white-space: nowrap; z-index: 3; }
.tag { position: absolute; z-index: 20; font-size: 30px; letter-spacing: .14em; text-transform: uppercase; }
.col { position: absolute; top: 0; width: 480px; height: 1080px; overflow: hidden; }
.col .vw { left: -30px; top: 300px; width: 540px; height: 490px; }
.col span { position: absolute; left: 0; right: 0; top: 880px; text-align: center; font-size: 32px; z-index: 20; }
.tile { position: absolute; width: 480px; height: 360px; overflow: hidden; }
.tile img { position: absolute; left: 30px; top: -30px; width: 420px; height: 381px; transform: scale(1.75); transform-origin: 50% 48%; }
.tile span { position: absolute; left: 16px; bottom: 14px; font-size: 30px; z-index: 2; padding: 4px 14px; border-radius: 12px; background: rgba(255,255,255,.9); color: #191B24; }
.chip { position: absolute; left: 50%; top: 50%; z-index: 30; margin: -66px 0 0 -330px; width: 660px; height: 132px; border-radius: 66px; background: #FFFFFF; box-shadow: 0 30px 80px -20px rgba(20,24,60,.45); display: flex; align-items: center; justify-content: center; font-weight: 900; font-size: 76px; letter-spacing: -0.03em; }
.num { position: absolute; font-weight: 900; letter-spacing: -0.06em; line-height: .8; z-index: 2; }
.call { position: absolute; border: 7px solid ${MOOD.needsYou}; border-radius: 34px; z-index: 9; }
.mark { position: absolute; left: 900px; top: 372px; z-index: 20; font-weight: 900; font-size: 140px; letter-spacing: -0.045em; line-height: 1; white-space: nowrap; }
.url { position: absolute; left: 906px; top: 548px; z-index: 20; font-size: 38px; }
.indie { position: absolute; left: 906px; top: 616px; z-index: 20; font-size: 28px; font-weight: 500; }
`;

// ---- helpers for this film
const drift = (sel, D, a = 1, b = 1.06, origin = '50% 50%') => `gsap.set("${sel}", { scale: ${a}, transformOrigin: "${origin}" });\ntl.to("${sel}", { scale: ${b}, duration: ${D}, ease: "none" }, 0);\n`;
/** a centred line; a word that starts with * takes the accent colour */
const center = (id, text, size, top, { color = null, accent = MOOD.needsYou, weight = 900 } = {}) => { const ws = say(text.replace(/\*/g, '')) && text.split(' ');
  return { id, n: ws.length, html: `<div class="ln ctr" id="${id}" style="top:${top}px;font-size:${size}px;font-weight:${weight}${color ? ';color:' + color : ''}"><span class="row">${ws.map((w, i) => `<span class="kw" id="${id}-${i}"${w[0] === '*' ? ` style="color:${accent}"` : ''}>${esc(w.replace(/^\*/, ''))}</span>`).join('')}</span></div>` }; };
const L = (id, rws, o = {}) => { say(rws.join(' ')); return line(id, rws, { factor: 0.56, cap: 130, ...o }); };
const blobs = (id, list) => list.map(([x, y, col, a = '66'], i) => `<div class="blob" id="${id}-bl${i}" data-layout-ignore style="left:${x}px;top:${y}px;background:radial-gradient(circle, ${col}${a} 0%, ${col}22 38%, ${col}00 64%)"></div>`).join('');
const sway = (id, n, D) => Array.from({ length: n }, (_, i) => `tl.fromTo("#${id}-bl${i}", { x: ${i % 2 ? 140 : -160}, y: ${i % 2 ? -60 : 80} }, { x: ${i % 2 ? -150 : 170}, y: ${i % 2 ? 70 : -50}, duration: ${D}, ease: "sine.inOut" }, 0);\n`).join('');
const typing = (cid, seed, n, from, every, until) => strokes(seed, n).map((s, i) => { const a = from + i * every; return a < until ? `tl.to("#${cid}-${i}", { scaleX: 1, duration: 0.16, ease: "power2.out" }, ${r3(a)});\n` : ''; }).join('');
const clip = (id, src, start, dur, x, y, w, h, { media = 0, track = 1, z = 6 } = {}) => `<div class="vw" id="${id}w" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px;z-index:${z}" data-layout-allow-occlusion><video id="${id}" class="clip" src="assets/${FOOT}/${src}.webm" muted playsinline data-start="${start}" data-duration="${dur}"${media ? ` data-media-start="${media}"` : ''} data-track-index="${track}" data-layout-allow-occlusion></video></div>`;

// ================= version 3: energy and detail, added to the shots above by name =================
const shake = (id, at, amp = 14) => `tl.to("#${id}-shot", { keyframes: [{ x: ${amp}, y: ${r3(-amp * 0.6)} }, { x: ${r3(-amp * 0.8)}, y: ${r3(amp * 0.5)} }, { x: ${r3(amp * 0.5)}, y: ${r3(amp * 0.3)} }, { x: ${r3(-amp * 0.3)}, y: ${r3(-amp * 0.2)} }, { x: 0, y: 0 }], duration: 0.3, ease: "none" }, ${r3(at)});\n`;
const flash = (id, at, op = 0.5) => `tl.fromTo("#${id}-fl", { opacity: ${op} }, { opacity: 0, duration: 0.28, ease: "power2.out", immediateRender: false }, ${r3(at)});\n`;
const hit = (id, at, amp, op) => shake(id, at, amp) + flash(id, at, op);
function confetti(id, cx, cy, at, cols, n = 26, seed = 7) { let x = seed; const rnd = () => (x = (x * 16807) % 2147483647) / 2147483647; let html = '', js = '';
  for (let i = 0; i < n; i++) { const a = rnd() * Math.PI * 2, d = 260 + rnd() * 440, w = 14 + rnd() * 18, ex = r3(Math.cos(a) * d), ey = r3(Math.sin(a) * d - 130);
    html += `<i class="cf" id="${id}-cf${i}" data-layout-ignore style="left:${cx}px;top:${cy}px;width:${r3(w)}px;height:${r3(w * 0.45)}px;background:${cols[i % cols.length]}"></i>`;
    js += `gsap.set("#${id}-cf${i}", { opacity: 0 });\ntl.set("#${id}-cf${i}", { opacity: 1 }, ${at});\ntl.fromTo("#${id}-cf${i}", { x: 0, y: 0, rotation: 0, scale: 0.4 }, { x: ${ex}, y: ${ey}, rotation: ${Math.round(rnd() * 720 - 360)}, scale: 1, duration: 0.7, ease: "power3.out", immediateRender: false }, ${at});\ntl.to("#${id}-cf${i}", { y: ${r3(ey + 190)}, opacity: 0, duration: 0.6, ease: "power1.in" }, ${r3(at + 0.7)});\n`; }
  return { html, js }; }
const ring = (id, k, cx, cy, at, col, size = 900) => ({ html: `<div class="ringfx" id="${id}-rg${k}" data-layout-ignore style="left:${cx}px;top:${cy}px;width:${size}px;height:${size}px;margin:${-size / 2}px 0 0 ${-size / 2}px;border-color:${col}"></div>`, js: `gsap.set("#${id}-rg${k}", { opacity: 0, scale: 0.1 });\ntl.fromTo("#${id}-rg${k}", { opacity: 0.9, scale: 0.1 }, { opacity: 0, scale: 1, duration: 0.65, ease: "power2.out", immediateRender: false }, ${at});\n` });
const chipm = (id, text, style, at) => ({ html: `<div class="chipm mono" id="${id}" style="${style}">${say(text)}</div>`, js: popIn('#' + id, at, 0.6) });
const merge = (...xs) => ({ html: xs.map(x => x.html || '').join(''), js: xs.map(x => x.js || '').join('') });
const floodFx = (id, chip, style, extra = {}) => (T0, D) => merge(ring(id, 0, 960, 540, 0.02, 'rgba(255,255,255,.75)', 1900), ring(id, 1, 960, 540, 0.14, 'rgba(255,255,255,.5)', 1300), chipm(id + '-chip', chip, style, 0.55), extra, { js: hit(id, 0.02, 12, 0.45) });
const FX = {
  a2: () => ({ js: hit('a2', 0.45, 10, 0.35) }),
  b2: () => ({ js: hit('b2', 0.5, 16, 0.5) }),
  // the landing: streaks on the way down, then a ring, a burst and a jolt
  c1: () => { const st = [700, 860, 1010, 1160, 1260].map((x, i) => ({ html: `<i class="streak" id="c1-st${i}" data-layout-ignore style="left:${x}px"></i>`, js: `tl.fromTo("#c1-st${i}", { y: -500, opacity: 0.5 }, { y: 1300, opacity: 0, duration: 0.3, ease: "none" }, ${r3(0.03 + i * 0.03)});\n` }));
    return merge(...st, ring('c1', 0, 960, 960, 0.42, MOOD.working, 1700), confetti('c1', 960, 640, 0.42, [MOOD.working, MOOD.idle, MOOD.done, MOOD.needsYou, MOOD.asleep], 32, 5), { js: hit('c1', 0.42, 22, 0.6) }); },
  c2: () => ({ html: `<div class="menubar" id="c2-mb" data-layout-ignore><b></b><span></span><span></span><span></span><em></em></div>`, js: pieceIn('#c2-mb', 0.05) }),
  d1: floodFx('d1', 'hands typing, a foot tapping', 'left:124px;top:190px'),
  d2: floodFx('d2', 'it hops, chimes, and pops a speech bubble', 'left:770px;top:390px', confetti('d2', 510, 560, 0.3, ['#FFFFFF', '#FFE9A8', '#191B24', '#FFF4CF'], 28, 9)),
  d3: floodFx('d3', 'reminds you again every 5 minutes', 'left:124px;top:372px'),
  // what a row tells you
  e1: () => merge(...[['its status', MOOD.needsYou], ['the app it runs in', MOOD.idle], ['how long it has been in that state', MOOD.asleep]].map(([t, c], i) => ({ html: `<div class="lst mono" id="e1-l${i}" style="top:${640 + i * 66}px"><i style="background:${c}"></i>${say(t)}</div>`, js: popIn('#e1-l' + i, 0.9 + i * 0.18, 0.7) }))),
  e2: () => ({ js: hit('e2', 0.75, 10, 0.3) }),
  // the big numeral counts with the cuts
  f2: () => { const A = 0.1, STEP = 0.26; let html = '', js = `gsap.set("#f2-n", { opacity: 0 });\n`;
    for (let i = 0; i < 9; i++) { const a = r3(A + i * STEP); html += `<div class="num" id="f2-c${i}" style="left:90px;top:180px;font-size:760px;color:#EEF0F7" data-layout-ignore>${i + 1}</div>`; js += `gsap.set("#f2-c${i}", { opacity: 0 });\ntl.set("#f2-c${i}", { opacity: 1 }, ${a});\ntl.fromTo("#f2-c${i}", { scale: 1.12 }, { scale: 1, duration: 0.16, ease: "power3.out", immediateRender: false }, ${a});\n` + (i < 8 ? `tl.set("#f2-c${i}", { opacity: 0 }, ${r3(a + STEP)});\n` : ''); }
    return { html, js }; },
  g: () => chipm('g-chip', 'reads ~/.claude/sessions, once a second', 'left:124px;top:760px;background:rgba(255,255,255,.12);color:rgba(255,255,255,.85)', 2.1),
  h: () => merge(ring('h', 0, 650, 700, 3.2, MOOD.idle, 1500), confetti('h', 650, 600, 3.2, [MOOD.working, MOOD.idle, MOOD.done, MOOD.needsYou, MOOD.asleep], 34, 11), { js: hit('h', 3.2, 16, 0.5) }),
  e3: () => ({ js: hit('e3', 1.55, 12, 0.3) }),
};

const scenes = [];
const add = (id, beats, bg, fn) => { const start = scenes.reduce((a, s) => a + s.beats, 0), T0 = r3(start * B), D = r3(beats * B), s = fn(T0, D), fx = (FX[id] || (() => ({})))(T0, D);
  scenes.push({ id, beats, bg, start: T0, dur: D, ...s, body: s.body + (fx.html || ''), js: s.js + (fx.js || '') }); };

// ===== A1 (0–2): macro on one session at work =====
add('a1', 4, NIGHT, (T0, D) => {
  const body = `<div class="cam" id="a1-cam" data-layout-ignore>${win('a1-w', 'api', code('a1-c', 11, 15, 1.9), { x: 300, y: 150, w: 1320, h: 800, cls: 'dark', dot: `<em><i style="background:${MOOD.working}"></i></em>` })}</div>`;
  let js = `gsap.set("#root .code u", { scaleX: 0 });\ngsap.set("#a1-c-0, #a1-c-1, #a1-c-2, #a1-c-3", { scaleX: 1 });\n` + drift('#a1-cam', D, 1.04, 1.2, '42% 36%') + typing('a1-c', 11, 15, 0.02, 0.12, D);
  [0.1, 0.5, 0.9, 1.3].forEach(t => snd(T0 + t, 'key', 0.22)); speak(T0 + 0.4, 'a1');
  return { body, js };
});

// ===== A2 (2–4.5): the question, in type =====
add('a2', 4, NAVY, (T0, D) => {
  const t1 = center('a2-s', 'the moment', 70, 372, { color: 'rgba(255,255,255,.66)', weight: 700 }), t2 = center('a2-b', 'Claude *needs *you.', 168, 458, { color: '#FFFFFF' });
  const body = blobs('a2', [[520, 380, '#2B4BFF'], [1420, 720, '#7A3CF0']]) + t1.html + t2.html;
  let js = sway('a2', 2, D) + wfIn('a2-s', t1.n, 0.05) + wfIn('a2-b', t2.n, 0.3, { gap: 0.13 }) + `tl.to("#a2-b", { scale: 1.05, duration: ${D - 0.3}, ease: "none" }, 0.3);\n` + cutOut('a2-s', t1.n, D - 0.36) + cutOut('a2-b', t2.n, D - 0.34);
  snd(T0 - 0.05, 'whooshA', 0.4);
  return { body, js };
});

// ===== B1 (4.5–7.5): the desktop, wide. Sessions at work; you move on to something else =====
add('b1', 5, NIGHT, (T0, D) => {
  const t = L('b1-t', ['works on', 'its own.'], { color: '#FFFFFF', width: 760, cy: 500 });
  const body = `<div class="cam" id="b1-cam" data-layout-ignore>
${win('b1-a', 'website', code('b1-ca', 5, 12), { x: 1060, y: 70, w: 720, h: 430, cls: 'dark', z: 1 })}${win('b1-c', 'docs', code('b1-cc', 9, 8, 0.6), { x: 880, y: 720, w: 380, h: 300, cls: 'dark', z: 1 })}
${win('b1-b', 'api', code('b1-cb', 3, 9, 0.9), { x: 1300, y: 640, w: 540, h: 380, cls: 'dark', z: 2, dot: `<em><i style="background:${MOOD.working}"></i></em>` })}
${win('b1-d', 'notes', cards('b1-k', 350, 326), { x: 980, y: 150, w: 780, h: 500, cls: 'warm', z: 3 })}</div>${t.html}`;
  let js = `gsap.set("#root .code u", { scaleX: 0 });\n` + drift('#b1-cam', D, 1.1, 1.0, '72% 55%') + typing('b1-ca', 5, 12, 0, 0.2, D) + typing('b1-cc', 9, 8, 0.1, 0.33, D) + typing('b1-cb', 3, 9, 0.05, 0.26, 1.9);
  js += cutIn('b1-t', t.n, 0.3) + cutOut('b1-t', t.n, D - 0.36); speak(T0 + 0.3, 'b1');
  js += pieceIn('#b1-d', 1.5, 420) + `tl.to("#b1-a, #b1-b, #b1-c", { opacity: 0.5, duration: 0.4, ease: "power2.out" }, 1.5);\n`;
  snd(T0 - 0.05, 'whooshB', 0.4); snd(T0 + 1.5, 'whooshA', 0.3); speak(T0 + 2.4, 'b2');
  return { body, js };
});

// ===== B2 (7.5–11.5): the one that stopped, close up. It waits, and windows pile over it =====
add('b2', 7, NIGHT, (T0, D) => {
  const t = L('b2-t', ['it waits.'], { color: MOOD.needsYou, width: 700, cy: 470, cap: 170 }), s = L('b2-s', ['somewhere behind', 'your windows'], { color: 'rgba(255,255,255,.7)', width: 700, top: 590, cap: 62, weight: 700 });
  const body = `<div class="cam" id="b2-cam" data-layout-ignore>
${win('b2-b', 'api', code('b2-cb', 3, 11, 1.5), { x: 860, y: 220, w: 940, h: 640, cls: 'dark', z: 2, dot: `<em><i style="background:${MOOD.needsYou}"></i></em>` })}
<div class="rip" id="b2-r1" style="z-index:8"></div><div class="rip" id="b2-r2" style="z-index:8"></div>
${win('b2-d', 'notes', cards('b2-k', 350, 326), { x: 1080, y: 330, w: 780, h: 620, cls: 'warm', z: 3 })}${win('b2-e', 'mail', code('b2-ce', 31, 9), { x: 960, y: 560, w: 600, h: 440, z: 4 })}</div>${t.html}${s.html}`;
  let js = strokes(3, 11).map((_, i) => `gsap.set("#b2-cb-${i}", { scaleX: ${i < 6 ? 1 : 0} });\n`).join('') + drift('#b2-cam', D, 1.0, 1.1, '86% 24%');
  js += [0.0, 1.0, 2.0, 3.0].map((a, i) => `gsap.set("#b2-r${i % 2 + 1}", { x: 1760, y: 251, scale: 0.2, opacity: 0 });\ntl.fromTo("#b2-r${i % 2 + 1}", { scale: 0.2, opacity: 0.95 }, { scale: 1.5, opacity: 0, duration: 0.9, ease: "power2.out", immediateRender: false }, ${a});\n`).join('');
  js += `gsap.set("#b2-t", { opacity: 0, transformOrigin: "0% 50%" });\ntl.set("#b2-t", { opacity: 1 }, 0.5);\ntl.fromTo("#b2-t", { scale: 1.25 }, { scale: 1, duration: 0.2, ease: "power4.out", immediateRender: false }, 0.5);\n`;
  js += wfIn('b2-s', s.n, 1.9) + pieceIn('#b2-d', 1.9, 520) + pieceIn('#b2-e', 2.4, -520);
  js += `tl.to("#b2-t", { scale: 6, opacity: 0, duration: 0.3, ease: "power4.in" }, ${D - 0.3});\n` + cutOut('b2-s', s.n, D - 0.36) + `tl.to("#b2-cam", { opacity: 0, duration: 0.25, ease: "power2.in" }, ${D - 0.25});\n`;
  snd(T0, 'impact', 0.5); snd(T0 + D - 4.0, 'riser', 0.26);
  return { body, js };
});

// ===== C1 (11.5–14.5): Vertex drops in, the name behind it =====
add('c1', 6, GROUND, (T0, D) => {
  const TK = take(FOOT, 'hero'), LAND = 0.42, G = glows('c1', TK, 960, 660);
  const body = `${G.html}<div class="ghost" id="c1-n" style="top:64px;font-size:236px;color:${INK}" data-layout-allow-overlap>${say('Vertex Buddy')}</div>${clip('c1-v', 'hero', 0, D, 500, 215, 920, 834)}`;
  let js = `gsap.set('[id^="c1-g-"]', { scale: 0.3, opacity: 0 });\ntl.to("#c1-g-${G.moods[0]}", { scale: 1, opacity: 1, duration: 0.5, ease: "power3.out" }, ${LAND});\n`;
  js += `gsap.set("#c1-vw", { y: -1150, transformOrigin: "50% 92%" });\ntl.to("#c1-vw", { y: 0, duration: ${LAND - 0.02}, ease: "power2.in" }, 0.02);\ntl.to("#c1-vw", { scale: 1.08, duration: ${D - LAND}, ease: "none" }, ${LAND});\n`;
  js += `gsap.set("#c1-n", { opacity: 0, scale: 0.86 });\ntl.set("#c1-n", { opacity: 1 }, ${LAND});\ntl.to("#c1-n", { scale: 1, duration: 0.5, ease: "power4.out" }, ${LAND});\ntl.to("#c1-n", { scale: 1.05, duration: ${D - LAND - 0.5}, ease: "none" }, ${LAND + 0.5});\n`;
  js += pieceOut('#c1-vw', D - 0.3) + pieceOut('#c1-n', D - 0.34);
  snd(T0 + LAND, 'pop', 0.65); speak(T0 + 0.8, 'c1');
  return { body, js };
});

// ===== C2 (14.5–20): a real-sized desktop. Apps change behind it; it stays on top =====
add('c2', 10, GROUND, (T0, D) => {
  const TK = take(FOOT, 'desk'), G = glows('c2', TK, 1540, 700);
  const t1 = L('c2-a', ['above every app'], { width: 900, top: 880, cap: 96 }), t2 = L('c2-b', ['watching your sessions'], { width: 1000, top: 880, cap: 96 });
  const body = `<div class="cam" id="c2-cam" data-layout-ignore>${win('c2-w1', 'website', code('c2-c1', 7, 14, 1.3), { x: 200, y: 110, w: 1100, h: 700, z: 1 })}${win('c2-w2', 'notes', cards('c2-k', 500, 470), { x: 200, y: 110, w: 1100, h: 700, cls: 'warm', z: 2 })}
<div class="full" id="c2-full"><div class="tool"></div><div style="position:absolute;left:200px;top:110px;width:1100px;height:700px">${cards('c2-f', 500, 470)}</div></div>
${G.html}${clip('c2-v', 'desk', 0, D, 1240, 400, 600, 544)}</div>${t1.html}${t2.html}`;
  let js = G.js + drift('#c2-cam', D, 1.16, 1.0, '80% 66%') + pieceIn('#c2-cam', 0.02) + typing('c2-c1', 7, 14, 0.1, 0.1, 1.5) + `gsap.set("#c2-w1 .code u", { scaleX: 0 });\n`;
  js += pieceOut('#c2-w1', 1.5) + pieceIn('#c2-w2', 1.65);
  js += `gsap.set("#c2-full", { opacity: 0, clipPath: "inset(110px 620px 270px 200px round 22px)" });\ntl.set("#c2-full", { opacity: 1 }, 3.0);\ntl.set("#c2-w2", { opacity: 0 }, 3.0);\ntl.to("#c2-full", { clipPath: "inset(0px 0px 0px 0px round 0px)", duration: 0.55, ease: "power3.inOut" }, 3.0);\n`;
  js += cutIn('c2-a', t1.n, 0.9) + cutOut('c2-a', t1.n, 3.0) + cutIn('c2-b', t2.n, 3.25) + cutOut('c2-b', t2.n, D - 0.36) + pieceOut('#c2-vw', D - 0.32);
  snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + 1.5, 'whooshB', 0.28); snd(T0 + 3.0, 'whooshA', 0.3); speak(T0 + 0.2, 'c2');
  return { body, js };
});

// ===== D1–D3 (20–27.5): three colours, three worlds =====
const flood = (id, mood, word, takeName, vo_, lay) => add(id, 4, MOOD[mood], (T0, D) => {
  const body = `<div class="word" id="${id}-w" style="${lay.word};font-size:${lay.size}px;color:${DEEP[mood]}" data-layout-allow-overlap data-layout-allow-overflow>${say(word)}</div>
<div class="tag mono" id="${id}-k" style="${lay.tag};color:rgba(25,27,36,.72)">${say(lay.name)}</div>
${clip(id + '-v', takeName, 0, D, lay.vx, 190, 900, 815)}${lay.bubble ? `<div class="bub clip" id="${id}-b" style="left:${lay.bubble[1]}px;top:${lay.bubble[2]}px;width:680px;height:521px" data-start="0.45" data-duration="${r3(D - 0.45)}" data-track-index="2" data-layout-allow-occlusion><img id="${id}-bi" src="assets/${FOOT}/bubble-${lay.bubble[0]}.png" alt=""></div>` : ''}`;
  let js = `gsap.set("#${id}-w", { x: ${lay.from}, opacity: 0 });\ntl.set("#${id}-w", { opacity: 1 }, 0);\ntl.to("#${id}-w", { x: 0, duration: 0.4, ease: "power4.out" }, 0);\ntl.to("#${id}-w", { x: ${-lay.from * 0.12}, duration: ${D - 0.4}, ease: "none" }, 0.4);\n`;
  js += `gsap.set("#${id}-vw", { scale: 1.18, transformOrigin: "50% 80%" });\ntl.to("#${id}-vw", { scale: 1, duration: 0.35, ease: "power4.out" }, 0);\ntl.to("#${id}-vw", { scale: 1.05, duration: ${D - 0.35}, ease: "none" }, 0.35);\n` + pieceIn(`#${id}-k`, 0.15);
  if (lay.bubble) { js += `tl.fromTo("#${id}-bi", { scale: 0.45, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.3, ease: "back.out(1.6)" }, 0.45);\n`; snd(T0 + 0.45, 'pop', 0.5); }
  snd(T0 - 0.04, lay.hit, 0.42); speak(T0 + 0.3, vo_);
  return { body, js };
});
flood('d1', 'working', 'working', 'work', 'd1', { word: 'left:70px;top:620px', size: 300, tag: 'left:124px;top:110px', name: 'Green', vx: 1040, from: -300, hit: 'whooshB' });
flood('d2', 'done', 'finished', 'turn', 'd2', { word: 'left:760px;top:110px', size: 250, tag: 'left:124px;top:960px', name: 'Yellow', vx: 60, from: 300, hit: 'whooshA', bubble: ['done', 1130, 470] });
flood('d3', 'needsYou', 'needs you', 'needs', 'd3', { word: 'left:70px;top:90px', size: 250, tag: 'left:1640px;top:960px', name: 'Pink', vx: 980, from: -300, hit: 'whooshB', bubble: ['needs', 150, 480] });

// ===== E1 (27.5–31): the bubble, close up =====
add('e1', 6, GROUND, (T0, D) => {
  const TK = take(FOOT, 'demo'), G = glows('e1', TK, 1250, 900), t = L('e1-t', ['every', 'session.'], { width: 540, cy: 430, cap: 150 });
  const body = `<div class="cam" id="e1-cam" data-layout-ignore>${G.html}${clip('e1-v', 'demo', 0, D, 890, 590, 720, 652)}
<div class="bub clip" id="e1-b" style="left:700px;top:-6px;width:1100px;height:842px" data-start="0.2" data-duration="${r3(D - 0.2)}" data-track-index="2" data-layout-allow-occlusion><img id="e1-bi" src="assets/${FOOT}/bubble-needs.png" alt=""></div>
<div class="call" id="e1-call" style="left:806px;top:240px;width:888px;height:146px"></div></div>${t.html}${CUR('e1-cur')}`;
  let js = G.js + drift('#e1-cam', D, 1.0, 1.06, '65% 40%') + `tl.fromTo("#e1-bi", { scale: 0.5, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.32, ease: "back.out(1.5)" }, 0.2);\n`;
  js += cutIn('e1-t', t.n, 0.25) + cutOut('e1-t', t.n, D - 0.36);
  js += `gsap.set("#e1-cur", ${J(cp(2050, 1130))});\n` + curTo('e1-cur', 1330, 520, 0.2, 0.7) + curTo('e1-cur', 1560, 330, 1.5, 0.5, 'power3.inOut');
  js += `gsap.set("#e1-call", { opacity: 0 });\n` + [1.95, 2.6].map(a => `tl.fromTo("#e1-call", { scale: 1.16, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.22, ease: "power4.out", immediateRender: false }, ${a});\ntl.to("#e1-call", { opacity: 0, duration: 0.25, ease: "power2.in" }, ${a + 0.4});\n`).join('');
  snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + 0.2, 'pop', 0.5); snd(T0 + 1.95, 'key', 0.3); speak(T0 + 0.4, 'e1');
  return { body, js };
});

// ===== E2 (31–35): click. The waiting session's window comes forward =====
add('e2', 7, GROUND, (T0, D) => {
  const TK = take(FOOT, 'demo'), VX = 1150, VY = 300, CX = VX + 360, CY = 690, CLICK = 0.75, MEDIA = 5.3 - CLICK;
  const t1 = L('e2-a', ['Click.'], { width: 760, cy: 520, cap: 190 }), t2 = L('e2-b', ['straight', 'back in.'], { width: 760, cy: 520, cap: 150 });
  const body = `${win('e2-api', 'api', code('e2-ca', 23, 13), { x: 1120, y: 90, w: 740, h: 600, z: 1, dot: `<em><i style="background:${MOOD.needsYou}"></i><i id="e2-ok" style="background:${MOOD.working}"></i></em>` })}${win('e2-web', 'website', code('e2-cw', 7, 13), { x: 1010, y: 200, w: 780, h: 600, z: 2 })}
<div class="gl" id="e2-gp" data-layout-ignore style="left:${CX}px;top:640px;background:radial-gradient(circle, ${MOOD.needsYou}8C 0%, ${MOOD.needsYou}33 34%, ${MOOD.needsYou}00 62%)"></div><div class="gl" id="e2-gg" data-layout-ignore style="left:${CX}px;top:640px;background:radial-gradient(circle, ${MOOD.working}8C 0%, ${MOOD.working}33 34%, ${MOOD.working}00 62%)"></div>
${clip('e2-v', 'demo', 0, D, VX, VY, 720, 652, { media: r3(MEDIA) })}<div class="rip" id="e2-rip" data-layout-ignore></div>${t1.html}${t2.html}${CUR('e2-cur')}`;
  let js = `gsap.set("#e2-ok, #e2-gg", { opacity: 0 });\ngsap.set("#e2-ca-9, #e2-ca-10, #e2-ca-11, #e2-ca-12", { scaleX: 0 });\n` + pieceIn('#e2-vw', 0.02) + pieceIn('#e2-web', 0.02) + pieceIn('#e2-api', 0.06);
  js += cutIn('e2-a', t1.n, 0.25) + cutOut('e2-a', t1.n, 1.5) + cutIn('e2-b', t2.n, 1.7) + cutOut('e2-b', t2.n, D - 0.36);
  js += `gsap.set("#e2-cur", ${J(cp(900, 1180))});\n` + curTo('e2-cur', CX - 10, CY, 0.05, 0.62) + tap('e2-cur', CLICK); snd(T0 + CLICK, 'click', 0.85);
  js += `gsap.set("#e2-rip", { x: ${CX}, y: ${CY}, scale: 0.3, opacity: 0 });\ntl.fromTo("#e2-rip", { scale: 0.3, opacity: 0.9 }, { scale: 1.7, opacity: 0, duration: 0.5, ease: "power2.out", immediateRender: false }, ${CLICK});\n`;
  js += `tl.set("#e2-api", { zIndex: 3 }, ${CLICK});\ntl.fromTo("#e2-api", { scale: 0.94 }, { scale: 1, x: -110, y: 110, duration: 0.45, ease: "power4.out", immediateRender: false }, ${CLICK});\ntl.to("#e2-web", { x: 90, y: -90, scale: 0.95, opacity: 0.7, duration: 0.45, ease: "power4.out" }, ${CLICK});\ntl.to("#e2-ok", { opacity: 1, duration: 0.2 }, ${CLICK + 0.3});\ntl.to("#e2-gp", { opacity: 0, duration: 0.5 }, ${CLICK + 0.3});\ntl.to("#e2-gg", { opacity: 1, duration: 0.4 }, ${CLICK + 0.3});\n`;
  js += [9, 10, 11, 12].map((i, k) => `tl.to("#e2-ca-${i}", { scaleX: 1, duration: 0.2, ease: "power2.out" }, ${r3(CLICK + 0.7 + k * 0.3)});\n`).join('') + curTo('e2-cur', 2080, 1010, 2.0, 0.6, 'power2.in');
  js += pieceOut('#e2-vw', D - 0.32) + pieceOut('#e2-api', D - 0.32) + pieceOut('#e2-web', D - 0.32);
  snd(T0 - 0.05, 'whooshB', 0.4); speak(T0 + 0.3, 'e2');
  return { body, js };
});

// ===== E3: drag it anywhere. The app's own picked-up pose, and its own landing =====
add('e3', 5, GROUND, (T0, D) => {
  const t = L('e3-t', ['Drag it', 'anywhere.'], { width: 760, top: 96, cap: 140 }), X0 = 110, Y0 = 400, DX = 1010, GRAB = 0.45, DROP = 1.55, CX = X0 + 360, CY = Y0 + 390;
  const body = `${win('e3-w', 'website', code('e3-c', 7, 12), { x: 1000, y: 150, w: 800, h: 600, z: 1 })}<div class="disc" id="e3-home" style="left:${X0 + DX + 160}px;top:${Y0 + 570}px;z-index:2" data-layout-ignore></div>
${clip('e3-v', 'drag', 0, D, X0, Y0, 720, 652)}<div class="chipm mono" id="e3-chip" style="left:${X0 + DX + 130}px;top:${Y0 - 40}px">${say('that spot is remembered')}</div>${t.html}${CUR('e3-cur')}`;
  let js = cutIn('e3-t', t.n, 0.1) + cutOut('e3-t', t.n, D - 0.36);
  js += `gsap.set("#e3-cur", ${J(cp(CX - 500, 1180))});\n` + curTo('e3-cur', CX, CY, 0.02, 0.4) + tap('e3-cur', GRAB);
  js += `tl.to("#e3-vw", { x: ${DX}, duration: ${DROP - GRAB - 0.05}, ease: "power2.inOut" }, ${GRAB + 0.05});\ntl.to("#e3-vw", { y: -150, duration: ${r3((DROP - GRAB - 0.05) / 2)}, ease: "power2.out" }, ${GRAB + 0.05});\ntl.to("#e3-vw", { y: 0, duration: ${r3((DROP - GRAB - 0.05) / 2)}, ease: "power2.in" }, ${r3(GRAB + 0.05 + (DROP - GRAB - 0.05) / 2)});\n`;
  js += `tl.to("#e3-cur", { x: ${r3(cp(CX + DX, CY).x)}, duration: ${DROP - GRAB - 0.05}, ease: "power2.inOut" }, ${GRAB + 0.05});\n` + curTo('e3-cur', CX + DX + 420, CY + 420, DROP + 0.15, 0.5, 'power2.in');
  js += `gsap.set("#e3-home", { opacity: 0, scale: 0.3 });\ntl.to("#e3-home", { opacity: 1, scale: 1.3, duration: 0.3, ease: "back.out(2)" }, ${DROP});\n` + popIn('#e3-chip', DROP + 0.2, 0.6) + pieceOut('#e3-vw', D - 0.3);
  snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + GRAB, 'click', 0.7); snd(T0 + GRAB + 0.05, 'whooshB', 0.35); snd(T0 + DROP, 'pop', 0.6); speak(T0 + 0.3, 'e3');
  return { body, js };
});

// ===== F1 (35–37.5): four characters, four columns =====
add('f1', 4, GROUND, (T0, D) => {
  const CAST = [['cloud', 'Cloud Vertex', '#DDEBFF'], ['pixel', 'Pixel Vertex', '#E6E0FF'], ['robo', 'Robo Vertex', '#D9F3E5'], ['cozy', 'Cozy Vertex', '#FFEFC9']];
  let body = '', js = '';
  CAST.forEach(([k, name, col], i) => { body += `<div class="col" id="f1-c${i}" style="left:${i * 480}px;background:${col}" data-layout-ignore><div class="vw" id="f1-${k}w" data-layout-allow-occlusion><video id="f1-${k}" class="clip" src="assets/${FOOT}/cast-${k}.webm" muted playsinline data-start="0" data-duration="${D}" data-track-index="${1 + i}" data-layout-allow-occlusion></video></div><span class="mono">${say(name)}</span></div>`;
    js += `gsap.set("#f1-c${i}", { y: ${i % 2 ? -1080 : 1080} });\ntl.to("#f1-c${i}", { y: 0, duration: 0.42, ease: "power4.out" }, ${r3(i * 0.07)});\ntl.fromTo("#f1-${k}w", { scale: 1 }, { scale: 1.1, duration: ${D}, ease: "none" }, 0);\n`; });
  body += `<div class="chip" id="f1-chip" style="top:170px">${say('four characters')}</div>`;
  js += popIn('#f1-chip', 0.35, 0.6) + `tl.to("#f1-chip", { scale: 0.7, opacity: 0, duration: 0.2, ease: "power2.in" }, ${D - 0.2});\n`;
  snd(T0 - 0.05, 'whooshA', 0.4); speak(T0 + 0.3, 'f1');
  return { body, js };
});

// ===== F2 (37.5–40): nine behaviours, cut on the beat =====
add('f2', 5, '#FFFFFF', (T0, D) => {
  const BEH = ['idle', 'working', 'thinking', 'walking', 'following', 'watching', 'sleeping', 'happy', 'curious'], STEP = 0.26, A = 0.1;
  let body = `<div class="num" id="f2-n" style="left:90px;top:180px;font-size:760px;color:#EEF0F7" data-layout-ignore>9</div><div class="tag mono" style="left:124px;top:110px">${say('behaviours')}</div>`, js = drift('#f2-n', D, 1, 1.08, '20% 60%');
  BEH.forEach((b, i) => { const a = r3(A + i * STEP), last = i === BEH.length - 1, d = last ? r3(D - a) : STEP;
    body += clip('f2-b' + i, 'beh-' + b, a, last ? 0.4 : d, 860, 150, 900, 815, { track: 1 + i % 2 }) + `<div class="word" id="f2-w${i}" style="left:120px;top:770px;font-size:170px;color:${INK}">${say(b)}</div>`;
    js += `gsap.set("#f2-w${i}", { opacity: 0 });\ntl.set("#f2-w${i}", { opacity: 1 }, ${a});\ntl.fromTo("#f2-w${i}", { y: 50 }, { y: 0, duration: 0.14, ease: "power4.out", immediateRender: false }, ${a});\n` + (last ? '' : `tl.set("#f2-w${i}", { opacity: 0 }, ${r3(a + STEP)});\n`); if (i % 3 === 0) snd(T0 + a, 'key', 0.3); });
  snd(T0 - 0.05, 'whooshB', 0.4); speak(T0 + 0.3, 'f2');
  return { body, js };
});

// ===== F3 (40–42.5): twelve faces, wall to wall =====
add('f3', 4, GROUND, (T0, D) => {
  const FACES = ['neutral', 'happy', 'excited', 'curious', 'confused', 'sleepy', 'surprised', 'playful', 'focused', 'worried', 'pondering', 'sneaky'], TINT = ['#E3E6F2', '#D7DBEC'];
  let body = '', js = '';
  FACES.forEach((f, i) => { const c = i % 4, r = Math.floor(i / 4), a = r3(0.02 + (c + r) * 0.07);
    body += `<div class="tile" id="f3-t${i}" style="left:${c * 480}px;top:${r * 360}px;background:${TINT[(c + r) % 2]}"><img src="assets/${FOOT}/faces/${f}.png" alt=""><span class="mono">${say(f)}</span></div>`;
    js += `gsap.set("#f3-t${i}", { scale: 0.7, opacity: 0 });\ntl.set("#f3-t${i}", { opacity: 1 }, ${a});\ntl.to("#f3-t${i}", { scale: 1, duration: 0.3, ease: "back.out(1.4)" }, ${a});\n`; });
  body += `<div class="chip" id="f3-chip" style="top:540px;width:560px;margin-left:-280px;height:112px;font-size:64px">${say('twelve faces')}</div>`;
  js += popIn('#f3-chip', 0.6, 0.6) + `tl.to("#f3-chip", { scale: 0.7, opacity: 0, duration: 0.2, ease: "power2.in" }, ${D - 0.2});\n`;
  snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + 0.6, 'pop', 0.4); speak(T0 + 0.3, 'f3');
  return { body, js };
});

// ===== G (42.5–48): the quiet part. Three promises, at night =====
add('g', 9, NAVY, (T0, D) => {
  const TK = take(FOOT, 'trust'), G = glows('g', TK, 1500, 700);
  const rows = [['g1', 'No hooks.', 0.3], ['g2', 'No changes to your settings.', 1.4], ['g3', 'Nothing leaves your Mac.', 3.0]].map(([id, text, at], i) => ({ id, at, ...L('g-' + id, [text], { color: '#FFFFFF', width: 1240, top: 350 + i * 116, cap: 76 }) }));
  const body = blobs('g', [[1500, 700, '#2B4BFF', '55'], [300, 200, '#7A3CF0', '33']]) + `<div class="cam" id="g-cam" data-layout-ignore>${G.html}${clip('g-v', 'trust', 0, D, 1140, 330, 720, 652)}</div>` + rows.map(r => r.html).join('');
  let js = sway('g', 2, D) + `gsap.set('[id^="g-g-"]', { opacity: 0.45 });\n` + drift('#g-cam', D, 1, 1.06, '78% 70%') + pieceIn('#g-cam', 0.02);
  rows.forEach((r, i) => { js += wfIn(r.id, r.n, r.at, { gap: 0.09 }) + (i < 2 ? `tl.to("#${r.id}", { opacity: 0.4, duration: 0.3, ease: "power2.out" }, ${rows[i + 1].at});\n` : '') + cutOut(r.id, r.n, D - 0.36 + i * 0.01); snd(T0 + r.at, 'key', 0.3); });
  js += pieceOut('#g-cam', D - 0.32);
  snd(T0 - 0.05, 'whooshB', 0.4); speak(T0 + 0.4, 'g1'); speak(T0 + 1.5, 'g2'); speak(T0 + 3.1, 'g3');
  return { body, js };
});

// ===== H (48–56): the line, then the name =====
add('h', 14, GROUND, (T0, D) => {
  const CARD = 3.2, a = center('h-a', 'Claude does the work.', 96, 398, { color: SOFT, weight: 800 }), b = center('h-b', 'Vertex keeps you in the *loop.', 118, 506, { accent: '#1FA858' });
  const body = blobs('h', [[420, 300, MOOD.idle, '55'], [1500, 800, MOOD.working, '55'], [1000, 1100, MOOD.asleep, '44']]) + a.html + b.html +
    `<div class="gl" id="h-g" data-layout-ignore style="left:650px;top:640px;background:radial-gradient(circle, ${MOOD.idle}8C 0%, ${MOOD.idle}33 34%, ${MOOD.idle}00 62%)"></div>${clip('h-v', 'end', CARD - 0.2, r3(D - CARD + 0.2), 290, 300, 720, 652, { media: 2.2 })}
<div class="mark" id="h-mark">${say('Vertex Buddy')}</div><div class="url mono" id="h-url">${REPO}</div><div class="indie mono" id="h-ind">${say('An independent project. Not made by Anthropic.')}</div>`;
  let js = sway('h', 3, D) + wfIn('h-a', a.n, 0.4, { gap: 0.1 }) + wfIn('h-b', b.n, 1.5, { gap: 0.1 }) + cutOut('h-a', a.n, CARD - 0.36) + cutOut('h-b', b.n, CARD - 0.34);
  js += `gsap.set("#h-g", { opacity: 0, scale: 0.4 });\ntl.to("#h-g", { opacity: 1, scale: 1, duration: 0.5, ease: "power3.out" }, ${CARD});\n`;
  js += `gsap.set("#h-vw", { scale: 0.5, opacity: 0, transformOrigin: "50% 92%" });\ntl.set("#h-vw", { opacity: 1 }, ${CARD});\ntl.to("#h-vw", { scale: 1, duration: 0.4, ease: "back.out(1.5)" }, ${CARD});\n`;
  js += `gsap.set("#h-mark", { clipPath: "inset(-10% 100% -10% 0%)" });\ntl.to("#h-mark", { clipPath: "inset(-10% 0% -10% 0%)", duration: 0.45, ease: "power3.out" }, ${CARD + 0.25});\n`;
  js += `gsap.set("#h-url, #h-ind", { opacity: 0 });\ntl.set("#h-url", { opacity: 1 }, ${CARD + 0.6});\ntl.fromTo("#h-url", { y: 36 }, { y: 0, duration: 0.24, ease: "power4.out", immediateRender: false }, ${CARD + 0.6});\ntl.set("#h-ind", { opacity: 1 }, ${CARD + 0.75});\ntl.fromTo("#h-ind", { y: 30 }, { y: 0, duration: 0.24, ease: "power4.out", immediateRender: false }, ${CARD + 0.75});\n`;
  snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + CARD, 'pop', 0.55); speak(T0 + 0.5, 'h1');
  return { body, js, card: r3(T0 + CARD) };
});

// ================= write the project =================
fs.mkdirSync(path.join(OUT, 'compositions'), { recursive: true });
const FDIR = path.join(VIDEO, 'assets', FOOT);
for (const f of fs.readdirSync(FDIR)) { if (/\.(webm|png)$/.test(f)) asset(path.join(FDIR, f), `${FOOT}/${f}`); }
for (const f of fs.readdirSync(path.join(FDIR, 'faces'))) asset(path.join(FDIR, 'faces', f), `${FOOT}/faces/${f}`);
for (const [f] of Object.values(SFX)) asset(path.join(VIDEO, 'assets/audio/sfx', f), 'audio/sfx/' + f);
for (const f of ['jetbrains-mono-var-latin.woff2', 'OFL.txt']) asset(path.join(VIDEO, 'assets/fonts', f), 'fonts/' + f);
for (const l of VO) asset(path.join(VIDEO, l.file), `audio/voice/${l.id}.wav`);
const MUSIC = [P + '.mp3', P + '.wav', P + '-bed.wav'].map(f => path.join(VIDEO, 'assets/audio/music', f)).find(f => fs.existsSync(f));
if (MUSIC) asset(MUSIC, 'audio/music/' + path.basename(MUSIC));

const DUR = r3(scenes.reduce((a, s) => a + s.beats, 0) * B);
for (const s of scenes) fs.writeFileSync(path.join(OUT, 'compositions', s.id + '.html'),
  `<template>\n<style>\n${scope(CSS + EXTRA)}\n#root { background: ${s.bg}; }\n</style>\n<div id="root" data-composition-id="${s.id}" data-width="${W}" data-height="${H}">\n${[GROUND, '#FFFFFF'].includes(s.bg) ? '<div class="grid" data-layout-ignore></div>' : ''}<div class="shot" id="${s.id}-shot">\n${s.body}\n</div><div class="flash" id="${s.id}-fl" data-layout-ignore></div>\n</div>\n<script>\n(function () {\n  const tl = gsap.timeline({ paused: true });\n${(`gsap.set("#${s.id}-fl", { opacity: 0 });\ntl.fromTo("#${s.id}-shot", { scale: 1.07 }, { scale: 1, duration: 0.28, ease: "power3.out" }, 0);\n` + s.js).split('\n').map(l => '  ' + l).join('\n')}\n  window.__timelines["${s.id}"] = tl;\n})();\n</script>\n</template>\n`);
const hosts = scenes.map(s => `      <div id="${s.id}" data-composition-id="${s.id}" data-composition-src="compositions/${s.id}.html" data-start="${s.start}" data-duration="${s.dur}" data-track-index="0" data-track-kind="graphics" data-width="${W}" data-height="${H}"></div>`).join('\n');
sfx.forEach(e => { if (e.t < 0) e.t = 0; }); sfx.sort((a, b) => a.t - b.t); const ends = []; const lane = (st, d) => { let i = ends.findIndex(e => e <= st + 1e-6); if (i < 0) { i = ends.length; ends.push(0); } ends[i] = st + d; return 12 + i; };
const fx = sfx.map((e, i) => { const [f, d, m] = SFX[e.key]; return `      <audio id="sfx-${i}-${e.key}" class="clip" src="assets/audio/sfx/${f}" data-start="${e.t}" data-duration="${d}"${m ? ` data-media-start="${m}"` : ''} data-volume="${e.vol}" data-track-index="${lane(e.t, d)}"></audio>`; }).join('\n');
vo.sort((a, b) => a.at - b.at);
for (let i = 1; i < vo.length; i++) if (vo[i].at < vo[i - 1].at + vo[i - 1].duration + 0.05) throw new Error(`narration ${vo[i].id} starts before ${vo[i - 1].id} has finished`);
const voice = vo.map(v => `      <audio id="vo-${v.id}" class="clip" src="assets/audio/voice/${v.id}.wav" data-start="${v.at}" data-duration="${v.duration}" data-volume="1" data-track-index="11" data-timeline-role="voice"></audio>`).join('\n');
const music = MUSIC ? `      <audio id="music-bed" class="clip" src="assets/audio/music/${path.basename(MUSIC)}" data-start="0" data-duration="${DUR}" data-volume="0.32" data-track-index="10" data-timeline-role="music"></audio>\n` : '';
fs.writeFileSync(path.join(OUT, 'index.html'), `<!doctype html>
<html lang="en" data-resolution="landscape">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=${W}, height=${H}" />
    <title>Vertex Buddy launch film, version 3</title>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { margin: 0; width: ${W}px; height: ${H}px; overflow: hidden; background: ${NIGHT}; }
    </style>
  </head>
  <body>
    <!-- Generated by video/source/build/launch2.mjs. Edit the builder, then run: video/source/bin/make build -->
    <div id="root" data-composition-id="main" data-start="0" data-duration="${DUR}" data-width="${W}" data-height="${H}">
${hosts}
${music}${voice}
${fx}
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
put('meta.json', J({ id: P, name: 'vertex-buddy-launch-v3', createdAt: '2026-11-21T00:00:00.000Z' }, null, 2) + '\n');
put('package.json', J({ name: P, private: true, type: 'module' }, null, 2) + '\n');
fs.mkdirSync(path.join(VIDEO, 'storyboard'), { recursive: true });
fs.writeFileSync(path.join(VIDEO, `storyboard/timeline-${P}.json`), J({ film: 'Vertex Buddy launch film, version 3', width: W, height: H, fps: 30, bpm: BPM, duration: DUR,
  music: { drive: true, bpm: BPM, open_at: scenes.find(s => s.id === 'c1').start, close_at: scenes.find(s => s.id === 'h').card, file: MUSIC ? path.basename(MUSIC) : null },
  scenes: scenes.map(s => ({ id: s.id, start: s.start, dur: s.dur, beats: s.beats })), vo: vo.map(v => ({ ...v, text: VO.find(l => l.id === v.id).text })), sfx: sfx.map(e => ({ t: e.t, sound: SFX[e.key][0], volume: e.vol })), words: copy }, null, 1));
console.log(`${P}: ${scenes.length} shots | ${DUR} s | narration ${vo.length} lines | sfx ${sfx.length} | music ${MUSIC ? path.basename(MUSIC) : 'none yet'}`);
console.log('  ' + scenes.map(s => `${s.id}@${s.start}`).join(' '));
