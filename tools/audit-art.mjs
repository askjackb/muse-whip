#!/usr/bin/env node
// Art audit: runs every automated rule of docs/ART_CONTRACT.md on delivered frames.
// Exit 0 = no DEFECT (FLAGs go to the reviewer), 1 = at least one DEFECT, 2 = usage error.
//
//   node tools/audit-art.mjs --frames <frames_root> [--out <dir>] [--only <regex>] [--allow-missing]
//                            [--contract contract/art_contract.json]
//
// <frames_root>/<clip_id>/f000.png ...   delivered frames at contract canvas size
// <frames_root>/clips.json               { clip_id: { "ms": [...], "loop": bool } }
// <frames_root>/hand_sockets.json        { hero_attack_clip_id: [[x, y], ...] }
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadContract } from './lib/contract.mjs';
import { runAudit } from './lib/audit.mjs';
import { dirSource } from './lib/source.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const opt = (name) => { const i = argv.indexOf(name); return i >= 0 ? argv[i + 1] : undefined; };
const framesRoot = opt('--frames');
if (!framesRoot) {
  console.error('usage: node tools/audit-art.mjs --frames <frames_root> [--out <dir>] [--only <regex>] [--allow-missing]');
  process.exit(2);
}
const c = loadContract(opt('--contract') || resolve(repo, 'contract/art_contract.json'));
const out = opt('--out') || resolve(framesRoot, '..', 'review');
const result = runAudit(c, dirSource(framesRoot), { only: opt('--only'), allowMissing: argv.includes('--allow-missing') });

mkdirSync(out, { recursive: true });
const slim = Object.fromEntries(Object.entries(result.metrics).map(([id, fs]) => [id, fs.map((f) => f && Object.fromEntries(
  Object.entries(f).filter(([k]) => k !== 'figure' && k !== 'debris').map(([k, v]) => [k, typeof v === 'number' ? Math.round(v * 1000) / 1000 : v]),
))]));
writeFileSync(resolve(out, 'audit.json'), JSON.stringify({
  contract_version: c.contract_version, frames_root: resolve(framesRoot),
  defects: result.defects, flags: result.flags, clips_audited: result.clips,
  references: result.refs, findings: result.findings, metrics: slim,
}, null, 1));

const byRule = {};
for (const f of result.findings) (byRule[`${f.rule} ${f.severity}`] ||= []).push(f);
const lines = [
  `# Art audit`, '',
  `Contract ${c.contract_version}; ${result.clips} clips audited; **${result.defects} DEFECT, ${result.flags} FLAG**.`, '',
  'DEFECTs block approval. Every FLAG must be adjudicated by the independent reviewer (ART_CONTRACT §9).', '',
  '| Rule | Severity | Count |', '|---|---|---:|',
  ...Object.entries(byRule).sort().map(([k, v]) => `| ${k.split(' ')[0]} | ${k.split(' ')[1]} | ${v.length} |`), '',
  '## Findings', '',
  ...result.findings.map((f) => `- **${f.rule} ${f.severity}** \`${f.clip ?? '-'}\`${f.frame != null ? ` f${String(f.frame).padStart(3, '0')}` : ''}: ${f.msg}`),
];
writeFileSync(resolve(out, 'audit.md'), lines.join('\n') + '\n');

console.log(`ART AUDIT: ${result.defects ? 'FAIL' : 'PASS'} — ${result.clips} clips, ${result.defects} DEFECT, ${result.flags} FLAG (report: ${resolve(out, 'audit.md')})`);
for (const f of result.findings.filter((x) => x.severity === 'DEFECT').slice(0, 25)) {
  console.log(`  ${f.rule} ${f.clip ?? ''}${f.frame != null ? ` f${f.frame}` : ''}: ${f.msg}`);
}
if (result.defects > 25) console.log(`  … ${result.defects - 25} more in audit.md`);
process.exit(result.defects ? 1 : 0);
