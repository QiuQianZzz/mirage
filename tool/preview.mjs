#!/usr/bin/env node
/**
 * 本地预览已构建的站点（build/web）。
 *
 * 用法：
 *   node tool/preview.mjs            # 默认端口 8080，自动打开浏览器
 *   node tool/preview.mjs --port=9000
 *   node tool/preview.mjs --no-open
 *
 * 服务端会对 js/wasm/ttf 等做 gzip 压缩并支持 SPA 路由回退，
 * 模拟线上静态托管，便于评估真实的加载体验。
 * 浏览器 DevTools 控制台可查看 [boot] 各阶段耗时日志。
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(fileURLToPath(new URL('..', import.meta.url)));
const WEB = path.join(ROOT, 'build', 'web');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=utf-8',
  '.xml': 'application/rss+xml; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8',
};
const GZ = /\.(js|mjs|wasm|json|html|ttf|otf|css|txt|map)$/;

const portArg = process.argv.find((a) => a.startsWith('--port='));
const port = portArg ? Number(portArg.slice('--port='.length)) || 8080 : 8080;
const shouldOpen = !process.argv.includes('--no-open');

if (!fs.existsSync(WEB)) {
  console.error('未找到 build/web，请先构建：');
  console.error('  node tool/subset_font.mjs');
  console.error('  flutter build web --release --no-web-resources-cdn');
  process.exit(1);
}

http
  .createServer((req, res) => {
    const url = decodeURIComponent((req.url || '/').split('?')[0]);
    let file = path.join(WEB, url === '/' ? '/index.html' : url);

    if (!file.startsWith(path.resolve(WEB))) {
      res.writeHead(403);
      res.end();
      return;
    }

    fs.readFile(file, (err, data) => {
      // SPA 回退：无扩展名的路径视为前端路由，返回 index.html。
      if (err && !path.extname(file)) {
        file = path.join(WEB, 'index.html');
        data = null;
        fs.readFile(file, (err2, buf) => {
          if (err2) {
            res.writeHead(404);
            res.end('not found');
            return;
          }
          respond(req, res, file, buf);
        });
        return;
      }
      if (err) {
        res.writeHead(404);
        res.end('not found');
        return;
      }
      respond(req, res, file, data);
    });
  })
  .listen(port, '127.0.0.1', () => {
    const url = `http://127.0.0.1:${port}/`;
    console.log(`预览服务已启动（gzip 压缩，模拟线上托管）：${url}`);
    console.log('按 Ctrl+C 停止。');
    if (shouldOpen) openBrowser(url);
  });

function respond(req, res, file, data) {
  const type = MIME[path.extname(file)] || 'application/octet-stream';
  const accept = req.headers['accept-encoding'] || '';
  if (GZ.test(file) && accept.includes('gzip')) {
    zlib.gzip(data, (err, buf) => {
      if (err) {
        res.writeHead(500);
        res.end();
        return;
      }
      res.writeHead(200, { 'Content-Type': type, 'Content-Encoding': 'gzip' });
      res.end(buf);
    });
  } else {
    res.writeHead(200, { 'Content-Type': type });
    res.end(data);
  }
}

function openBrowser(url) {
  if (process.platform === 'win32') {
    const child = spawn('cmd', ['/c', 'start', '', url], { detached: true, stdio: 'ignore' });
    child.unref();
  } else {
    const child = spawn(process.platform === 'darwin' ? 'open' : 'xdg-open', [url], {
      detached: true,
      stdio: 'ignore',
    });
    child.unref();
  }
}
