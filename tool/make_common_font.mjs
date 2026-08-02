#!/usr/bin/env node
/**
 * 一次性生成"够用字库"：从完整 Noto Sans SC 中取出 GB2312 一二级（6763 个常用/次常用汉字）
 * + ASCII 与常用标点，输出一个约几 MB、覆盖简体中文日常写作的字体，提交进仓库，
 * 供 tool/subset_font.mjs 离线从中再生成每页 ~0.5MB 的小子集。
 *
 * 用法（需要完整源字体 ~17MB 一次）：
 *   node tool/make_common_font.mjs [--source=path/NotoSansSC.ttf] [--out=tool/fonts/NotoSansSC-Common.ttf]
 *
 * 不带 --source 时按 tool/subset_font.mjs 的查找顺序找源字体。
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import iconv from 'iconv-lite';

const ROOT = path.resolve(fileURLToPath(new URL('..', import.meta.url)));
const DEFAULT_OUT = path.join(ROOT, 'tool', 'fonts', 'NotoSansSC-Common.ttf');

function* range(a, b) {
  for (let i = a; i <= b; i++) yield i;
}

// 与 subset_font.mjs 保持一致的基础字符：ASCII 可打印 + 常用中文标点 + 空白
const BASE = [
  ...range(0x20, 0x7e),
  0xa0, 0x2000, 0x2002, 0x2003, 0x2009, 0x2013, 0x2014,
  0x3000,
  ...range(0x3001, 0x3003),
  0x300a, 0x300b, 0x300e, 0x300f, 0x3010, 0x3011,
  0x2018, 0x2019, 0x201c, 0x201d,
  0xff01, 0xff08, 0xff09, 0xff0c, 0xff0e, 0xff1a, 0xff1b, 0xff1f,
  0xff20, 0xff5e, 0xff05, 0xff06, 0xff03, 0xff04, 0xff0a, 0xff0b,
  0xff0d, 0xff1d, 0x00d7, 0x00f7,
  0x200b, 0xfeff,
];

// 枚举 GB2312 一、二级汉字（共 6763 个）→ Unicode 码点。
// 一级：区 16–55（lead 0xB0–0xD7）；二级：区 56–87（lead 0xD8–0xF7）。
function gb2312Chars() {
  const out = [];
  const addBand = (leadFrom, leadTo) => {
    for (let lead = leadFrom; lead <= leadTo; lead++) {
      for (let trail = 0xa1; trail <= 0xfe; trail++) {
        try {
          const s = iconv.decode(Buffer.from([lead, trail]), 'gb2312');
          if (s && s.length === 1) out.push(s.codePointAt(0));
        } catch {
          /* 网格中的空闲位，跳过 */
        }
      }
    }
  };
  addBand(0xb0, 0xd7); // 一级 3755
  addBand(0xd8, 0xf7); // 二级 3008
  return out;
}

// 基础符号（汉字之外的中文标点等）
const MISC = [0x3005, 0x3006, 0x3007, 0x303b];

const chars = new Set([...BASE, ...gb2312Chars(), ...MISC]);

function arg(name) {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(`--${name}=`.length) : undefined;
}

async function main() {
  const outPath = arg('out') || DEFAULT_OUT;
  const explicit = arg('source');

  let src;
  if (explicit) {
    try {
      await fs.access(explicit);
      src = explicit;
    } catch {
      throw new Error(`--source 指定的字体不存在：${explicit}`);
    }
  } else {
    const candidates = [
      path.join(ROOT, 'tool', '.fonts', 'NotoSansSC.ttf'),
      path.join(ROOT, 'tool', 'fonts', 'NotoSansSC-Common.ttf'),
    ];
    src = candidates.find((f) => {
      try {
        fs.accessSync(f);
        return true;
      } catch {
        return false;
      }
    });
    if (!src) {
      throw new Error('未找到源字体。请先用浏览器/任意方式下载完整 Noto Sans SC（约 17MB），\n' +
        '然后通过 --source 指定路径，例如：\n' +
        '  node tool/make_common_font.mjs --source="D:/Downloads/NotoSansSC.ttf"');
    }
  }

  const raw = await fs.readFile(src);
  const { default: subsetFont } = await import('subset-font');
  const text = Array.from(chars)
    .sort((a, b) => a - b)
    .map((cp) => String.fromCodePoint(cp))
    .join('');
  const result = await subsetFont(raw, text, { targetFormat: 'truetype' });

  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.writeFile(outPath, result);

  const srcSize = (raw.length / 1024 / 1024).toFixed(1);
  const outSize = (result.length / 1024 / 1024).toFixed(1);
  console.log(`够用字库生成完成：${chars.size} 字，${srcSize}MB → ${outSize}MB，输出 ${outPath}`);
  console.log('请提交该文件（tool/fonts/NotoSansSC-Common.ttf），此后 CI/本地即可离线构建。');
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});