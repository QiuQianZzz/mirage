#!/usr/bin/env node
/**
 * 开发模式脚本：替换占位符 → 启动 flutter run → 退出时恢复。
 *
 * 用法：
 *   node tool/dev.mjs -d edge                     # 指定设备（默认 chrome）
 *   node tool/dev.mjs -d edge --source local     # 覆盖内容源为 local
 *   node tool/dev.mjs --content content_override  # 直接用指定内容目录
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { syncContent, parseContentArgs, resolveContentDir, readSiteConfig } from './sync-content.mjs';

const args = process.argv.slice(2);
const contentOpts = parseContentArgs(args);

// 先物化内容源到 assets/content_effective/（不修改 app.yaml 也能切换内容源）
try {
  console.log(`[sync-content] ${syncContent(contentOpts)}`);
} catch (err) {
  console.error('[sync-content] failed:', err.message);
  process.exit(1);
}

const files = {
  'web/index.html': readFileSync('web/index.html', 'utf-8'),
  'web/manifest.json': readFileSync('web/manifest.json', 'utf-8'),
};

const dir = resolveContentDir(contentOpts);
const { title, siteName } = readSiteConfig(dir);

// 替换占位符
for (const [path, original] of Object.entries(files)) {
  const replaced = original
      .replaceAll('{{site_title}}', title)
      .replaceAll('{{site_name}}', siteName);
  writeFileSync(path, replaced, 'utf-8');
}

// 解析设备参数（仅 -d），其余被 sync 用到的标记不传给 flutter
const deviceIndex = args.indexOf('-d');
const deviceArg = deviceIndex >= 0
  ? `-d ${args[deviceIndex + 1]}`
  : '-d chrome';

const proc = spawn('cmd', ['/c', 'flutter', 'run', ...deviceArg.split(' ')], {
  stdio: 'inherit',
  cwd: process.cwd(),
});

// 退出时恢复占位符
function restore() {
  for (const [path, original] of Object.entries(files)) {
    writeFileSync(path, original, 'utf-8');
  }
}

proc.on('exit', () => { restore(); process.exit(); });
process.on('SIGINT', () => { restore(); process.exit(); });
process.on('SIGTERM', () => { restore(); process.exit(); });