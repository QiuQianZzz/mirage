{{flutter_js}}
{{flutter_build_config}}

// 自定义引导：驱动启动画面进度条 + 详细阶段提示，记录各阶段耗时与关键资源
// 传输量，引擎首帧渲染后隐藏启动画面。
(function () {
  var t0 = performance.now();
  var progress = 0;
  // 最小展示时长：让品牌 logo 动画（描线 + 朝阳弹出）能完整播放。
  // 应用加载更快时按此补足，更慢时不做额外等待。
  var MIN_HOLD = 1350;
  // 进度到 100% 后的停留，让「完成」状态与满格进度条可感知。
  var DONE_HOLD = 500;

  function setProgress(p, phase) {
    if (p > progress) progress = p;
    if (window.setBootProgress) window.setBootProgress(progress, phase);
    console.log('[boot] ' + Math.round(progress) + '% ' + (phase || '') +
      ' @ +' + (performance.now() - t0).toFixed(0) + 'ms');
  }

  // 加载阶段文案：命中缓存时无需重新下载，避免误导。
  function loadPhase() {
    return cached ? '正在读取缓存中的应用…' : '正在下载应用代码…';
  }

  // 预估是否命中缓存（用于加载阶段文案）：文档来自缓存，或页面已被
  // Service Worker 接管，通常意味着应用资源无需重新下载。
  function guessCached() {
    var nav = performance.getEntriesByType('navigation')[0];
    if (nav && nav.transferSize === 0) return true;
    if (navigator.serviceWorker && navigator.serviceWorker.controller) return true;
    return false;
  }

  // 对 main.dart.js 做「仅缓存」探测：命中 HTTP 缓存即说明是二次访问，
  // 用于尽早确定加载阶段文案。只读缓存、绝不发起网络请求，未命中即失败。
  function probeMainJsCache(done) {
    try {
      var url = new URL('main.dart.js', document.baseURI).toString();
      fetch(url, { cache: 'only-if-cached', mode: 'same-origin' })
        .then(function (r) { done(r.ok); })
        .catch(function () { done(false); });
    } catch (e) {
      done(false);
    }
  }

  // 二次访问最终判定：main.dart.js 传输量为 0 表示命中浏览器缓存 /
  // Service Worker，此时应用加载明显更快，无需为品牌动画补足等待时长。
  function isCachedLoad() {
    var entries = performance.getEntriesByType('resource');
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].name.indexOf('main.dart.js') !== -1) {
        return entries[i].transferSize === 0;
      }
    }
    return false;
  }

  function logResources() {
    var byName = {};
    performance.getEntriesByType('resource').forEach(function (r) { if (!byName[r.name]) byName[r.name] = r; });
    var keys = ['canvaskit.wasm', 'main.dart.js', 'NotoSansSC', 'MaterialIcons', 'CupertinoIcons'];
    keys.forEach(function (k) {
      Object.keys(byName).filter(function (n) { return n.indexOf(k) !== -1; }).forEach(function (n) {
        var r = byName[n];
        console.log('[boot] fetch ' + k + ': ' + (r.transferSize / 1024).toFixed(0) + 'KB, ' + r.duration.toFixed(0) + 'ms');
      });
    });
    var nav = performance.getEntriesByType('navigation')[0];
    if (nav) {
      console.log('[boot] navigation: dcl=' + (nav.domContentLoadedEventEnd - nav.startTime).toFixed(0) +
        'ms, load=' + (nav.loadEventEnd - nav.startTime).toFixed(0) +
        'ms, transfer=' + (nav.transferSize / 1024).toFixed(0) + 'KB');
    }
  }

  // 预估缓存状态（二次访问），拿到 main.dart.js 传输量后再用 isCachedLoad 修正。
  var cached = guessCached();

  setProgress(8, '正在初始化…');
  // 用「仅缓存」探测尽早确定加载阶段文案（命中即显示"读取缓存"）。
  probeMainJsCache(function (hit) {
    if (hit) cached = true;
    setProgress(14, loadPhase());
  });
  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      // main.dart.js 已加载并执行完成；此时可确定是否命中缓存。
      cached = isCachedLoad();
      setProgress(55, '正在启动渲染引擎…');
      var appRunner = await engineInitializer.initializeEngine();
      setProgress(82, '正在渲染页面…');
      await appRunner.runApp();
      setProgress(100, '完成');
      logResources();
      // 二次访问（缓存命中，加载极快）：短停留后立即进入，不为动画补足等待；
      // 首次/慢加载：补足到 MIN_HOLD 让品牌动画完整播放，并停留 DONE_HOLD
      // 让满格进度条与「完成」文案可感知。
      var elapsed = performance.now() - t0;
      var hold = cached ? 100 : Math.max(DONE_HOLD, MIN_HOLD - elapsed);
      setTimeout(function () { window.hideSplash && window.hideSplash(); }, hold);
    }
  }).catch(function (err) {
    console.error('Flutter 启动失败：', err);
    window.setBootProgress && window.setBootProgress(100, '加载失败');
    window.hideSplash && window.hideSplash();
  });
})();
