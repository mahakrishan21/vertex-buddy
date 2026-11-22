// Vertex Buddy launch film, 55 s, 16:9. Writes the HyperFrames project in source/launch/.
// Run: video/source/bin/make build
//
// The words are the creative brief's of 2026-11-21 (listed in storyboard/timeline-launch.json, "words"). Vertex and its speech bubble are recorded from the app itself
// (bin/make footage). The windows behind it are plain drawings, not any real app. Narration, music and effects are placed here.
import fs from 'node:fs'; import path from 'node:path';
import { VIDEO, r3, J, MOOD, GROUND, INK, SOFT, NIGHT, CSS, scope, take, linker, CUR, cp, curTo, tap, line, wfIn, cutOut, cutIn, pieceIn, pieceOut, popIn, glows, strokes, code, win, cards, vertex } from './kit.mjs';

const P = 'launch', OUT = path.join(VIDEO, 'source', P), FOOT = 'footage-launch';
const W = 1920, H = 1080, BPM = 120, B = 60 / BPM;
const REPO = 'github.com/mahakrishan21/vertex-buddy';
const asset = linker(OUT);
const VO = JSON.parse(fs.readFileSync(path.join(VIDEO, 'assets/audio/voice/launch/manifest.json'), 'utf8')).lines;
const voDur = Object.fromEntries(VO.map(l => [l.id, l.duration]));

const SFX = { click: ['click-soft.mp3', 0.37], whooshA: ['whoosh-short.mp3', 0.57], whooshB: ['whoosh.mp3', 0.57], pop: ['pop.mp3', 0.72], impact: ['impact-bass-1.mp3', 2.12] };
const sfx = [], vo = [], copy = [];
const snd = (t, key, vol) => sfx.push({ t: r3(t), key, vol });
const speak = (t, id) => vo.push({ id, at: r3(t), duration: voDur[id] });
const txt = s => { copy.push(s); return s; };
const T = (...rws) => { txt(rws.join(' ')); return rws; };   // a line, given as its rows

const EXTRA = `
#root.night, .night { background: ${NIGHT}; }
.flash { position: absolute; inset: 0; background: #FFFFFF; z-index: 60; }
.veil { position: absolute; inset: 0; background: ${NIGHT}; z-index: 5; }
.stage { position: absolute; inset: 0; }
.dots { position: absolute; left: 124px; top: 952px; display: flex; gap: 22px; z-index: 20; }
.dots i { width: 30px; height: 30px; border-radius: 50%; box-shadow: 0 0 0 5px rgba(255,255,255,.8); }
.call { position: absolute; left: 1266px; top: 196px; width: 490px; height: 82px; border: 6px solid ${MOOD.needsYou}; border-radius: 22px; z-index: 9; }
.nm { position: absolute; top: 816px; width: 520px; text-align: center; z-index: 20; font-size: 31px; }
.chips { position: absolute; left: 0; right: 0; top: 968px; display: flex; justify-content: center; gap: 30px; z-index: 20; font-size: 28px; }
.chips span { position: relative; padding-bottom: 12px; }
.chips i { position: absolute; left: 0; right: 0; bottom: 0; height: 6px; border-radius: 3px; background: ${INK}; }
.face { position: absolute; width: 280px; height: 254px; z-index: 6; }
.face div { position: absolute; left: 0; top: 0; width: 280px; height: 226px; overflow: hidden; border-radius: 28px; background: rgba(255,255,255,.7); }
.face img { position: absolute; left: 0; top: -14px; width: 280px; height: 254px; transform: scale(1.62); transform-origin: 50% 48%; }
.face span { position: absolute; left: 0; right: 0; top: 238px; text-align: center; font-size: 28px; }
.mark { position: absolute; left: 900px; top: 300px; z-index: 20; font-weight: 900; font-size: 124px; letter-spacing: -0.04em; line-height: 1; white-space: nowrap; }
.url { position: absolute; left: 904px; top: 716px; z-index: 20; font-size: 36px; }
.indie { position: absolute; left: 904px; top: 784px; z-index: 20; font-size: 28px; font-weight: 500; }
`;

const scenes = [];
const add = (id, beats, fn) => { const start = scenes.reduce((a, s) => a + s.beats, 0); scenes.push({ id, beats, start: r3(start * B), dur: r3(beats * B), ...fn(r3(start * B), r3(beats * B)) }); };

// ================= 1. the problem (0–9): Claude works, you look away, and then it needs you =================
add('problem', 18, (T0, D) => {
  const p1 = line('p1', T('CLAUDE IS', 'WORKING.'), { color: '#FFFFFF', width: 1000, cap: 180 });
  const p2 = line('p2', T("YOU'RE DOING", 'SOMETHING ELSE.'), { color: '#FFFFFF', width: 840, cap: 180 });
  const p3 = line('p3', T('AND THEN...'), { color: 'rgba(255,255,255,.7)', width: 860, cap: 110 });
  const p4 = line('p4', T('IT NEEDS', 'YOU.'), { color: MOOD.needsYou, width: 860, cap: 190 });
  const FREEZE = 7.0;
  const A = { x: 1080, y: 60, w: 700, h: 420 }, Bw = { x: 1300, y: 660, w: 540, h: 360 }, C = { x: 900, y: 720, w: 360, h: 300 }, Dw = { x: 1000, y: 130, w: 780, h: 500 };
  let body = `<div class="stage" id="p-stage" data-layout-ignore>
${win('p-a', 'website', code('p-ca', 5, 14), { ...A, cls: 'dark', z: 1 })}
${win('p-c', 'docs', code('p-cc', 9, 8, 0.6), { ...C, cls: 'dark', z: 1 })}
${win('p-b', 'api', code('p-cb', 3, 9, 0.9), { ...Bw, cls: 'dark', z: 2, dot: `<em><i id="p-bok" style="background:${MOOD.working}"></i><i id="p-bno" style="background:${MOOD.needsYou}"></i></em>` })}
${win('p-d', 'notes', cards('p-k', 350, 326), { ...Dw, cls: 'warm', z: 3 })}
<div class="veil" id="p-veil"></div>
<div class="rip" id="p-rip"></div>
</div>
${p1.html}${p2.html}${p3.html}${p4.html}<div class="flash" id="p-flash" data-layout-ignore></div>`;
  let js = `gsap.set("#p-veil", { opacity: 0 });\ngsap.set("#p-flash", { opacity: 0 });\ngsap.set("#p-bno", { opacity: 0 });\ngsap.set("#root .code u", { scaleX: 0 });\n`;
  // three sessions typing; "api" stops first, and everything holds still at the freeze
  const typing = (cid, seed, n, from, every, until) => strokes(seed, n).map((s, i) => { const a = from + i * every; return a < until ? `tl.to("#${cid}-${i}", { scaleX: 1, duration: 0.22, ease: "power2.out" }, ${r3(a)});\n` : ''; }).join('');
  js += typing('p-ca', 5, 14, 0.1, 0.46, FREEZE - 0.3) + typing('p-cc', 9, 8, 0.3, 0.78, FREEZE - 0.3) + typing('p-cb', 3, 9, 0.2, 0.62, 5.2);
  js += lineIn(p1, 0, true) + lineOut(p1, 2.72); speak(T0 + 0.3, 'v01');
  // you switch to something else: another app slides over the sessions and they fall back
  js += lineIn(p2, 2.92) + lineOut(p2, 5.42); speak(T0 + 3.0, 'v02');
  js += pieceIn('#p-d', 2.9) + `tl.to("#p-a, #p-b, #p-c", { opacity: 0.55, duration: 0.4, ease: "power2.out" }, 2.9);\n`;
  // and then: the stopped session turns pink behind the app you are in
  js += lineIn(p3, 5.62) + lineOut(p3, 6.7); speak(T0 + 5.75, 'v03');
  js += `tl.to("#p-bok", { opacity: 0, duration: 0.15 }, 5.6);\ntl.to("#p-bno", { opacity: 1, duration: 0.15 }, 5.6);\n`;
  // the freeze: a flash, everything else dims, the frame pushes in on the waiting window
  js += `tl.fromTo("#p-flash", { opacity: 0.55 }, { opacity: 0, duration: 0.35, ease: "power2.out", immediateRender: false }, ${FREEZE});\n`;
  js += `tl.to("#p-veil", { opacity: 0.62, duration: 0.2, ease: "power2.out" }, ${FREEZE});\ntl.set("#p-b", { zIndex: 6, opacity: 1 }, ${FREEZE});\n`;
  js += `tl.to("#p-stage", { scale: 1.07, transformOrigin: "${Math.round((Bw.x + Bw.w - 40) / W * 100)}% ${Math.round((Bw.y + 30) / H * 100)}%", duration: 0.22, ease: "power4.out" }, ${FREEZE});\n`;
  js += `gsap.set("#p-rip", { x: ${Bw.x + Bw.w - 34}, y: ${Bw.y + 31}, scale: 0.2, opacity: 0, zIndex: 7 });\ntl.fromTo("#p-rip", { scale: 0.2, opacity: 0.95 }, { scale: 1.5, opacity: 0, duration: 0.7, ease: "power2.out", immediateRender: false }, ${FREEZE});\ntl.fromTo("#p-rip", { scale: 0.2, opacity: 0.95 }, { scale: 1.5, opacity: 0, duration: 0.7, ease: "power2.out", immediateRender: false }, ${FREEZE + 0.9});\n`;
  js += `gsap.set("#p4", { opacity: 0, transformOrigin: "0% 50%" });\ntl.set("#p4", { opacity: 1 }, ${FREEZE});\ntl.fromTo("#p4", { scale: 1.3 }, { scale: 1, duration: 0.2, ease: "power4.out", immediateRender: false }, ${FREEZE});\n`;
  snd(T0 + FREEZE - 0.03, 'impact', 0.55);
  // out: the words burst past the camera into the next world
  js += `tl.to("#p4", { scale: 7, opacity: 0, duration: 0.3, ease: "power4.in" }, ${D - 0.3});\ntl.to("#p-stage", { scale: 1.6, opacity: 0, duration: 0.3, ease: "power4.in" }, ${D - 0.3});\n`;
  snd(T0 + D - 0.3, 'whooshB', 0.5);
  return { body, js, night: true };
});

// a line arrives and leaves word by word; a coloured row's ground comes and goes with it
function lineIn(L, at, first = false) { return (L.pill ? `gsap.set("#${L.pill}", { opacity: 0 });\ntl.set("#${L.pill}", { opacity: 1 }, ${r3(at)});\n` : '') + (first ? wfIn(L.id, L.n, at) : cutIn(L.id, L.n, at)); }
function lineOut(L, at) { return cutOut(L.id, L.n, at) + (L.pill ? `tl.to("#${L.pill}", { opacity: 0, duration: 0.16, ease: "none" }, ${r3(at + 0.04)});\n` : ''); }

// ================= 2. meet Vertex (9–17): it drops in, lands, looks around, waves =================
add('meet', 16, (T0, D) => {
  const TK = take(FOOT, 'meet'), VX = 1010, VY = 215, LAND = 0.42;
  const m1 = line('m1', T('MEET', 'VERTEX BUDDY.'), { width: 860, cy: 500 });
  const m2 = line('m2', T('YOUR LITTLE', 'COMPANION FOR', 'CLAUDE CODE.'), { width: 860, cy: 500 });
  const G = glows('m', TK, VX + 420, 640);
  let body = `${win('m-w1', 'website', code('m-c1', 7, 14), { x: 1100, y: 110, w: 780, h: 600, z: 1 })}${win('m-w2', 'notes', cards('m-k'), { x: 1000, y: 250, w: 800, h: 600, cls: 'warm', z: 2 })}
${G.html}${vertex('m-v', FOOT, 'meet', D, VX, VY, 840, 761)}${m1.html}${m2.html}`;
  let js = `gsap.set('[id^="m-g-"]', { scale: 0.4, opacity: 0 });\ntl.to("#m-g-${G.moods[0]}", { scale: 1, opacity: 1, duration: 0.5, ease: "power3.out" }, ${LAND});\n`;
  // the drop: the app's own picked-up pose on the way down, its own landing when it is let go
  js += `gsap.set("#m-vw", { y: -1000, transformOrigin: "50% 92%" });\ntl.to("#m-vw", { y: 0, duration: ${LAND - 0.02}, ease: "power2.in" }, 0.02);\ntl.to("#m-vw", { scale: 1.1, duration: 3.2, ease: "power1.out" }, ${LAND + 0.3});\n`;
  snd(T0 + LAND, 'pop', 0.6);
  js += lineIn(m1, 0.55, true) + lineOut(m1, 3.85); speak(T0 + 0.7, 'v04');
  js += lineIn(m2, 4.05) + lineOut(m2, D - 0.36); speak(T0 + 4.15, 'v05');
  // windows arrive behind it: it floats above them
  js += pieceIn('#m-w1', 4.0) + pieceIn('#m-w2', 4.12) + pieceOut('#m-w1', D - 0.34) + pieceOut('#m-w2', D - 0.34) + pieceOut('#m-vw', D - 0.34);
  snd(T0 + D - 0.22, 'whooshA', 0.45);
  return { body, js };
});

// ================= 3. the status colours (17–29) =================
add('status', 24, (T0, D) => {
  const TK = take(FOOT, 'status'), VX = 1150, VY = 300;
  const s1 = line('s1', T('EVERY APP.', 'EVERY SPACE.', 'EVEN FULL-SCREEN.'), { width: 860 });
  const s2 = line('s2', T('GREEN.', 'WORKING.'), { width: 860, pill: [0, MOOD.working] });
  const s3 = line('s3', T('YELLOW.', 'FINISHED.', 'YOUR TURN.'), { width: 860, pill: [0, MOOD.done] });
  const s4 = line('s4', T('PINK.', 'NEEDS YOUR', 'ANSWER.'), { width: 860, pill: [0, MOOD.needsYou] });
  const G = glows('s', TK, VX + 360, 640), ORDER = ['asleep', 'idle', 'working', 'done', 'needsYou'];
  let body = `${win('s-w1', 'website', code('s-c1', 7, 14), { x: 1040, y: 140, w: 800, h: 640 })}${win('s-w2', 'notes', cards('s-k'), { x: 1040, y: 140, w: 800, h: 640, cls: 'warm' })}
<div class="full" id="s-full" data-layout-ignore><div class="tool"></div><div style="position:absolute;left:1040px;top:140px;width:800px;height:640px">${cards('s-f')}</div></div>
${G.html}${vertex('s-v', FOOT, 'status', D, VX, VY, 720, 652)}
<div class="bub clip" id="s-b1" data-start="6.3" data-duration="2.6" data-track-index="2" data-layout-allow-occlusion><img id="s-b1i" src="assets/${FOOT}/bubble-done.png" alt=""></div>
<div class="bub clip" id="s-b2" data-start="8.9" data-duration="${r3(D - 8.9)}" data-track-index="2" data-layout-allow-occlusion><img id="s-b2i" src="assets/${FOOT}/bubble-needs.png" alt=""></div>
<div class="dots" id="s-dots" data-layout-ignore>${ORDER.map(m => `<i id="s-d-${m}" style="background:${MOOD[m]}"></i>`).join('')}</div>
${s1.html}${s2.html}${s3.html}${s4.html}`;
  let js = G.js + pieceIn('#s-vw', 0.02) + pieceIn('#s-w1', 0.02) + pieceIn('#s-dots', 0.1);
  // every app, every Space, even full-screen: each row lands as the thing behind Vertex changes
  const [r0, r1, r2, r3_] = s1.starts;
  js += cutIn('s1', r1, 0.12, 230, r0) + cutIn('s1', r2, 0.95, 230, r1) + cutIn('s1', r3_, 1.8, 230, r2) + cutOut('s1', s1.n, 2.72); speak(T0 + 0.2, 'v06');
  js += pieceOut('#s-w1', 0.8) + pieceIn('#s-w2', 0.95);
  js += `gsap.set("#s-full", { opacity: 0, clipPath: "inset(140px 80px 300px 1040px round 22px)" });\ntl.set("#s-full", { opacity: 1 }, 1.8);\ntl.set("#s-w2", { opacity: 0 }, 1.8);\ntl.to("#s-full", { clipPath: "inset(0px 0px 0px 0px round 0px)", duration: 0.5, ease: "power3.inOut" }, 1.8);\n`;
  js += lineIn(s2, 2.92) + lineOut(s2, 5.62); speak(T0 + 3.05, 'v07');
  js += lineIn(s3, 5.82) + lineOut(s3, 8.62); speak(T0 + 5.95, 'v08');
  js += lineIn(s4, 8.82) + lineOut(s4, D - 0.36); speak(T0 + 8.95, 'v09');
  js += `tl.fromTo("#s-b1i", { scale: 0.45, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.3, ease: "back.out(1.6)" }, 6.3);\ntl.fromTo("#s-b2i", { scale: 0.9 }, { scale: 1, duration: 0.22, ease: "back.out(1.6)" }, 8.9);\n`;
  snd(T0 + 6.3, 'pop', 0.5); snd(T0 + 8.9, 'pop', 0.45);
  // the five colours as a row of lights; the one that is on follows the footage
  js += ORDER.map(m => `gsap.set("#s-d-${m}", { scale: ${m === TK.track[0].mood ? 1.5 : 0.8}, opacity: ${m === TK.track[0].mood ? 1 : 0.4} });\n`).join('');
  let cur = TK.track[0].mood; for (const e of TK.track) if (e.mood !== cur) { js += `tl.to("#s-d-${cur}", { scale: 0.8, opacity: 0.4, duration: 0.25, ease: "power2.out" }, ${e.t});\ntl.to("#s-d-${e.mood}", { scale: 1.5, opacity: 1, duration: 0.3, ease: "back.out(2)" }, ${e.t});\n`; cur = e.mood; }
  js += pieceOut('#s-vw', D - 0.34) + pieceOut('#s-dots', D - 0.34) + `tl.to("#s-b2i", { x: -230, opacity: 0, duration: 0.3, ease: "power4.in" }, ${D - 0.34});\n`;
  snd(T0 + D - 0.22, 'whooshB', 0.45);
  return { body, js };
});

// ================= 4. the product (29–39): hover, see which one, click =================
add('demo', 20, (T0, D) => {
  const TK = take(FOOT, 'demo'), VX = 1150, VY = 300, CX = VX + 360, CY = 690, CLICK = 7.2;
  const d1 = line('d1', T('SEE EVERY', 'LIVE SESSION.'), { width: 860 });
  const d2 = line('d2', T('KNOW WHICH', 'ONE NEEDS YOU.'), { width: 860 });
  const d3 = line('d3', T('CLICK.', 'JUMP TO THE', 'SESSION.'), { width: 860 });
  const G = glows('o', TK, CX, 640);
  let body = `${win('o-api', 'api', code('o-ca', 23, 13), { x: 1120, y: 90, w: 740, h: 600, z: 1, dot: `<em><i style="background:${MOOD.needsYou}"></i><i id="o-ok" style="background:${MOOD.working}"></i></em>` })}
${win('o-web', 'website', code('o-cw', 7, 13), { x: 1010, y: 200, w: 780, h: 600, z: 2 })}
${G.html}${vertex('o-v', FOOT, 'demo', D, VX, VY, 720, 652)}
<div class="bub clip" id="o-b" data-start="1.1" data-duration="${r3(CLICK + 0.14 - 1.1)}" data-track-index="2" data-layout-allow-occlusion><img id="o-bi" src="assets/${FOOT}/bubble-needs.png" alt=""></div>
<div class="call" id="o-call" data-layout-ignore></div><div class="rip" id="o-rip" data-layout-ignore></div>
${d1.html}${d2.html}${d3.html}${CUR('o-cur')}`;
  let js = G.js + pieceIn('#o-vw', 0.02) + pieceIn('#o-web', 0.02) + pieceIn('#o-api', 0.06);
  js += `gsap.set("#o-ok", { opacity: 0 });\ngsap.set("#o-ca-9, #o-ca-10, #o-ca-11, #o-ca-12", { scaleX: 0 });\n`;
  // hover: the cursor comes in from off screen and rests on Vertex; its bubble opens
  js += lineIn(d1, 0.12) + lineOut(d1, 2.9); speak(T0 + 0.3, 'v10');
  js += `gsap.set("#o-cur", ${J(cp(-170, 1000))});\n` + curTo('o-cur', CX + 30, CY + 40, 0.25, 0.8);
  js += `tl.fromTo("#o-bi", { scale: 0.45, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.3, ease: "back.out(1.6)" }, 1.1);\n`; snd(T0 + 1.1, 'pop', 0.5);
  // which one: the cursor points at the outlined row and a ring lands on it twice
  js += lineIn(d2, 3.1) + lineOut(d2, 6.0); speak(T0 + 3.2, 'v11');
  js += curTo('o-cur', 1700, 262, 3.2, 0.6, 'power3.inOut');
  js += `gsap.set("#o-call", { opacity: 0 });\n` + [3.75, 4.6].map(a => `tl.fromTo("#o-call", { scale: 1.22, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.25, ease: "power4.out", immediateRender: false }, ${a});\ntl.to("#o-call", { opacity: 0, duration: 0.3, ease: "power2.in" }, ${a + 0.5});\n`).join('');
  // click: back to Vertex, tap, the bubble closes and the waiting session's window comes forward
  js += lineIn(d3, 6.2) + lineOut(d3, D - 0.36); speak(T0 + 6.85, 'v12');
  js += curTo('o-cur', CX - 10, CY, 6.3, 0.7, 'power3.inOut') + tap('o-cur', CLICK); snd(T0 + CLICK, 'click', 0.8);
  js += `gsap.set("#o-rip", { x: ${CX}, y: ${CY}, scale: 0.3, opacity: 0 });\ntl.fromTo("#o-rip", { scale: 0.3, opacity: 0.9 }, { scale: 1.7, opacity: 0, duration: 0.5, ease: "power2.out", immediateRender: false }, ${CLICK});\n`;
  js += `tl.to("#o-bi", { scale: 0.6, opacity: 0, duration: 0.12, ease: "power2.in" }, ${CLICK});\n`;
  js += `tl.set("#o-api", { zIndex: 3 }, ${CLICK});\ntl.fromTo("#o-api", { scale: 0.94 }, { scale: 1, x: -110, y: 110, duration: 0.45, ease: "power4.out", immediateRender: false }, ${CLICK});\ntl.to("#o-web", { x: 90, y: -90, scale: 0.95, opacity: 0.7, duration: 0.45, ease: "power4.out" }, ${CLICK});\ntl.to("#o-ok", { opacity: 1, duration: 0.2 }, ${CLICK + 0.35});\n`;
  js += [9, 10, 11, 12].map((i, k) => `tl.to("#o-ca-${i}", { scaleX: 1, duration: 0.2, ease: "power2.out" }, ${r3(CLICK + 0.7 + k * 0.3)});\n`).join('');
  js += curTo('o-cur', 2080, 1010, 8.1, 0.6, 'power2.in');
  js += pieceOut('#o-vw', D - 0.34) + pieceOut('#o-api', D - 0.34) + pieceOut('#o-web', D - 0.34);
  snd(T0 + D - 0.22, 'whooshA', 0.45);
  return { body, js };
});

// ================= 5. the cast (39–47): four characters, nine behaviours, twelve faces =================
add('cast', 16, (T0, D) => {
  const NAMES = [['cloud', 'Cloud Vertex'], ['pixel', 'Pixel Vertex'], ['robo', 'Robo Vertex'], ['cozy', 'Cozy Vertex']];
  const BEH = ['idle', 'working', 'thinking', 'walking', 'following', 'watching', 'sleeping', 'happy', 'curious'];
  const FACES = ['neutral', 'happy', 'excited', 'curious', 'confused', 'sleepy', 'surprised', 'playful', 'focused', 'worried', 'pondering', 'sneaky'];
  const A1 = 2.5, A2 = 5.3, STEP = 0.3;
  const c1 = line('c1', T('FOUR CHARACTERS.'), { width: 1500, top: 96, cap: 130 });
  const c2 = line('c2', T('NINE BEHAVIOURS.'), { width: 1500, top: 96, cap: 130 });
  const c3 = line('c3', T('TWELVE FACES.'), { width: 1500, top: 96, cap: 130 });
  let body = c1.html + c2.html + c3.html, js = '';
  js += lineIn(c1, 0.04) + lineOut(c1, A1 - 0.24) + lineIn(c2, A1 - 0.04) + lineOut(c2, A2 - 0.24) + lineIn(c3, A2 - 0.04) + lineOut(c3, D - 0.36);
  speak(T0 + 0.15, 'v13'); speak(T0 + A1 + 0.05, 'v14'); speak(T0 + A2 + 0.05, 'v15');
  NAMES.forEach(([k, name], i) => { const x = 45 + i * 445;
    body += `<div class="disc" id="c-d${i}" style="left:${x + 60}px;top:734px" data-layout-ignore></div><div class="vw" id="c-${k}w" style="left:${x}px;top:330px;width:520px;height:472px" data-layout-allow-occlusion><video id="c-${k}" class="clip" src="assets/${FOOT}/cast-${k}.webm" muted playsinline data-start="0" data-duration="${A1}" data-track-index="${1 + i}" data-layout-allow-occlusion></video></div><div class="nm mono" id="c-n${i}" style="left:${x}px">${txt(name)}</div>`;
    js += pieceIn(`#c-${k}w`, 0.02 + i * 0.06) + pieceIn(`#c-n${i}`, 0.25 + i * 0.06) + pieceOut(`#c-${k}w`, A1 - 0.3 + i * 0.012) + pieceOut(`#c-n${i}`, A1 - 0.3 + i * 0.012) + `tl.set("#c-d${i}", { opacity: 0 }, ${A1 - 0.05});\n`; });
  // nine behaviours: one clip each, cut on the beat, with its name lit in the row underneath
  body += `<div class="disc" id="c-bd" style="left:760px;top:890px;width:400px" data-layout-ignore></div>` + BEH.map((b, i) => `<div class="vw" id="c-b${i}w" style="left:600px;top:290px;width:720px;height:652px" data-layout-allow-occlusion><video id="c-b${i}" class="clip" src="assets/${FOOT}/beh-${b}.webm" muted playsinline data-start="${r3(A1 + i * STEP)}" data-duration="${STEP}" data-track-index="${5 + i % 2}" data-layout-allow-occlusion></video></div>`).join('');
  body += `<div class="chips mono" id="c-chips">${BEH.map((b, i) => `<span id="c-ch${i}">${txt(b[0].toUpperCase() + b.slice(1))}<i id="c-cu${i}"></i></span>`).join('')}</div>`;
  js += `gsap.set("#c-bd", { opacity: 0 });\ntl.set("#c-bd", { opacity: 1 }, ${A1});\ntl.set("#c-bd", { opacity: 0 }, ${A2 - 0.02});\n` + pieceIn('#c-chips', A1 - 0.04) + pieceOut('#c-chips', A2 - 0.26);
  BEH.forEach((b, i) => { const a = r3(A1 + i * STEP); js += `gsap.set("#c-cu${i}", { scaleX: 0 });\ntl.set("#c-cu${i}", { scaleX: 1 }, ${a});\n` + (i < BEH.length - 1 ? `tl.set("#c-cu${i}", { scaleX: 0 }, ${r3(a + STEP)});\n` : ''); });
  // twelve faces: they pop in one after another, two rows of six
  FACES.forEach((f, i) => { const x = 90 + (i % 6) * 290, y = i < 6 ? 300 : 610, a = r3(A2 + 0.05 + i * 0.09);
    body += `<div class="face" id="c-f${i}" style="left:${x}px;top:${y}px"><div><img src="assets/${FOOT}/faces/${f}.png" alt=""></div><span class="mono">${txt(f)}</span></div>`;
    js += popIn(`#c-f${i}`, a, 0.55) + pieceOut(`#c-f${i}`, D - 0.34 + (i % 6) * 0.01); });
  snd(T0 + A1 - 0.2, 'whooshA', 0.35); snd(T0 + A2 - 0.2, 'whooshA', 0.35); snd(T0 + D - 0.22, 'whooshB', 0.45);
  return { body, js };
});

// ================= 6. trust, the line, the name (47–55) =================
add('close', 16, (T0, D) => {
  const TK = take(FOOT, 'end'), VX = 1150, VY = 300, CARD = 4.1;
  const e1 = line('e1', T('NO HOOKS.'), { width: 860 });
  const e2 = line('e2', T('NO CLAUDE', 'SETTINGS', 'CHANGES.'), { width: 860 });
  const e3 = line('e3', T('NOTHING SENT', 'ANYWHERE.'), { width: 860 });
  const e4 = line('e4', T('CLAUDE DOES THE WORK.', 'VERTEX KEEPS YOU', 'IN THE LOOP.'), { width: 900, left: 900, top: 462, cap: 70 });
  const G = glows('e', TK, VX + 360, 640);
  let body = `${G.html}${vertex('e-v', FOOT, 'end', D, VX, VY, 720, 652)}${e1.html}${e2.html}${e3.html}${e4.html}
<div class="mark" id="e-mark">${txt('VERTEX BUDDY')}</div><div class="url mono" id="e-url">${REPO}</div><div class="indie mono" id="e-ind">${txt('An independent project. Not made by Anthropic.')}</div>`;
  let js = G.js + pieceIn('#e-vw', 0.02);
  js += lineIn(e1, 0.1) + lineOut(e1, 1.0) + lineIn(e2, 1.2) + lineOut(e2, 2.5) + lineIn(e3, 2.7) + lineOut(e3, CARD - 0.2); speak(T0 + 0.15, 'v16');
  // the end card: Vertex carries itself to the left, the line lands beside it, then the name and the address
  js += `tl.to("#e-vw", { x: -860, duration: 0.6, ease: "power3.inOut" }, ${CARD});\ntl.to('[id^="e-g-"]', { x: -860, duration: 0.6, ease: "power3.inOut" }, ${CARD});\n`;
  js += wfIn('e4', e4.n, CARD + 0.35, { gap: 0.11 }); speak(T0 + CARD + 0.3, 'v17');
  js += `gsap.set("#e-mark", { clipPath: "inset(-10% 100% -10% 0%)" });\ntl.to("#e-mark", { clipPath: "inset(-10% 0% -10% 0%)", duration: 0.4, ease: "power3.out" }, 5.7);\n`; snd(T0 + 5.7, 'pop', 0.4);
  js += `gsap.set("#e-url, #e-ind", { opacity: 0 });\ntl.set("#e-url", { opacity: 1 }, 5.85);\ntl.fromTo("#e-url", { y: 36 }, { y: 0, duration: 0.24, ease: "power4.out", immediateRender: false }, 5.85);\ntl.set("#e-ind", { opacity: 1 }, 5.92);\ntl.fromTo("#e-ind", { y: 30 }, { y: 0, duration: 0.24, ease: "power4.out", immediateRender: false }, 5.92);\n`;
  return { body, js };
});

// ================= write the project =================
fs.mkdirSync(path.join(OUT, 'compositions'), { recursive: true });
const FDIR = path.join(VIDEO, 'assets', FOOT);
for (const f of fs.readdirSync(FDIR)) { if (/\.(webm|png)$/.test(f)) asset(path.join(FDIR, f), `${FOOT}/${f}`); }
for (const f of fs.readdirSync(path.join(FDIR, 'faces'))) asset(path.join(FDIR, 'faces', f), `${FOOT}/faces/${f}`);
for (const [f] of Object.values(SFX)) asset(path.join(VIDEO, 'assets/audio/sfx', f), 'audio/sfx/' + f);
for (const f of ['jetbrains-mono-var-latin.woff2', 'OFL.txt']) asset(path.join(VIDEO, 'assets/fonts', f), 'fonts/' + f);
for (const l of VO) asset(path.join(VIDEO, l.file), `audio/voice/${l.id}.wav`);
const MUSIC = ['launch.mp3', 'launch.wav', 'launch-bed.wav'].map(f => path.join(VIDEO, 'assets/audio/music', f)).find(f => fs.existsSync(f));
if (MUSIC) asset(MUSIC, 'audio/music/' + path.basename(MUSIC));

const DUR = r3(scenes.reduce((a, s) => a + s.beats, 0) * B);
for (const s of scenes) fs.writeFileSync(path.join(OUT, 'compositions', s.id + '.html'),
  `<template>\n<style>\n${scope(CSS + EXTRA)}${s.night ? `\n#root { background: ${NIGHT}; }` : ''}\n</style>\n<div id="root" data-composition-id="${s.id}" data-width="${W}" data-height="${H}">\n${s.body}\n</div>\n<script>\n(function () {\n  const tl = gsap.timeline({ paused: true });\n${s.js.split('\n').map(l => '  ' + l).join('\n')}\n  window.__timelines["${s.id}"] = tl;\n})();\n</script>\n</template>\n`);
const hosts = scenes.map(s => `      <div id="${s.id}" data-composition-id="${s.id}" data-composition-src="compositions/${s.id}.html" data-start="${s.start}" data-duration="${s.dur}" data-track-index="0" data-track-kind="graphics" data-width="${W}" data-height="${H}"></div>`).join('\n');
sfx.sort((a, b) => a.t - b.t); const ends = []; const lane = (st, d) => { let i = ends.findIndex(e => e <= st + 1e-6); if (i < 0) { i = ends.length; ends.push(0); } ends[i] = st + d; return 12 + i; };
const fx = sfx.map((e, i) => { const [f, d] = SFX[e.key]; return `      <audio id="sfx-${i}-${e.key}" class="clip" src="assets/audio/sfx/${f}" data-start="${e.t}" data-duration="${d}" data-volume="${e.vol}" data-track-index="${lane(e.t, d)}"></audio>`; }).join('\n');
vo.sort((a, b) => a.at - b.at);
for (let i = 1; i < vo.length; i++) if (vo[i].at < vo[i - 1].at + vo[i - 1].duration + 0.05) throw new Error(`narration ${vo[i].id} starts before ${vo[i - 1].id} has finished`);
const voice = vo.map(v => `      <audio id="vo-${v.id}" class="clip" src="assets/audio/voice/${v.id}.wav" data-start="${v.at}" data-duration="${v.duration}" data-volume="1" data-track-index="11" data-timeline-role="voice"></audio>`).join('\n');
const music = MUSIC ? `      <audio id="music-bed" class="clip" src="assets/audio/music/${path.basename(MUSIC)}" data-start="0" data-duration="${DUR}" data-volume="0.32" data-track-index="10" data-timeline-role="music"></audio>\n` : '';
fs.writeFileSync(path.join(OUT, 'index.html'), `<!doctype html>
<html lang="en" data-resolution="landscape">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=${W}, height=${H}" />
    <title>Vertex Buddy launch film, 55 s, 16:9</title>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { margin: 0; width: ${W}px; height: ${H}px; overflow: hidden; background: ${GROUND}; }
    </style>
  </head>
  <body>
    <!-- Generated by video/source/build/launch.mjs. Edit the builder, then run: video/source/bin/make build -->
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
put('meta.json', J({ id: P, name: 'vertex-buddy-launch-55s', createdAt: '2026-11-21T00:00:00.000Z' }, null, 2) + '\n');
put('package.json', J({ name: P, private: true, type: 'module' }, null, 2) + '\n');
fs.mkdirSync(path.join(VIDEO, 'storyboard'), { recursive: true });
fs.writeFileSync(path.join(VIDEO, 'storyboard/timeline-launch.json'), J({ film: 'Vertex Buddy launch film, 55 s, 16:9', width: W, height: H, fps: 30, bpm: BPM, duration: DUR,
  music: { bpm: BPM, open_at: scenes[1].start, close_at: r3(scenes[5].start + 4.1), file: MUSIC ? path.basename(MUSIC) : null },
  scenes: scenes.map(s => ({ id: s.id, start: s.start, dur: s.dur, beats: s.beats })), vo, sfx: sfx.map(e => ({ t: e.t, sound: SFX[e.key][0], volume: e.vol })), words: copy }, null, 1));
console.log(`${P}: ${scenes.length} scenes | ${DUR} s | narration ${vo.length} lines | sfx ${sfx.length} | music ${MUSIC ? path.basename(MUSIC) : 'none yet'}`);
for (const s of scenes) console.log(`  ${s.id.padEnd(8)} ${s.start.toFixed(1).padStart(5)}  ${s.dur.toFixed(1)} s`);
