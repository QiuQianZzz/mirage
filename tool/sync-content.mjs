#!/usr/bin/env node
/**
 * 内容物化脚本：把「生效内容源」同步到 `assets/content_effective/`。
 *
 * Flutter Web 无法直接递归打包声明目录的子目录，且 git 子模块目录的资源也
 * 常被打包遗漏。因此把内容源（本地仓库或子模块）复制到一个普通目录
 * `assets/content_effective/`，由 pubspec 显式登记「根目录 + 各子目录」，供
 * Flutter 打包。
 *
 * 内容源默认读取 `assets/config/app.yaml` 的 `content` 段；也可用命令参数覆盖：
 *   --content <articles|content_override|...>  直接指定内容目录（最高优先级）
 *   --source <local|submodule>                 覆盖 source 配置的分支选择
 *
 * `photos/index.yaml` 中写死的绝对路径前缀会被改写为 `assets/content_effective/`，
 * 与打包后的真实路径保持一致。
 */
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const CONTENT_DIR = 'content_effective'; // 应用内读取的内容目录名

/** 内容区所在的文件系统目录 */
const CONTENT_PATH = `assets/${CONTENT_DIR}`;

/** 应用支持的内容分区，物化时确保这些子目录都存在，保证 pubspec 引用不落空 */
const ZONES = ['posts', 'projects', 'skills', 'essays', 'photos'];

/** 读取 assets/config/app.yaml 的基础设施配置。 */
export function readConfig() {
  const yaml = readFileSync('assets/config/app.yaml', 'utf-8');
  return {
    source: yaml.match(/^\s*source:\s*([^\s\r]+)/m)?.[1] ?? 'local',
    local: yaml.match(/^\s*local_path:\s*([^\s\r]+)/m)?.[1] ?? 'content',
    sub: yaml.match(/^\s*submodule_path:\s*([^\s\r]+)/m)?.[1] ?? 'content_override',
  };
}

/** 解析命令行内容相关参数：--content <dir>、--source <local|submodule>。 */
export function parseContentArgs(argv = []) {
  let contentDir;
  let sourceOverride;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if ((a === '--content' || a === '-c') && argv[i + 1]) {
      contentDir = argv[i + 1].trim();
      i++;
    } else if (a === '--source' && argv[i + 1]) {
      sourceOverride = argv[i + 1].trim();
      i++;
    }
  }
  return { contentDir, sourceOverride };
}

/** 依据配置 + 覆盖参数确定内容目录名。 */
export function resolveContentDir(opts = {}) {
  const { contentDir, sourceOverride } = opts;
  if (contentDir) return contentDir;
  const c = readConfig();
  return (sourceOverride || c.source) === 'submodule' ? c.sub : c.local;
}

function copyDir(src, dst) {
  if (!existsSync(src)) return;
  mkdirSync(dst, { recursive: true });
  for (const entry of readdirSync(src, { withFileTypes: true })) {
    if (entry.name === '.git') continue;
    const s = join(src, entry.name);
    const d = join(dst, entry.name);
    if (entry.isDirectory()) {
      copyDir(s, d);
    } else if (entry.name === 'index.yaml') {
      const text = readFileSync(s, 'utf-8')
        .replaceAll('assets/content_override/', `assets/${CONTENT_DIR}/`)
        .replaceAll('assets/content/', `assets/${CONTENT_DIR}/`);
      writeFileSync(d, text, 'utf-8');
    } else {
      writeFileSync(d, readFileSync(s));
    }
  }
}

export function syncContent(opts = {}) {
  const contentDir = resolveContentDir(opts);
  rmSync(CONTENT_PATH, { recursive: true, force: true });
  copyDir(`assets/${contentDir}`, CONTENT_PATH);
  // 确保所有分区目录存在，来源缺少的分区会渲染为空而非缺失
  for (const zone of ZONES) mkdirSync(`${CONTENT_PATH}/${zone}`, { recursive: true });
  return `${contentDir} -> ${CONTENT_PATH}`;
}

/** 从内容区 site.yaml 读取站点标题与站点名（供占位符注入）。 */
export function readSiteConfig(contentDir) {
  const yaml = readFileSync(`assets/${contentDir}/site.yaml`, 'utf-8');
  const title = yaml.match(/^\s*title:\s*([^\r\n]+)/m)?.[1]?.trim() ?? 'QiuQianZzz';
  const siteName = yaml.match(/^\s*site_name:\s*([^\r\n]+)/m)?.[1]?.trim() ?? 'Mirage';
  return { title, siteName };
}

const scriptPath = fileURLToPath(import.meta.url).replace(/\\/g, '/');
const isMain =
  process.argv[1] &&
  scriptPath.endsWith(process.argv[1].replace(/\\/g, '/'));

if (isMain) {
  try {
    const opts = parseContentArgs(process.argv.slice(2));
    console.log(`[sync-content] ${syncContent(opts)}`);
  } catch (err) {
    console.error('[sync-content] failed:', err.message);
    process.exit(1);
  }
}