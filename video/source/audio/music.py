#!/usr/bin/env python3
"""Vertex Buddy launch film: a scratch music bed, written and rendered here (original; no samples, no licence to clear).

It is a placeholder for judging the cut, adapted from the bed written for the FORMA films. D minor, at the film's tempo:
a warm pad and a soft sub under the problem scene, then it opens to F major with a plucked pulse exactly when Vertex
lands, and it is ducked under each narration line. Replace it with a real track before publishing
(assets/audio/music/launch.mp3, then build and render).

usage: python music.py launch      (run from video/source; reads video/storyboard/timeline-launch.json)
"""
import json, sys, os
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
from scipy.io import wavfile

fmt = sys.argv[1]
VIDEO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
tl = json.load(open(os.path.join(VIDEO, 'storyboard', f'timeline-{fmt}.json')))
vo = {'lines': tl.get('vo', [])}
SR = 48000; DUR = tl['duration'] + 1.5; N = int(SR * DUR); t = np.arange(N) / SR
BPM = tl['music']['bpm']; BEAT = 60.0 / BPM; BAR = 4 * BEAT; OPEN = tl['music']['open_at']
scene = {s['id']: s for s in tl['scenes']}
rng = np.random.default_rng(7)

def midi(n): return 440.0 * 2 ** ((n - 69) / 12)
def env_seg(t0, t1, a=0.02, r=0.3):
    e = np.zeros(N); i0, i1 = int(max(0, t0) * SR), int(min(DUR, t1) * SR)
    if i1 <= i0: return e
    n = i1 - i0; x = np.ones(n); na, nr = min(n // 2, int(a * SR)), min(n // 2, int(r * SR))
    if na: x[:na] = np.sin(np.linspace(0, np.pi / 2, na)) ** 2
    if nr: x[-nr:] = np.cos(np.linspace(0, np.pi / 2, nr)) ** 2
    e[i0:i1] = x; return e
def lp(x, fc, order=2): return sosfilt(butter(order, min(fc, SR * 0.45), 'low', fs=SR, output='sos'), x)
def hp(x, fc, order=2): return sosfilt(butter(order, fc, 'high', fs=SR, output='sos'), x)
def saw(f, ph=0.0):  # band-limited enough for a pad: a few harmonics
    y = np.zeros(N)
    for k in range(1, 9): y += np.sin(2 * np.pi * f * k * t + ph * k) / k
    return y * 0.55
def tri(f, ph=0.0):
    y = np.zeros(N)
    for k in range(0, 5): h = 2 * k + 1; y += ((-1) ** k) * np.sin(2 * np.pi * f * h * t + ph) / (h * h)
    return y * 0.8

# ---- harmony: four bars a chord. Before the opening: Dm9, Bbmaj7, F add9, C sus2. After: F, C, Dm7, Bb (open, brighter).
A = [[50, 57, 60, 64, 65], [46, 53, 57, 62, 65], [53, 57, 60, 67, 69], [48, 55, 62, 64, 67]]
B = [[53, 60, 65, 69, 72], [48, 55, 64, 67, 72], [50, 57, 65, 69, 72], [46, 53, 62, 65, 70]]
CH = 2 * BAR
def chord_at(time):
    if time < OPEN: return A[int(time // CH) % 4], False
    return B[int((time - OPEN) // CH) % 4], True

L = np.zeros(N); R = np.zeros(N)
# ---- pad
k = 0; tt = 0.0
while tt < DUR:
    nxt = min(DUR, OPEN if (tt < OPEN < tt + CH) else tt + CH); notes, bright = chord_at(tt + 1e-3)
    e = env_seg(tt - 0.6, nxt + 1.2, a=1.6, r=2.2)
    for j, n in enumerate(notes):
        f = midi(n); d = 0.0035 * (1 + j % 3)
        a = (saw(f * (1 - d), 0.3 * j) + tri(f * (1 + d), 1.1 * j)) * e * (0.20 if j else 0.26)
        b = (saw(f * (1 + d), 0.7 * j) + tri(f * (1 - d), 0.4 * j)) * e * (0.20 if j else 0.26)
        pan = 0.5 + 0.38 * np.sin(j * 1.7 + k); L += a * (1 - pan * 0.6); R += b * (0.4 + pan * 0.6)
    tt = nxt; k += 1
# the pad's filter opens with the render
cut = np.interp(t, [0, OPEN - 2.0, OPEN + 0.4, OPEN + 6, DUR], [700, 950, 2600, 3200, 2400])
def sweep_lp(x):
    out = np.zeros(N); step = int(0.05 * SR)
    for i in range(0, N, step):
        j = min(N, i + step + 256); seg = lp(x[max(0, i - 2048):j], float(cut[i]))
        out[i:min(N, i + step)] = seg[(i - max(0, i - 2048)):(i - max(0, i - 2048)) + min(N, i + step) - i]
    return out
L = sweep_lp(L); R = sweep_lp(R)

# ---- sub and bass (kept audible on small speakers with a little harmonic)
bass = np.zeros(N); tt = 0.0
while tt < DUR:
    nxt = min(DUR, OPEN if (tt < OPEN < tt + CH) else tt + CH); notes, bright = chord_at(tt + 1e-3); f = midi(notes[0] - 12)
    e = env_seg(tt, nxt + 0.3, a=0.25, r=0.9)
    bass += (np.sin(2 * np.pi * f * t) * 0.9 + np.sin(2 * np.pi * 2 * f * t) * 0.28 + np.sin(2 * np.pi * 3 * f * t) * 0.10) * e
    tt = nxt
bass *= np.interp(t, [0, 2, OPEN - 0.3, OPEN + 0.2, DUR - 4, DUR], [0.0, 0.16, 0.20, 0.30, 0.26, 0.0])

# ---- the pulse: plucked eighths outlining the chord. It starts with the team, thins for the approvals, doubles at the opening.
team = OPEN; appr = {'start': DUR, 'dur': 0}
pl = np.zeros(N); pr = np.zeros(N); step = BEAT / 2; i = 0; tt = np.ceil(max(team - 0.2, 0) / step) * step
pat = [0, 2, 1, 3, 2, 4, 1, 3]
close_at = tl['music']['close_at']
while tt < min(DUR - 3.0, close_at + 6.0):
    notes, bright = chord_at(tt)
    in_appr = appr['start'] - 0.3 <= tt < appr['start'] + appr['dur'] - 0.4
    if not (in_appr and i % 2):
        n = notes[pat[i % 8] % len(notes)] + (12 if (bright and i % 4 == 2) else 0)
        f = midi(n + 12); dur_n = 0.55 if bright else 0.42; i0 = int(tt * SR); m = min(N - i0, int(dur_n * SR * 2.2))
        if m > 0:
            x = np.arange(m) / SR; e = np.exp(-x / (dur_n * 0.42)) * (1 - np.exp(-x / 0.004))
            y = (np.sin(2 * np.pi * f * x) + 0.35 * np.sin(2 * np.pi * 2 * f * x + 0.5) * np.exp(-x / 0.08) + 0.12 * np.sin(2 * np.pi * 3 * f * x) * np.exp(-x / 0.05)) * e
            g = (0.085 if not bright else 0.115) * (0.55 if in_appr else 1.0) * (1.0 if i % 2 == 0 else 0.72)
            fade = float(np.interp(tt, [team - 0.2, team + 2.4, close_at, close_at + 6.0], [0.0, 1.0, 1.0, 0.0]))
            pan = 0.5 + 0.34 * np.sin(i * 0.9); pl[i0:i0 + m] += y * g * fade * (1 - pan); pr[i0:i0 + m] += y * g * fade * pan
    tt += step; i += 1
pl = hp(lp(pl, 6500), 180); pr = hp(lp(pr, 6500), 180)

# ---- drive: a soft kick on every beat, hats between them and a clap on two and four, when the timeline asks (music.drive)
dr = np.zeros(N)
if tl['music'].get('drive'):
    k = 0; tt = np.ceil(OPEN / BEAT) * BEAT
    while tt < min(DUR - 2.0, close_at + 3.5):
        i0 = int(tt * SR); n1 = min(N - i0, int(0.32 * SR)); x = np.arange(n1) / SR
        if n1 > 0: dr[i0:i0 + n1] += np.sin(2 * np.pi * (46 * x + (118 - 46) * 0.03 * (1 - np.exp(-x / 0.03)))) * np.exp(-x / 0.12) * 0.34
        j0 = int((tt + BEAT / 2) * SR); n2 = min(N - j0, int(0.07 * SR))
        if n2 > 64: dr[j0:j0 + n2] += hp(rng.standard_normal(n2), 6500) * np.exp(-np.arange(n2) / SR / 0.02) * 0.05
        if k % 2 == 1:
            n3 = min(N - i0, int(0.2 * SR))
            if n3 > 64: dr[i0:i0 + n3] += lp(hp(rng.standard_normal(n3), 900), 3600) * np.exp(-np.arange(n3) / SR / 0.06) * 0.11
        tt += BEAT; k += 1

# ---- drama: a heartbeat before the opening, a roll into it, a deep hit there and at the mark, and a thinner beat in the quiet passage
if tl['music'].get('drama'):
    brk = tl['music'].get('break_at', DUR); tt = np.ceil(4.0 / (2 * BEAT)) * 2 * BEAT
    while tt < OPEN - 1.6:
        i0 = int(tt * SR); n1 = min(N - i0, int(0.4 * SR)); x = np.arange(n1) / SR
        dr[i0:i0 + n1] += np.sin(2 * np.pi * (40 * x + (80 - 40) * 0.04 * (1 - np.exp(-x / 0.04)))) * np.exp(-x / 0.16) * 0.28
        tt += 2 * BEAT
    tt = OPEN - 1.5; k = 0
    while tt < OPEN - 0.01:
        i0 = int(tt * SR); n3 = min(N - i0, int(0.09 * SR))
        if n3 > 64: dr[i0:i0 + n3] += lp(hp(rng.standard_normal(n3), 700), 4200) * np.exp(-np.arange(n3) / SR / 0.03) * (0.03 + 0.11 * (k / 12))
        tt += BEAT / 4; k += 1
    b0, b1 = int(brk * SR), int(close_at * SR)
    if b1 > b0: dr[b0:b1] *= 0.35
    dr *= 1.25
    for th, g in ((OPEN, 0.55), (close_at, 0.7)):
        i0 = int(th * SR); n1 = min(N - i0, int(1.8 * SR)); x = np.arange(n1) / SR
        dr[i0:i0 + n1] += np.sin(2 * np.pi * (34 * x + (95 - 34) * 0.09 * (1 - np.exp(-x / 0.09)))) * np.exp(-x / 0.5) * g
        dr[i0:i0 + n1] += hp(rng.standard_normal(n1), 5000) * np.exp(-x / 0.35) * 0.06 * g

# ---- air: a breath of filtered noise that rises into the opening
air = lp(hp(rng.standard_normal(N), 1800), 7000)
air *= np.interp(t, [0, OPEN - 5.0, OPEN - 0.05, OPEN + 0.5, OPEN + 5, DUR], [0.0, 0.0, 0.050, 0.012, 0.004, 0.0])

L = L + pl + air * 0.9; R = R + pr + air
# ---- room: a short synthetic reverb (exponentially decaying noise), wet 22 %
ir_n = int(2.4 * SR); ir_t = np.arange(ir_n) / SR
irl = lp(rng.standard_normal(ir_n), 5200) * np.exp(-ir_t / 0.62); irr = lp(rng.standard_normal(ir_n), 5200) * np.exp(-ir_t / 0.66)
irl /= np.sqrt(np.sum(irl ** 2)); irr /= np.sqrt(np.sum(irr ** 2))
wl = fftconvolve(L, irl)[:N]; wr = fftconvolve(R, irr)[:N]
L = L * 0.86 + wl * 0.24 + bass; R = R * 0.86 + wr * 0.24 + bass
L = L + dr; R = R + dr

# ---- shape: fade in, section levels, duck under each narration line, fade out
# The opening is carried by the brighter chords, the octave of pulse and the bed coming out from under the voice, not by a jump in level:
# measured in the first mix, a full step up put the reveal about 8 dB over the narration. level_ref is that first curve, kept only as the
# gain reference so the bed under the voice stays exactly where it was balanced.
KNOTS = [0, 1.2, OPEN - 0.4, OPEN + 0.25, DUR - 3.6, DUR - 1.5, DUR]
level_ref = np.interp(t, KNOTS, [0.0, 0.62, 0.74, 1.0, 0.92, 0.0, 0.0])
level = np.interp(t, KNOTS, [0.0, 0.62, 0.74, 0.76, 0.72, 0.0, 0.0])
duck = np.ones(N)
for ln in vo['lines']:
    a = ln['at']; b = a + ln['duration']
    d = np.interp(t, [a - 0.35, a + 0.05, b - 0.05, b + 0.55], [1.0, 0.42, 0.42, 1.0], left=1.0, right=1.0); duck = np.minimum(duck, d)
shape = lambda lv: np.stack([hp(L * lv * duck, 34), hp(R * lv * duck, 34)], axis=1)
peak = np.max(np.abs(shape(level_ref))); st = shape(level) / peak * 10 ** (-3.0 / 20)          # leave 3 dB: the mix adds voice and effects
st = np.tanh(st * 1.05) / np.tanh(1.05)
out = os.path.join(VIDEO, 'assets', 'audio', 'music'); os.makedirs(out, exist_ok=True)
path = os.path.join(out, f'{fmt}-bed.wav'); wavfile.write(path, SR, (st * 32767).astype(np.int16))
rms = float(np.sqrt(np.mean(st ** 2)))
json.dump({'file': os.path.relpath(path, VIDEO), 'format': fmt, 'seconds': round(DUR, 2), 'bpm': BPM, 'key': 'D minor, opening to F major', 'opens_at': OPEN,
           'peak_dbfs': round(20 * np.log10(np.max(np.abs(st))), 2), 'rms_dbfs': round(20 * np.log10(rms), 2), 'ducked_under': [l['id'] for l in vo['lines']],
           'origin': 'written and synthesised for this film by source/audio/music.py; no samples'}, open(os.path.join(out, f'{fmt}-bed.json'), 'w'), indent=1)
print(path, 'peak', round(20 * np.log10(np.max(np.abs(st))), 2), 'dBFS rms', round(20 * np.log10(rms), 2), 'dBFS')
