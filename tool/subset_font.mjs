#!/usr/bin/env node
/**
 * 按需子集化中文字体。
 *
 * 扫描站点实际使用到的全部字符（lib/ 源码、assets/ 配置与 Markdown 内容、
 * web/ 页面），仅将 Noto Sans SC 中出现的字符打进子集字体，
 * 大幅缩小包体（完整字体 ~17MB → 通常几十到几百 KB）。
 *
 * 用法：
 *   node tool/subset_font.mjs
 *   node tool/subset_font.mjs --font=path/to/NotoSansSC.ttf   # 指定源字体
 *
 * 源字体查找顺序：
 *   1. --font= 参数
 *   2. 环境变量 NOTO_SANS_SC
 *   3. 系统临时目录（缺失时自动从 GitHub 下载完整版 ~17MB）
 *
 * 输出到 assets/fonts/NotoSansSC-Subset.ttf。
 *
 * 注意：编辑文章/配置/代码新增字符后，需重新运行本脚本再构建站点。
 */
import { promises as fs } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import subsetFont from 'subset-font';

const ROOT = path.resolve(fileURLToPath(new URL('..', import.meta.url)));
const OUT_FONT = path.join(ROOT, 'assets', 'fonts', 'NotoSansSC-Subset.ttf');
const DEFAULT_SRC = path.join(tmpdir(), 'mirage-fonts', 'NotoSansSC.ttf');
const FONT_SOURCES = [
  'https://github.com/google/fonts/raw/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf',
  'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf',
  'https://fastly.jsdelivr.net/gh/google/fonts@main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf',
];

async function downloadFont(dest) {
  for (let attempt = 1; attempt <= 3; attempt++) {
    for (const url of FONT_SOURCES) {
      try {
        const resp = await fetch(url, { signal: AbortSignal.timeout(120_000) });
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
        const buf = Buffer.from(await resp.arrayBuffer());
        if (buf.length < 1_000_000) throw new Error(`文件过小 ${buf.length}B`);
        await fs.writeFile(dest, buf);
        console.log(`下载完成：${dest}（来自 ${url}）`);
        return;
      } catch (err) {
        console.warn(`  [${url}] 失败：${err.message}`);
      }
    }
    if (attempt < 3) {
      console.warn(`第 ${attempt} 轮下载失败，2 秒后重试…`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  throw new Error('多次尝试后仍无法下载源字体，可手动下载后通过 --font= 指定路径。');
}

// 始终保留的基础字符：ASCII 可打印 + 常用中文标点 + 空白。
const BASE_CHARS = [
  ...range(0x20, 0x7e), // ASCII 可打印
  0xa0, 0x2000, 0x2002, 0x2003, 0x2009, 0x2013, 0x2014, // 空格/连字符
  0x3000, // 全角空格
  ...range(0x3001, 0x3003), // 、。《  》→ 常用中文标点
  0x300a, 0x300b, 0x300e, 0x300f, 0x3010, 0x3011, // 《》「」『』【】
  0x2018, 0x2019, 0x201c, 0x201d, // ‘ “ ”
  0xff01, 0xff08, 0xff09, 0xff0c, 0xff0e, 0xff1a, 0xff1b, 0xff1f, // ！（）,．：；？
  0xff20, 0xff5e, 0xff05, 0xff06, 0xff03, 0xff04, 0xff0a, 0xff0b, // ＠～％＃＄×＋
  0xff0d, 0xff1d, 0x00d7, 0x00f7, // 各种符号
  0x200b, 0xfeff, // 零宽空格 / BOM
];

function* range(start, end) {
  for (let i = start; i <= end; i++) yield i;
}

async function resolveSourceFont() {
  const arg = process.argv.find((a) => a.startsWith('--font='));
  const candidates = [
    arg && arg.slice('--font='.length),
    process.env.NOTO_SANS_SC,
    DEFAULT_SRC,
  ].filter(Boolean);

  for (const file of candidates) {
    try {
      await fs.access(file);
      console.log(`使用源字体：${file}`);
      return file;
    } catch {
      /* 继续尝试下一个 */
    }
  }

  // 全部缺失：自动下载完整版。
  console.log('未找到源字体，正在下载完整版 Noto Sans SC（约 17MB）…');
  const dest = candidates[candidates.length - 1];
  await fs.mkdir(path.dirname(dest), { recursive: true });
  await downloadFont(dest);
  return dest;
}

async function collectSourceText() {
  const sources = [];
  for (const dir of ['lib', 'assets', 'web'].map((d) => path.join(ROOT, d))) {
    await walk(dir, (file) => {
      if (/\.(dart|md|yaml|yml|html|json)$/.test(file)) {
        sources.push(file);
      }
    });
  }
  const chars = new Set(BASE_CHARS);
  for (const file of sources) {
    let text;
    try {
      text = await fs.readFile(file, 'utf8');
    } catch {
      continue;
    }
    for (const ch of text) {
      chars.add(ch.codePointAt(0));
    }
  }
  return chars;
}

async function walk(dir, onFile) {
  let entries;
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      await walk(full, onFile);
    } else if (entry.isFile()) {
      onFile(full);
    }
  }
}

async function main() {
  const srcFont = await resolveSourceFont();
  const chars = await collectSourceText();
  const text = Array.from(chars)
    .map((cp) => String.fromCodePoint(cp))
    .join('');

  const src = await fs.readFile(srcFont);
  const subset = await subsetFont(src, text, { targetFormat: 'truetype' });

  await fs.mkdir(path.dirname(OUT_FONT), { recursive: true });
  await fs.writeFile(OUT_FONT, subset);

  const srcSize = (src.length / 1024 / 1024).toFixed(1);
  const outSize = (subset.length / 1024).toFixed(1);
  console.log(
    `子集化完成：唯一字符 ${chars.size} 个，` +
      `${srcSize}MB → ${outSize}KB，输出 ${OUT_FONT}`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
