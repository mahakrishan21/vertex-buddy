// Vertex Buddy launch film, version 5: "In the loop". 55 s, 16:9. Writes the HyperFrames project in source/launch5/.
// The tagline's loop is the design: a neon ring that starts as you and Claude, multiplies into sessions, breaks when one
// turns pink, and closes again round Vertex. Built on version 4 (typed text, stock footage, gradients, the state close-ups).
// Run: video/source/bin/make build
//
// A clean black, white and neon-green film in the manner of a second reference (docs/reference-skuve.md): typed text with a
// cursor, real footage with type over it, pictures set inside sentences, floating cards, split panels with labels, rows of
// cards, and a mark that builds from dots. The footage of people is free stock (assets/stock/README.md); Vertex and its
// speech bubble are recorded from the app itself. Windows and cards are plain drawings, not a real app.
import fs from 'node:fs'; import path from 'node:path';
import { VIDEO, r3, J, esc, MOOD, CSS, scope, linker, CUR, cp, curTo, tap, popIn, pieceIn, pieceOut, strokes } from './kit.mjs';

const P = 'launch5', OUT = path.join(VIDEO, 'source', P), FOOT = 'footage-launch2';
const W = 1920, H = 1080, BPM = 120, B = 60 / BPM;
const REPO = 'github.com/mahakrishan21/vertex-buddy';
const PAPER = '#F5F5F1', INK = '#121212', ACC = '#39F06A', GREY = 'rgba(18,18,18,.5)';
const asset = linker(OUT);
const VO = JSON.parse(fs.readFileSync(path.join(VIDEO, 'assets/audio/voice', P, 'manifest.json'), 'utf8')).lines;
const voDur = Object.fromEntries(VO.map(l => [l.id, l.duration]));
const SFX = { click: ['click-soft.mp3', 0.37], key: ['key-press.mp3', 0.43], whooshA: ['whoosh-short.mp3', 0.57], whooshB: ['whoosh.mp3', 0.57], pop: ['pop.mp3', 0.72], impact: ['impact-bass-1.mp3', 2.12], riser: ['riser.mp3', 4.0, 0.7] };
const sfx = [], vo = [], copy = [];
// the mix: the hits and risers are loud files, so they are held back and the voice is lifted to stay on top
const GAIN = { impact: 0.5, riser: 0.55, whooshA: 0.8, whooshB: 0.8 }, VOICE = 1.6;
const snd = (t, key, vol) => sfx.push({ t: r3(t), key, vol });
const speak = (t, id) => vo.push({ id, at: r3(t), duration: voDur[id] });
const say = s => { copy.push(s); return s; };

const EXTRA = `
.shot { position: absolute; inset: 0; }
.mesh { position: absolute; inset: 0; overflow: hidden; }
.mesh i { position: absolute; width: 1600px; height: 1600px; margin: -800px 0 0 -800px; border-radius: 50%; }
.flash { position: absolute; inset: 0; background: #FFFFFF; z-index: 90; }
.t { position: absolute; font-weight: 400; letter-spacing: -0.04em; line-height: 1.04; white-space: nowrap; z-index: 20; }
.ch { opacity: 0; border-right: .06em solid transparent; margin-right: -.06em; }
.fv { position: absolute; left: 0; top: 0; width: 100%; height: 100%; object-fit: cover; }
.fw { position: absolute; inset: 0; overflow: hidden; }
.scrim { position: absolute; inset: 0; background: linear-gradient(25deg, #031C10 0%, #0A0A0A 42%, rgba(10,10,30,.25) 100%); z-index: 2; }
.vcard { position: absolute; overflow: hidden; border-radius: 34px; box-shadow: 0 50px 110px -40px rgba(0,0,0,.5); z-index: 5; }
.row { display: flex; align-items: center; gap: 22px; }
.inl { position: relative; width: 196px; height: 112px; border-radius: 56px; overflow: hidden; flex: none; box-shadow: 0 0 0 4px ${INK}; }
.inl img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
.inl i { position: absolute; right: 18px; top: 16px; width: 22px; height: 22px; border-radius: 50%; background: ${ACC}; box-shadow: 0 0 0 4px rgba(0,0,0,.45); }
.sc { position: absolute; width: 330px; height: 215px; border-radius: 20px; background: linear-gradient(150deg, #2A2D36 0%, #15161A 100%); box-shadow: 0 0 0 1.5px rgba(255,255,255,.1), 0 40px 80px -30px #000; z-index: 3; }
.sc b { position: absolute; left: 20px; top: 18px; font-family: "JetBrains Mono", monospace; font-weight: 500; font-size: 22px; color: rgba(255,255,255,.55); }
.sc i { position: absolute; right: 20px; top: 20px; width: 18px; height: 18px; border-radius: 50%; }
.sc u { position: absolute; left: 20px; height: 11px; border-radius: 6px; background: rgba(255,255,255,.16); }
.dots { position: absolute; inset: 0; background-image: radial-gradient(rgba(0,0,0,.55) 3px, transparent 3.6px); background-size: 16px 16px; z-index: 3; }
.pan { position: absolute; top: 0; width: 640px; height: 1080px; overflow: hidden; }
.pan .tint { position: absolute; inset: 0; z-index: 2; }
.lab { position: absolute; z-index: 21; padding: 8px 26px 12px; border-radius: 14px; font-weight: 700; font-size: 58px; letter-spacing: -0.03em; color: ${INK}; white-space: nowrap; }
.pill { position: absolute; z-index: 21; height: 96px; padding: 0 40px; border-radius: 48px; background: linear-gradient(120deg, #121212 0%, #0E4A2E 100%); color: #FFFFFF; display: flex; align-items: center; gap: 16px; font-weight: 700; font-size: 46px; letter-spacing: -0.02em; white-space: nowrap; }
.pill em { color: ${ACC}; font-style: normal; }
.pc { position: absolute; top: 0; width: 300px; height: 300px; border-radius: 30px; overflow: hidden; }
.pc img { position: absolute; left: 0; top: -10px; width: 300px; height: 272px; transform: scale(1.7); transform-origin: 50% 48%; }
.pc .vw { left: 10px; top: 10px; width: 280px; height: 254px; z-index: 1; }
.pc span { position: absolute; left: 14px; bottom: 12px; z-index: 3; padding: 3px 12px; border-radius: 10px; background: rgba(255,255,255,.92); font-size: 28px; color: ${INK}; }
.strip { position: absolute; left: 0; width: 2640px; height: 300px; }
.dot { position: absolute; left: 0; top: 0; width: 44px; height: 44px; margin: -22px 0 0 -22px; border-radius: 50%; z-index: 8; }
.wm { position: absolute; left: 0; right: 0; top: 742px; text-align: center; font-weight: 700; font-size: 86px; letter-spacing: .3em; background: linear-gradient(90deg, ${ACC} 0%, #45D4E8 55%, #A9A4F0 100%); -webkit-background-clip: text; background-clip: text; color: transparent; z-index: 20; white-space: nowrap; }
.cl { position: absolute; left: 0; right: 0; text-align: center; z-index: 20; white-space: nowrap; }
.srow { position: absolute; z-index: 21; display: flex; align-items: center; gap: 16px; padding: 14px 28px; border-radius: 18px; background: #FFFFFF; box-shadow: 0 18px 44px -20px rgba(0,0,0,.4), 0 0 0 1.5px rgba(18,18,18,.06); font-size: 32px; color: #121212; white-space: nowrap; }
.srow i { width: 20px; height: 20px; border-radius: 50%; }
.rsvg { position: absolute; overflow: visible; }
.orb { position: absolute; left: 0; top: 0; width: 250px; height: 250px; margin: -125px 0 0 -125px; border-radius: 50%; overflow: hidden; box-shadow: 0 0 0 7px ${ACC}, 0 0 70px ${ACC}66; z-index: 6; }
.orb img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
.orb.big { width: 360px; height: 360px; margin: -180px 0 0 -180px; box-shadow: 0 0 0 8px #FFFFFF, 0 40px 80px -30px rgba(0,0,0,.45); }
.orb.big .vw { left: 10px; top: 14px; width: 340px; height: 308px; z-index: 1; }
.orb.big span { position: absolute; left: 0; right: 0; bottom: 30px; text-align: center; font-size: 28px; z-index: 3; color: #121212; }
.disc2 { position: absolute; border-radius: 50%; overflow: hidden; z-index: 4; }
.mini { position: absolute; width: 96px; height: 96px; margin: -48px 0 0 -48px; border-radius: 50%; border: 8px solid ${ACC}; z-index: 6; }
.floodc { position: absolute; width: 100px; height: 100px; margin: -50px 0 0 -50px; border-radius: 50%; z-index: 30; }
.cam4 { position: absolute; inset: 0; }
.wheel { position: absolute; width: 120px; height: 120px; border-radius: 50%; box-shadow: inset 0 0 0 3px rgba(18,18,18,.18); z-index: 21; }
.wheel i { position: absolute; width: 22px; height: 22px; margin: -11px 0 0 -11px; border-radius: 50%; box-shadow: 0 0 0 4px rgba(255,255,255,.85); }
.fc { position: absolute; top: 0; width: 170px; height: 170px; border-radius: 50%; overflow: hidden; }
.fc img { position: absolute; left: 0; top: -6px; width: 170px; height: 154px; transform: scale(1.7); transform-origin: 50% 48%; }
.rg { position: absolute; border-radius: 50%; border: 8px solid ${MOOD.needsYou}; z-index: 9; }
`;

// ---- helpers
/** text that types itself, with a cursor bar that travels with the last letter */
function typeOn(id, text, at, { cps = 26, cur = ACC, hold = 0.5, acc = null } = {}) { say(text); let js = ''; const n = text.length, dt = 1 / cps;
  const html = `<span id="${id}">` + [...text].map((c, i) => `<span class="ch" id="${id}-${i}"${acc && i >= acc[0] && i < acc[1] ? ` style="color:${acc[2]}"` : ''}>${c === ' ' ? '&nbsp;' : esc(c)}</span>`).join('') + '</span>';
  for (let i = 0; i < n; i++) { const a = r3(at + i * dt); js += `tl.set("#${id}-${i}", { opacity: 1, borderRightColor: "${cur}" }, ${a});\n` + (i < n - 1 ? `tl.set("#${id}-${i}", { borderRightColor: "transparent" }, ${r3(a + dt)});\n` : `tl.set("#${id}-${i}", { borderRightColor: "transparent" }, ${r3(a + dt + hold)});\n`); }
  return { html, js, end: r3(at + n * dt) }; }
const foot = (id, src, start, dur, media = 0, track = 1) => `<video id="${id}" class="clip fv" src="assets/stock/${src}.mp4" muted playsinline data-start="${start}" data-duration="${dur}"${media ? ` data-media-start="${media}"` : ''} data-track-index="${track}" data-layout-allow-occlusion></video>`;
const buddy = (id, src, start, dur, x, y, w, h, { media = 0, track = 3, z = 6 } = {}) => `<div class="vw" id="${id}w" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px;z-index:${z}" data-layout-allow-occlusion><video id="${id}" class="clip" src="assets/${FOOT}/${src}.webm" muted playsinline data-start="${start}" data-duration="${dur}"${media ? ` data-media-start="${media}"` : ''} data-track-index="${track}" data-layout-allow-occlusion></video></div>`;
const drift = (sel, D, a, b, origin = '50% 50%') => `gsap.set("${sel}", { scale: ${a}, transformOrigin: "${origin}" });\ntl.to("${sel}", { scale: ${b}, duration: ${D}, ease: "none" }, 0);\n`;
const hit = (id, at, amp = 12, op = 0.4) => `tl.to("#${id}-shot", { keyframes: [{ x: ${amp}, y: ${-amp * 0.6} }, { x: ${-amp * 0.8}, y: ${amp * 0.5} }, { x: ${amp * 0.5}, y: ${amp * 0.3} }, { x: 0, y: 0 }], duration: 0.26, ease: "none" }, ${r3(at)});\ntl.fromTo("#${id}-fl", { opacity: ${op} }, { opacity: 0, duration: 0.26, ease: "power2.out", immediateRender: false }, ${r3(at)});\n`;
const glow = (id, x, y, col, op = 1) => `<div class="gl" id="${id}" data-layout-ignore style="left:${x}px;top:${y}px;opacity:${op};background:radial-gradient(circle, ${col}8C 0%, ${col}33 34%, ${col}00 62%)"></div>`;
const mix = (hex, t) => '#' + [1, 3, 5].map(i => Math.round(parseInt(hex.slice(i, i + 2), 16) * (1 - t) + 255 * t).toString(16).padStart(2, '0')).join('');
const NEIGH = { asleep: '#6C8BFF', idle: '#7CF0C0', working: '#D7F25A', done: '#FF8A5A', needsYou: '#B96BFF' };
const MESH = { light: [[280, 180, ACC, '3A'], [1680, 920, MOOD.idle, '40'], [1100, -120, MOOD.asleep, '38'], [700, 1100, MOOD.done, '26']], dark: [[240, 960, '#0F6B3E', 'B0'], [1720, 140, '#22308A', 'A0'], [1050, 560, ACC, '18'], [1500, 1050, '#5B1E6E', '66']] };
const ticks = (T0, a, b, vol = 0.22) => { for (let t = a; t < b; t += 0.32) snd(T0 + t, 'key', vol); };

// ---- the ring: drawn as a stroke that closes, coloured as a gradient
const ringSvg = (id, cx, cy, r, col, w = 14, col2 = '#45D4E8', z = 5) => { const sz = 2 * (r + w), C = r3(2 * Math.PI * r);
  return `<svg class="rsvg" id="${id}" data-layout-ignore style="left:${cx - r - w}px;top:${cy - r - w}px;z-index:${z}" width="${sz}" height="${sz}" viewBox="0 0 ${sz} ${sz}"><defs><linearGradient id="${id}-gr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${col}"/><stop offset="1" stop-color="${col2}"/></linearGradient></defs><circle id="${id}-c" cx="${r + w}" cy="${r + w}" r="${r}" fill="none" stroke="url(#${id}-gr)" stroke-width="${w}" stroke-linecap="round" stroke-dasharray="${C}" stroke-dashoffset="${C}" transform="rotate(-90 ${r + w} ${r + w})"/></svg>`; };
const drawRing = (id, at, dur = 0.7) => `tl.to("#${id}-c", { strokeDashoffset: 0, duration: ${dur}, ease: "power2.inOut" }, ${r3(at)});\n`;
/** move something round an ellipse; nearer the front it grows a little */
function orbit(sel, cx, cy, rx, ry, a0, turn, dur, at = 0, n = 24, depth = 0.18) { const kf = []; for (let i = 1; i <= n; i++) { const a = a0 + turn * i / n; kf.push(`{ x: ${r3(cx + Math.cos(a) * rx)}, y: ${r3(cy + Math.sin(a) * ry)}, scale: ${r3(1 + Math.sin(a) * depth)}, zIndex: ${Math.sin(a) > 0 ? 9 : 4}, duration: ${r3(dur / n)}, ease: "none" }`); }
  return `gsap.set("${sel}", { x: ${r3(cx + Math.cos(a0) * rx)}, y: ${r3(cy + Math.sin(a0) * ry)}, scale: ${r3(1 + Math.sin(a0) * depth)} });\ntl.to("${sel}", { keyframes: [${kf.join(', ')}], ease: "none" }, ${at});\n`; }
const ORDER = ['asleep', 'idle', 'working', 'done', 'needsYou'];
const wheel = (id, n, x, y) => `<div class="wheel" id="${id}-wh" data-layout-ignore style="left:${x}px;top:${y}px">${ORDER.map((m, k) => { const a = -Math.PI / 2 + k * 2 * Math.PI / 5; return `<i style="left:${r3(60 + Math.cos(a) * 60)}px;top:${r3(60 + Math.sin(a) * 60)}px;background:${MOOD[m]};${k === n ? 'width:38px;height:38px;margin:-19px 0 0 -19px' : 'opacity:.45'}"></i>`; }).join('')}</div>`;

const scenes = [];
const add = (id, beats, bg, fn) => { const start = scenes.reduce((a, s) => a + s.beats, 0), T0 = r3(start * B), D = r3(beats * B); scenes.push({ id, beats, bg, start: T0, dur: D, ...fn(T0, D) }); };

// 1. black: a ring closes round real work. You start in the loop
add('r1', 7, INK, (T0, D) => {
  const a = typeOn('r1-a', 'You start', 0.3, { cps: 22, cur: '#FFFFFF', hold: 0 }), b = typeOn('r1-b', 'in the loop.', 1.3, { cps: 18, hold: 1.4 });
  const body = `${ringSvg('r1-ring', 1380, 540, 340, ACC, 16)}<div class="disc2" id="r1-d" style="left:1080px;top:240px;width:600px;height:600px">${foot('r1-v', 'code', 0, D)}</div>
<div class="t" style="left:120px;top:390px;font-size:150px;color:#FFFFFF">${a.html}</div><div class="t" style="left:120px;top:556px;font-size:150px;color:${ACC}">${b.html}</div>`;
  const js = a.js + b.js + drawRing('r1-ring', 0.1, 1.0) + `gsap.set("#r1-d", { scale: 0 });\ntl.to("#r1-d", { scale: 1, duration: 0.55, ease: "back.out(1.5)" }, 0.5);\ntl.to("#r1-d", { scale: 1.06, duration: ${D - 1.1}, ease: "none" }, 1.1);\ntl.to("#r1-ring", { rotation: 40, transformOrigin: "50% 50%", duration: ${D}, ease: "none" }, 0);\n`;
  ticks(T0, 0.3, 0.7); ticks(T0, 1.3, 1.9); snd(T0 + 0.5, 'pop', 0.4); speak(T0 + 0.4, 'n1');
  return { body, js };
});

// 2. black: one ring becomes five, in orbit
add('r2', 6, INK, (T0, D) => {
  const a = typeOn('r2-a', 'Then one becomes', 0.2, { cps: 30, cur: '#FFFFFF', hold: 0 }), b = typeOn('r2-b', 'five.', 1.2, { cps: 12, hold: 1.3 }), PICS = ['code', 'keys', 'desk2', 'desk', 'coffee'];
  const body = PICS.map((p, i) => `<div class="orb" id="r2-o${i}" data-layout-ignore><img src="assets/stock/${p}.jpg" alt=""></div>`).join('') + `<div class="t" style="left:120px;top:410px;font-size:96px;color:#FFFFFF">${a.html}</div><div class="t" style="left:120px;top:520px;font-size:230px;color:${ACC}">${b.html}</div>`;
  let js = a.js + b.js; PICS.forEach((p, i) => { const at = i === 0 ? 0 : r3(0.45 + i * 0.2); js += orbit('#r2-o' + i, 1450, 540, 330, 270, -Math.PI / 2 + i * 2 * Math.PI / 5, 1.5, D) + `gsap.set("#r2-o${i}", { opacity: 0 });\ntl.to("#r2-o${i}", { opacity: 1, duration: 0.18 }, ${at});\n`; if (i) snd(T0 + at, 'pop', 0.34); });
  ticks(T0, 0.2, 0.75); snd(T0 - 0.05, 'whooshA', 0.4); speak(T0 + 0.3, 'n2');
  return { body, js };
});

// 3. footage: you hand it over, and get on with your day
add('s3', 6, INK, (T0, D) => {
  const a = typeOn('s3-a', 'You hand them off', 0.15, { cps: 28, hold: 0.2 }), b = typeOn('s3-b', 'and step away.', 1.6, { cps: 30, hold: 0.8 });
  const body = `<div class="fw" id="s3-f1">${foot('s3-v1', 'desk', 0, 1.5)}</div><div class="fw" id="s3-f2">${foot('s3-v2', 'coffee', 1.5, r3(D - 1.5), 0, 2)}</div><div class="scrim" style="opacity:.6"></div>
<div class="t" id="s3-ta" style="left:120px;top:800px;font-size:118px;color:#FFFFFF">${a.html}</div><div class="t" id="s3-tb" style="left:120px;top:800px;font-size:118px;color:#FFFFFF">${b.html}</div>`;
  const js = drift('#s3-f1', 1.5, 1.0, 1.08) + `gsap.set("#s3-f2", { scale: 1.1, transformOrigin: "50% 50%" });\ntl.to("#s3-f2", { scale: 1, duration: ${r3(D - 1.5)}, ease: "none" }, 1.5);\ntl.set("#s3-ta", { opacity: 0 }, 1.5);\n` + a.js + b.js;
  ticks(T0, 0.15, 0.8); ticks(T0, 1.6, 2.4); snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + 1.5, 'whooshB', 0.35); speak(T0 + 0.3, 'v2');
  return { body, js };
});

// 4. black: five small rings. One turns pink, and we fall into it
add('r4', 8, INK, (T0, D) => {
  const a = typeOn('r4-a', 'One of them stops.', 0.3, { cps: 26, cur: '#FFFFFF', hold: 0.2 }), b = typeOn('r4-b', 'It needs you.', 1.9, { cps: 16, cur: MOOD.needsYou, hold: 0.6 });
  const XS = [1100, 1270, 1440, 1610, 1780], PICK = 3, PX = XS[PICK], PY = 330, STOP = 0.9, DIVE = r3(D - 1.0);
  const body = `<div class="cam4" id="r4-cam" data-layout-ignore>${XS.map((x, i) => `<i class="mini" id="r4-n${i}" style="left:${x}px;top:${PY}px"></i>`).join('')}<div class="rg" id="r4-rg" style="left:${PX - 110}px;top:${PY - 110}px;width:220px;height:220px"></div><div class="floodc" id="r4-fill" style="left:${PX}px;top:${PY}px;background:${PAPER}"></div></div>
<div id="r4-words"><div class="t" style="left:120px;top:400px;font-size:120px;color:#FFFFFF">${a.html}</div><div class="t" style="left:120px;top:540px;font-size:170px;color:${MOOD.needsYou}">${b.html}</div></div>`;
  let js = a.js + b.js + XS.map((x, i) => `tl.fromTo("#r4-n${i}", { y: ${i % 2 ? 14 : -14} }, { y: ${i % 2 ? -14 : 14}, duration: ${D}, ease: "sine.inOut" }, 0);\n` + (i === PICK ? `tl.set("#r4-n${i}", { borderColor: "${MOOD.needsYou}" }, ${STOP});\ntl.to("#r4-n${i}", { scale: 1.5, duration: 0.3, ease: "back.out(2)" }, ${STOP});\n` : `tl.to("#r4-n${i}", { opacity: 0.25, duration: 0.3 }, ${STOP});\n`)).join('');
  js += `gsap.set("#r4-rg", { opacity: 0, scale: 0.3 });\ngsap.set("#r4-fill", { scale: 0 });\n` + [STOP, STOP + 0.8, STOP + 1.6].map(t => `tl.fromTo("#r4-rg", { opacity: 0.9, scale: 0.3 }, { opacity: 0, scale: 1.8, duration: 0.75, ease: "power2.out", immediateRender: false }, ${r3(t)});\n`).join('') + hit('r4', STOP, 14, 0.35);
  js += `tl.to("#r4-words", { opacity: 0, duration: 0.2 }, ${DIVE});\ntl.to("#r4-cam", { scale: 3.4, transformOrigin: "${PX}px ${PY}px", duration: 1.0, ease: "power3.in" }, ${DIVE});\ntl.to("#r4-fill", { scale: 16, duration: 0.5, ease: "power2.in" }, ${r3(D - 0.5)});\n`;
  ticks(T0, 0.3, 0.9); snd(T0 - 0.05, 'whooshB', 0.4); snd(T0 + STOP, 'impact', 0.6); snd(T0 + D - 4.0, 'riser', 0.34); speak(T0 + 0.3, 'n4');
  return { body, js };
});

// 7. white: Vertex drops in. The app's own picked-up pose and landing
add('s7', 6, PAPER, (T0, D) => {
  const LAND = 0.42, a = typeOn('s7-a', 'Vertex Buddy', 0.55, { cps: 20, hold: 0.6 }), b = typeOn('s7-b', 'a little companion for Claude Code', 1.5, { cps: 40, hold: 0.4 });
  const body = `${ringSvg('s7-ring', 960, 660, 440, ACC, 18, MOOD.idle, 3)}${glow('s7-g', 960, 690, MOOD.idle)}<div class="t cl" style="top:44px;font-size:200px">${a.html}</div><div class="t cl" style="top:262px;font-size:52px;color:${GREY}">${b.html}</div>${buddy('s7-v', 'hero', 0, D, 500, 245, 920, 834)}`;
  let js = drawRing('s7-ring', LAND, 0.7) + a.js + b.js + `gsap.set("#s7-g", { scale: 0.3, opacity: 0 });\ntl.to("#s7-g", { scale: 1, opacity: 1, duration: 0.5, ease: "power3.out" }, ${LAND});\ngsap.set("#s7-vw", { y: -1150, transformOrigin: "50% 92%" });\ntl.to("#s7-vw", { y: 0, duration: ${LAND - 0.02}, ease: "power2.in" }, 0.02);\ntl.to("#s7-vw", { scale: 1.06, duration: ${D - LAND}, ease: "none" }, ${LAND});\n` + hit('s7', LAND, 20, 0.55);
  snd(T0 + LAND, 'pop', 0.65); snd(T0 + LAND - 0.02, 'impact', 0.55); ticks(T0, 0.55, 1.1); speak(T0 + 0.5, 'v5');
  return { body, js };
});

// 8. footage with Vertex over it: above every app
add('s8', 8, INK, (T0, D) => {
  const a = typeOn('s8-a', 'above every app', 0.3, { cps: 22, hold: 0.3 }), b = typeOn('s8-b', 'on your Mac', 1.3, { cps: 26, hold: 1.5 });
  const body = `<div class="fw" id="s8-f">${foot('s8-v', 'code', 0, D, 2.6)}</div><div class="scrim" style="opacity:.58"></div>${glow('s8-g', 1490, 760, MOOD.idle, 0.7)}${buddy('s8-b0', 'desk', 0, D, 1130, 400, 720, 652)}
<div class="t" style="left:120px;top:380px;font-size:150px;color:#FFFFFF">${a.html}</div><div class="t" style="left:126px;top:560px;font-size:84px;color:rgba(255,255,255,.7)">${b.html}</div>`;
  const js = drift('#s8-f', D, 1.0, 1.1, '30% 40%') + a.js + b.js + popIn('#s8-b0w', 0.1, 0.6);
  ticks(T0, 0.3, 1.0); snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + 0.1, 'pop', 0.4); speak(T0 + 0.2, 'v6');
  return { body, js };
});

// 9b. how it acts for each session, close up: the app's own behaviour for each state
const STATES = [['x1', 'asleep', 'st-sleep', 'no sessions', 'it sleeps.', 0], ['x2', 'idle', 'st-look', 'website · Idle', 'it looks around.', 1], ['x3', 'working', 'st-work', 'api · Working…', 'it types along.', 0],
  ['x4', 'done', 'st-turn', 'website · Finished, your turn', 'it smiles and waves.', 1], ['x5', 'needsYou', 'st-needs', 'api · Needs you: Bash(npm test)', 'it hops and chimes.', 0]];
STATES.forEach(([id, mood, tk, rowText, lineText, left], n) => add(id, 5, PAPER, (T0, D) => {
  const a = typeOn(id + '-a', lineText, 0.4, { cps: 24, cur: MOOD[mood], hold: 1.2 }), vx = left ? -80 : 790, tx = left ? 1030 : 120;
  const body = `${glow(id + '-g', vx + 600, 640, MOOD[mood])}${ringSvg(id + '-ring', vx + 600, 590, 500, '#FFFFFF', 30, NEIGH[mood], 5)}${wheel(id, n, tx, 600)}${buddy(id + '-v', tk, 0, D, vx, 30, 1200, 1088)}<div class="t" style="left:${tx}px;top:250px;font-size:40px;color:${GREY}">${say(String(n + 1).padStart(2, '0') + ' / 05')}</div>
<div class="srow mono" id="${id}-r" style="left:${tx}px;top:330px"><i style="background:${MOOD[mood]}"></i>${say(rowText)}</div><div class="t" style="left:${tx}px;top:440px;font-size:${lineText.length > 16 ? 84 : 118}px">${a.html}</div>`;
  const js = drawRing(id + '-ring', 0.05, 0.8) + popIn('#' + id + '-wh', 0.2, 0.5) + a.js + popIn('#' + id + '-r', 0.12, 0.6) + `gsap.set("#${id}-vw", { scale: 1.14, transformOrigin: "50% 60%" });\ntl.to("#${id}-vw", { scale: 1, duration: 0.3, ease: "power3.out" }, 0);\ntl.to("#${id}-vw", { scale: 1.06, duration: ${D - 0.3}, ease: "none" }, 0.3);\n` + hit(id, 0.02, 10, 0.3);
  ticks(T0, 0.4, 1.0); snd(T0 - 0.04, n % 2 ? 'whooshB' : 'whooshA', 0.45); snd(T0 + 0.12, 'pop', 0.4); if (mood === 'needsYou') snd(T0, 'impact', 0.4); speak(T0 + 0.3, id);
  return { body, js, bg: mix(MOOD[mood], 0.5), mesh: [[vx + 600, 620, MOOD[mood], 'F2'], [left ? 1560 : 300, 120, NEIGH[mood], 'C8'], [left ? 1750 : 160, 1020, '#FFFFFF', 'D0'], [left ? 1000 : 900, 1150, NEIGH[mood], '70']] };
}));

// 10. white: the real bubble, close. Hover, then click
add('s10', 8, PAPER, (T0, D) => {
  const a = typeOn('s10-a', 'every session', 0.25, { cps: 24, hold: 0.3 }), b = typeOn('s10-b', 'click to jump in', 2.0, { cps: 28, hold: 1 }), CLICK = 2.6;
  const body = `${glow('s10-g', 1260, 900, MOOD.needsYou)}${buddy('s10-v', 'demo', 0, D, 900, 590, 720, 652)}
<div class="bub clip" id="s10-b0" style="left:710px;top:-6px;width:1100px;height:842px" data-start="0.2" data-duration="${r3(D - 0.2)}" data-track-index="2" data-layout-allow-occlusion><img id="s10-bi" src="assets/${FOOT}/bubble-needs.png" alt=""></div>
<div class="rg" id="s10-rg" style="left:816px;top:240px;width:888px;height:146px;border-radius:34px;border-width:7px" data-layout-ignore></div>
<div class="t" style="left:120px;top:370px;font-size:98px">${a.html}</div><div class="t" style="left:124px;top:490px;font-size:60px;color:${GREY}">${b.html}</div>${CUR('s10-cur')}`;
  let js = a.js + b.js + `tl.fromTo("#s10-bi", { scale: 0.5, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.32, ease: "back.out(1.5)" }, 0.2);\n`;
  js += `gsap.set("#s10-cur", ${J(cp(2050, 1130))});\n` + curTo('s10-cur', 1340, 560, 0.3, 0.7) + curTo('s10-cur', 1500, 320, 1.9, 0.55, 'power3.inOut') + tap('s10-cur', CLICK);
  js += `gsap.set("#s10-rg", { opacity: 0 });\ntl.fromTo("#s10-rg", { scale: 1.14, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.2, ease: "power4.out", immediateRender: false }, ${CLICK});\ntl.to("#s10-rg", { opacity: 0, duration: 0.4 }, ${CLICK + 0.5});\n` + hit('s10', CLICK, 8, 0.25);
  ticks(T0, 0.25, 0.8); snd(T0 - 0.05, 'whooshB', 0.4); snd(T0 + 0.2, 'pop', 0.45); snd(T0 + CLICK, 'click', 0.85); speak(T0 + 0.3, 'v8');
  return { body, js };
});

// 11. white: a carousel. Four characters orbit; twelve faces run underneath
add('r8', 8, PAPER, (T0, D) => {
  const CAST = [['cloud', 'Cloud Vertex', '#DDEBFF'], ['pixel', 'Pixel Vertex', '#E6E0FF'], ['robo', 'Robo Vertex', '#D9F3E5'], ['cozy', 'Cozy Vertex', '#FFEFC9']];
  const FACES = ['neutral', 'happy', 'excited', 'curious', 'confused', 'sleepy', 'surprised', 'playful', 'focused', 'worried', 'pondering', 'sneaky'], TINT = ['#D8F7E4', '#DCE9FF'];
  const PILLS = [['4', 'characters', 120, 0.3], ['9', 'behaviours', 620, 1.3], ['12', 'faces', 1130, 2.3]];
  let body = ringSvg('r8-ring', 960, 500, 640, ACC, 5, '#A9A4F0', 2) + CAST.map(([k, name, col], i) => `<div class="orb big" id="r8-c${i}" style="background:linear-gradient(160deg, ${col} 0%, #FFFFFF 120%)" data-layout-ignore><div class="vw" data-layout-allow-occlusion><video id="r8-${k}" class="clip" src="assets/${FOOT}/cast-${k}.webm" muted playsinline data-start="0" data-duration="${Math.min(D, 4.1)}" data-track-index="${1 + i}" data-layout-allow-occlusion></video></div><span class="mono">${say(name)}</span></div>`).join('');
  body += `<div class="strip" id="r8-f" style="top:850px;height:170px" data-layout-ignore>${FACES.map((f, i) => `<div class="fc" style="left:${i * 205}px;background:linear-gradient(160deg, ${TINT[i % 2]} 0%, #FFFFFF 100%)"><img src="assets/${FOOT}/faces/${f}.png" alt=""></div>`).join('')}</div>` + PILLS.map(([n, w, x], i) => `<div class="pill" id="r8-p${i}" style="left:${x}px;top:70px"><em>${n}</em>${say(w)}</div>`).join('');
  let js = `gsap.set("#r8-ring", { scaleY: 0.234, transformOrigin: "50% 50%" });\n` + drawRing('r8-ring', 0, 0.8) + CAST.map((c, i) => orbit('#r8-c' + i, 960, 500, 640, 150, Math.PI / 2 + i * Math.PI / 2, -Math.PI, D, 0, 24, 0.34)).join('');
  js += `tl.fromTo("#r8-f", { x: 300 }, { x: -620, duration: ${D}, ease: "none" }, 0);\n` + PILLS.map(([, , , at], i) => popIn('#r8-p' + i, at, 0.5)).join('');
  PILLS.forEach(([, , , at]) => snd(T0 + at, 'pop', 0.42)); snd(T0 - 0.05, 'whooshA', 0.4); speak(T0 + 0.25, 'v9');
  return { body, js };
});

// 12. black: three promises, typed
add('s12', 8, INK, (T0, D) => {
  const LINES = [['No hooks.', 0.3], ['No settings to change.', 1.25], ['Nothing leaves your Mac.', 2.4]].map(([t, at], i) => ({ at, ...typeOn('s12-l' + i, t, at, { cps: 30, cur: ACC, hold: i === 2 ? 1.2 : 0.2 }) }));
  const body = `${glow('s12-g', 1500, 720, MOOD.idle, 0.4)}${buddy('s12-v', 'trust', 0, D, 1140, 350, 720, 652)}` + LINES.map((l, i) => `<div class="t" style="left:120px;top:${330 + i * 140}px;font-size:104px;color:#FFFFFF"><span id="s12-d${i}" style="display:inline-block;width:26px;height:26px;border-radius:50%;background:${ACC};margin-right:30px;vertical-align:middle"></span>${l.html}</div>`).join('');
  let js = LINES.map((l, i) => l.js + popIn('#s12-d' + i, l.at, 0.2)).join('') + popIn('#s12-vw', 0.05, 0.7);
  LINES.forEach(l => ticks(T0, l.at, l.at + 0.6, 0.26)); snd(T0 - 0.05, 'whooshB', 0.4); speak(T0 + 0.3, 'v10');
  return { body, js };
});

// 13. black: five status lights gather into the mark
add('s13', 20, INK, (T0, D) => {
  const MEET = 1.4, COLS = [MOOD.asleep, MOOD.idle, MOOD.working, MOOD.done, MOOD.needsYou];
  const a = typeOn('s13-a', 'Claude does the work.', MEET + 0.5, { cps: 30, cur: ACC, hold: 0 }), b = typeOn('s13-b', 'Vertex keeps you in the loop.', MEET + 1.5, { cps: 30, cur: ACC, hold: 0.6, acc: [23, 28, ACC] });
  const body = `<div id="s13-orb" style="position:absolute;left:960px;top:430px;width:0;height:0" data-layout-ignore>${COLS.map((c, i) => `<i class="dot" id="s13-o${i}" style="background:${c}"></i>`).join('')}</div>
${ringSvg('s13-ring', 960, 392, 330, ACC, 14, '#A9A4F0', 3)}${glow('s13-g', 960, 470, MOOD.working, 0.8)}${buddy('s13-v', 'end', MEET, r3(D - MEET), 600, 70, 720, 652, { media: 2.2 })}<div class="wm" id="s13-wm">${say('VERTEX BUDDY')}</div>
<div class="t cl" style="top:862px;font-size:44px;color:rgba(255,255,255,.6)">${a.html}</div><div class="t cl" style="top:916px;font-size:44px;color:#FFFFFF">${b.html}</div>
<div class="cl mono" id="s13-u" style="top:990px;font-size:30px;color:rgba(255,255,255,.62)">${REPO} · ${say('an independent project, not made by Anthropic')}</div>`;
  let js = COLS.map((c, i) => { const ang = i / 5 * Math.PI * 2; return `gsap.set("#s13-o${i}", { x: ${r3(Math.cos(ang) * 620)}, y: ${r3(Math.sin(ang) * 380)}, scale: 0 });\ntl.to("#s13-o${i}", { scale: 1, duration: 0.25, ease: "back.out(2)" }, ${r3(0.05 + i * 0.08)});\ntl.to("#s13-o${i}", { x: 0, y: 0, duration: ${r3(MEET - 0.3 - i * 0.04)}, ease: "power3.in" }, ${r3(0.3 + i * 0.04)});\ntl.set("#s13-o${i}", { opacity: 0 }, ${MEET});\n`; }).join('');
  js += `tl.to("#s13-orb", { rotation: 300, duration: ${MEET}, ease: "power2.in" }, 0);\ngsap.set("#s13-g", { opacity: 0, scale: 0.2 });\ntl.to("#s13-g", { opacity: 0.8, scale: 1, duration: 0.5, ease: "power3.out" }, ${MEET});\n`;
  js += drawRing('s13-ring', MEET, 0.9) + `gsap.set("#s13-vw", { scale: 0.3, opacity: 0, transformOrigin: "50% 80%" });\ntl.set("#s13-vw", { opacity: 1 }, ${MEET});\ntl.to("#s13-vw", { scale: 1, duration: 0.45, ease: "back.out(1.6)" }, ${MEET});\n` + hit('s13', MEET, 16, 0.5);
  js += `gsap.set("#s13-wm", { opacity: 0, scaleX: 1.6 });\ntl.to("#s13-wm", { opacity: 1, scaleX: 1, duration: 0.6, ease: "power3.out" }, ${MEET + 0.15});\n` + a.js + b.js + `gsap.set("#s13-u", { opacity: 0 });\ntl.set("#s13-u", { opacity: 1 }, ${MEET + 2.7});\ntl.fromTo("#s13-u", { y: 26 }, { y: 0, duration: 0.24, ease: "power4.out", immediateRender: false }, ${MEET + 2.7});\n`;
  snd(T0 - 0.05, 'whooshA', 0.4); snd(T0 + MEET - 4.0, 'riser', 0.3); snd(T0 + MEET - 0.02, 'impact', 0.7); snd(T0 + MEET, 'pop', 0.6); ticks(T0, MEET + 0.5, MEET + 1.1); ticks(T0, MEET + 1.5, MEET + 2.3); speak(T0 + MEET + 0.55, 'v11');
  return { body, js, card: r3(T0 + MEET) };
});

// ================= write the project =================
fs.mkdirSync(path.join(OUT, 'compositions'), { recursive: true });
const FDIR = path.join(VIDEO, 'assets', FOOT), SDIR = path.join(VIDEO, 'assets/stock/prepared');
for (const f of fs.readdirSync(FDIR)) { if (/\.(webm|png)$/.test(f)) asset(path.join(FDIR, f), `${FOOT}/${f}`); }
for (const f of fs.readdirSync(path.join(FDIR, 'faces'))) asset(path.join(FDIR, 'faces', f), `${FOOT}/faces/${f}`);
for (const f of fs.readdirSync(SDIR)) asset(path.join(SDIR, f), 'stock/' + f);
for (const [f] of Object.values(SFX)) asset(path.join(VIDEO, 'assets/audio/sfx', f), 'audio/sfx/' + f);
for (const f of ['jetbrains-mono-var-latin.woff2', 'OFL.txt']) asset(path.join(VIDEO, 'assets/fonts', f), 'fonts/' + f);
for (const l of VO) asset(path.join(VIDEO, l.file), `audio/voice/${l.id}.wav`);
const MUSIC = [P + '.mp3', P + '.wav', P + '-bed.wav'].map(f => path.join(VIDEO, 'assets/audio/music', f)).find(f => fs.existsSync(f));
if (MUSIC) asset(MUSIC, 'audio/music/' + path.basename(MUSIC));

const DUR = r3(scenes.reduce((a, s) => a + s.beats, 0) * B);
const pre = s => [0, 1, 2, 3].map(i => `tl.fromTo("#${s.id}-m${i}", { x: ${i % 2 ? 150 : -170}, y: ${i % 2 ? -70 : 90} }, { x: ${i % 2 ? -160 : 180}, y: ${i % 2 ? 80 : -60}, duration: ${s.dur}, ease: "sine.inOut" }, 0);\n`).join('') + `gsap.set("#${s.id}-fl", { opacity: 0 });\ntl.fromTo("#${s.id}-shot", { scale: 1.05 }, { scale: 1, duration: 0.26, ease: "power3.out" }, 0);\n`;
for (const s of scenes) fs.writeFileSync(path.join(OUT, 'compositions', s.id + '.html'),
  `<template>\n<style>\n${scope(CSS + EXTRA)}\n#root { background: ${s.bg}; color: ${INK}; }\n</style>\n<div id="root" data-composition-id="${s.id}" data-width="${W}" data-height="${H}">\n<div class="mesh" data-layout-ignore>${(s.mesh || (s.bg === INK ? MESH.dark : MESH.light)).map(([x, y, c, a], i) => `<i id="${s.id}-m${i}" style="left:${x}px;top:${y}px;background:radial-gradient(circle, ${c}${a} 0%, ${c}00 66%)"></i>`).join('')}</div><div class="shot" id="${s.id}-shot">\n${s.body}\n</div><div class="flash" id="${s.id}-fl" data-layout-ignore></div>\n</div>\n<script>\n(function () {\n  const tl = gsap.timeline({ paused: true });\n${(pre(s) + s.js).split('\n').map(l => '  ' + l).join('\n')}\n  window.__timelines["${s.id}"] = tl;\n})();\n</script>\n</template>\n`);
const hosts = scenes.map(s => `      <div id="${s.id}" data-composition-id="${s.id}" data-composition-src="compositions/${s.id}.html" data-start="${s.start}" data-duration="${s.dur}" data-track-index="0" data-track-kind="graphics" data-width="${W}" data-height="${H}"></div>`).join('\n');
sfx.forEach(e => { if (e.t < 0) e.t = 0; }); sfx.sort((a, b) => a.t - b.t); const ends = []; const lane = (st, d) => { let i = ends.findIndex(e => e <= st + 1e-6); if (i < 0) { i = ends.length; ends.push(0); } ends[i] = st + d; return 12 + i; };
const fx = sfx.map((e, i) => { const [f, d, m] = SFX[e.key]; return `      <audio id="sfx-${i}-${e.key}" class="clip" src="assets/audio/sfx/${f}" data-start="${e.t}" data-duration="${d}"${m ? ` data-media-start="${m}"` : ''} data-volume="${r3(e.vol * (GAIN[e.key] || 1))}" data-track-index="${lane(e.t, d)}"></audio>`; }).join('\n');
vo.sort((a, b) => a.at - b.at);
for (let i = 1; i < vo.length; i++) if (vo[i].at < vo[i - 1].at + vo[i - 1].duration + 0.05) throw new Error(`narration ${vo[i].id} starts before ${vo[i - 1].id} has finished`);
const voice = vo.map(v => `      <audio id="vo-${v.id}" class="clip" src="assets/audio/voice/${v.id}.wav" data-start="${v.at}" data-duration="${v.duration}" data-volume="${VOICE}" data-track-index="11" data-timeline-role="voice"></audio>`).join('\n');
const music = MUSIC ? `      <audio id="music-bed" class="clip" src="assets/audio/music/${path.basename(MUSIC)}" data-start="0" data-duration="${DUR}" data-volume="0.3" data-track-index="10" data-timeline-role="music"></audio>\n` : '';
fs.writeFileSync(path.join(OUT, 'index.html'), `<!doctype html>
<html lang="en" data-resolution="landscape">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=${W}, height=${H}" />
    <title>Vertex Buddy launch film, version 5</title>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { margin: 0; width: ${W}px; height: ${H}px; overflow: hidden; background: ${INK}; }
    </style>
  </head>
  <body>
    <!-- Generated by video/source/build/launch5.mjs. Edit the builder, then run: video/source/bin/make build -->
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
put('meta.json', J({ id: P, name: 'vertex-buddy-launch-v5', createdAt: '2026-11-22T00:00:00.000Z' }, null, 2) + '\n');
put('package.json', J({ name: P, private: true, type: 'module' }, null, 2) + '\n');
fs.writeFileSync(path.join(VIDEO, `storyboard/timeline-${P}.json`), J({ film: 'Vertex Buddy launch film, version 5', width: W, height: H, fps: 30, bpm: BPM, duration: DUR,
  music: { drive: true, drama: true, break_at: scenes.find(s => s.id === 's12').start, bpm: BPM, open_at: scenes.find(s => s.id === 's7').start, close_at: scenes.find(s => s.id === 's13').card, file: MUSIC ? path.basename(MUSIC) : null },
  scenes: scenes.map(s => ({ id: s.id, start: s.start, dur: s.dur, beats: s.beats })), vo: vo.map(v => ({ ...v, text: VO.find(l => l.id === v.id).text })), sfx: sfx.map(e => ({ t: e.t, sound: SFX[e.key][0], volume: e.vol })), words: copy }, null, 1));
console.log(`${P}: ${scenes.length} shots | ${DUR} s | narration ${vo.length} lines | sfx ${sfx.length} | music ${MUSIC ? path.basename(MUSIC) : 'none yet'}`);
console.log('  ' + scenes.map(s => `${s.id}@${s.start}`).join(' '));
