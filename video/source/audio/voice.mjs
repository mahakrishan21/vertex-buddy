// Generates the narration with the local voice (Kokoro, on this machine; nothing is sent anywhere).
// usage: node audio/voice.mjs launch     (run from video/source; reads video/scripts/voiceover-<film>.json)
import fs from 'node:fs'; import path from 'node:path'; import { spawnSync } from 'node:child_process'; import { fileURLToPath } from 'node:url';
const VIDEO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..'); const film = process.argv[2] || 'launch';
const spec = JSON.parse(fs.readFileSync(path.join(VIDEO, 'scripts', `voiceover-${film}.json`), 'utf8')); const outDir = path.join(VIDEO, 'assets/audio/voice', film); fs.mkdirSync(outDir, { recursive: true });
const hf = path.join(VIDEO, 'source/bin/hf'); const manifest = { film, voice: spec.voice, speed: spec.speed, engine: 'Kokoro-82M (local, via hyperframes tts)', lines: [] };
for (const l of spec.lines) { const out = path.join(outDir, l.id + '.wav');
  const r = spawnSync(hf, ['tts', l.text, '-o', out, '-v', spec.voice, '-s', String(spec.speed), '--json'], { encoding: 'utf8' });
  const j = JSON.parse((r.stdout.trim().split('\n').pop()) || '{}'); if (!j.ok) throw new Error(l.id + ': ' + r.stdout + r.stderr);
  manifest.lines.push({ id: l.id, scene: l.scene, text: l.text, file: path.relative(VIDEO, out), duration: +j.durationSeconds.toFixed(3) }); console.log(l.id, j.durationSeconds.toFixed(2) + ' s', l.text); }
fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(manifest, null, 1));
