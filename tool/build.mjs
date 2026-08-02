#!/usr/bin/env node
/**
 * 一键构建脚本。
 *
 * 用法：
 *   node tool/build.mjs                      # 构建 + 生成 feed.xml
 *   node tool/build.mjs --preview            # 构建完自动启动预览
 *   node tool/build.mjs --no-cdn             # 不使用 CDN（国内部署）
 *   node tool/build.mjs --source local       # 覆盖内容源为 local
 *   node tool/build.mjs --content <dir>      # 直接用指定内容目录
 *   node tool/build.mjs --no-feed            # 跳过 feed.xml 生成
 *   node tool/build.mjs --no-subset          # 跳过字体子集化（CI 复用已提交子集）
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { syncContent, parseContentArgs, resolveContentDir, readSiteConfig } from './sync-content.mjs';

const args = process.argv.slice(2);
const preview = args.includes('--preview');
const noCdn = args.includes('--no-cdn');
const skipFeed = args.includes('--no-feed');
const skipSubset = args.includes('--no-subset');
const contentOpts = parseContentArgs(args);

function run(cmd) {
  console.log(`\n> ${cmd}`);
  execSync(cmd, { stdio: 'inherit', cwd: process.cwd() });
}

try {
  // 物化内容源，并确定生效内容目录
  console.log(`[sync-content] ${syncContent(contentOpts)}`);
  const dir = resolveContentDir(contentOpts);

  if (!skipSubset) {
    run('node tool/subset_font.mjs');
  } else {
    console.log('\n[subset_font] 跳过字体子集化（--no-subset），复用已提交子集。');
  }

  const buildFlags = `${noCdn ? '--no-web-resources-cdn' : ''} --wasm`;
  run(`flutter build web --release ${buildFlags}`);

  // 构建后替换 build/web/ 中的占位符（不修改源文件）
  const { title, siteName } = readSiteConfig(dir);
  console.log(`\n站点标题: ${title}`);
  console.log(`项目名称: ${siteName}`);

  const builtIndex = 'build/web/index.html';
  let html = readFileSync(builtIndex, 'utf-8');
  html = html.replaceAll('{{site_title}}', title);
  html = html.replaceAll('{{site_name}}', siteName);
  writeFileSync(builtIndex, html, 'utf-8');

  const builtManifest = 'build/web/manifest.json';
  let manifest = readFileSync(builtManifest, 'utf-8');
  manifest = manifest.replaceAll('{{site_title}}', title);
  manifest = manifest.replaceAll('{{site_name}}', siteName);
  writeFileSync(builtManifest, manifest, 'utf-8');

  if (!skipFeed) {
    run(`node tool/gen_feed.mjs build/web/feed.xml --content ${dir}`);
  }

  console.log('\n✅ 构建完成');

  if (preview) {
    run('node tool/preview.mjs');
  }
} catch (e) {
  console.error(`\n❌ 构建失败：${e && e.message ? e.message : e}`);
  process.exit(1);
}