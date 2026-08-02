#!/usr/bin/env node
// tool/gen_feed.mjs — 读取 posts + essays markdown，生成 RSS 2.0 feed.xml
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse as parseYaml } from 'yaml';

const SITE_URL = process.env.SITE_URL || 'https://mirage.example.com';
const OUTPUT = process.argv[2] || 'build/web/feed.xml';
const MAX_ITEMS = 20;

// 内容目录可用 --content <dir> 覆盖，默认 assets/content
const contentArg = process.argv.find((a) => a === '--content');
const contentDir = contentArg && process.argv[process.argv.indexOf(contentArg) + 1]
  ? process.argv[process.argv.indexOf(contentArg) + 1]
  : 'content';

function parseFrontmatter(text) {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return { meta: {}, body: text };
  const meta = parseYaml(match[1]) || {};
  const body = text.slice(match[0].length).trim();
  return { meta, body };
}

function scanDir(dir) {
  if (!existsSync(dir)) return [];
  const items = [];
  for (const file of readdirSync(dir)) {
    if (!file.endsWith('.md')) continue;
    const raw = readFileSync(join(dir, file), 'utf-8');
    const { meta, body } = parseFrontmatter(raw);
    const slug = file.replace(/\.md$/, '');
    items.push({ slug, ...meta, body });
  }
  return items;
}

function escXml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// 扫描内容目录
const contentRoot = join(import.meta.dirname, '..', 'assets', contentDir);
const posts = scanDir(join(contentRoot, 'posts')).map(i => ({ ...i, link: `/blog/${i.slug}` }));
const essays = scanDir(join(contentRoot, 'essays')).map(i => ({ ...i, link: `/essays/${i.slug}` }));

const items = [...posts, ...essays]
  .sort((a, b) => new Date(b.date) - new Date(a.date))
  .slice(0, MAX_ITEMS);

const now = new Date().toUTCString();

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
  <title>Mirage</title>
  <link>${SITE_URL}</link>
  <description>A personal site built with Flutter.</description>
  <lastBuildDate>${now}</lastBuildDate>
${items.map(i => `  <item>
    <title>${escXml(i.title || i.slug)}</title>
    <link>${SITE_URL}${i.link}</link>
    <pubDate>${new Date(i.date).toUTCString()}</pubDate>
    <description>${escXml(i.summary || '')}</description>
  </item>`).join('\n')}
</channel>
</rss>
`;

writeFileSync(OUTPUT, xml, 'utf-8');
console.log(`feed.xml generated → ${OUTPUT} (${items.length} items)`);
