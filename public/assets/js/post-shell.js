/* ============================================================
   文章正文页 & 404 页统一交互外壳（零依赖原生 JS）
   与首页共享 theme / hue 偏好，自动挂载星空横幅、悬浮导航、进度条与快捷目录
   ============================================================ */
(function () {
  var root = document.documentElement;
  var body = document.body;
  if (!body || body.dataset.v3ShellInit) return;
  body.dataset.v3ShellInit = '1';
  body.classList.add('v3-post-ready');

  // 1. 顶部阅读进度条
  var progress = document.createElement('div');
  progress.className = 'v3-progress';
  progress.setAttribute('aria-hidden', 'true');
  body.prepend(progress);

  // 2. 顶部悬浮毛玻璃导航 + 主题色盘
  var navWrap = document.createElement('div');
  navWrap.className = 'v3-nav-wrap';
  navWrap.innerHTML =
    '<header class="v3-navbar" id="v3Navbar">' +
      '<a class="v3-brand" href="/">' +
        '<img src="/assets/covers/avatar.jpg" alt="繁星若尘" width="30" height="30" />' +
        '<span>繁星若尘</span>' +
      '</a>' +
      '<nav class="v3-nav-links" aria-label="主导航">' +
        '<a href="/">首页</a>' +
        '<a href="/about/">关于</a>' +
        '<a href="https://www.xiaohongshu.com/user/profile/60cb6efc000000000101d62b" target="_blank" rel="noopener">小红书</a>' +
        '<a href="https://github.com/aosudh" target="_blank" rel="noopener">GitHub</a>' +
        '<a href="/classic.html" title="切换到保留的原始极简版首页">原版入口</a>' +
      '</nav>' +
      '<div class="v3-nav-tools">' +
        '<button class="v3-icon-btn" id="paletteToggle" type="button" aria-label="自定义主题色" title="主题色盘">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
            '<circle cx="13.5" cy="6.5" r=".5" fill="currentColor"></circle>' +
            '<circle cx="17.5" cy="10.5" r=".5" fill="currentColor"></circle>' +
            '<circle cx="8.5" cy="7.5" r=".5" fill="currentColor"></circle>' +
            '<circle cx="6.5" cy="12.5" r=".5" fill="currentColor"></circle>' +
            '<path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"></path>' +
          '</svg>' +
        '</button>' +
        '<button class="v3-icon-btn" id="themeToggle" type="button" aria-label="切换浅色或深色主题" title="切换浅/深色">' +
          '<svg id="themeIcon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
            '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>' +
          '</svg>' +
        '</button>' +
      '</div>' +
    '</header>';

  var palettePopover = document.createElement('div');
  palettePopover.className = 'palette-popover';
  palettePopover.id = 'palettePopover';
  palettePopover.setAttribute('role', 'dialog');
  palettePopover.setAttribute('aria-label', '主题色调节');
  palettePopover.innerHTML =
    '<div class="palette-head"><span class="palette-title">主题色 Hue</span><span class="palette-val" id="hueVal">222</span></div>' +
    '<input class="hue-slider" id="hueSlider" type="range" min="0" max="360" step="1" value="222" aria-label="主题色相" />' +
    '<div class="palette-presets">' +
      '<button class="hue-dot" type="button" data-hue="222" style="background:hsl(222,78%,54%)" title="星夜蓝"></button>' +
      '<button class="hue-dot" type="button" data-hue="258" style="background:hsl(258,76%,60%)" title="星云紫"></button>' +
      '<button class="hue-dot" type="button" data-hue="186" style="background:hsl(186,78%,44%)" title="极光青"></button>' +
      '<button class="hue-dot" type="button" data-hue="152" style="background:hsl(152,68%,44%)" title="翡翠绿"></button>' +
      '<button class="hue-dot" type="button" data-hue="34" style="background:hsl(34,88%,52%)" title="琥珀金"></button>' +
      '<button class="hue-dot" type="button" data-hue="338" style="background:hsl(338,78%,58%)" title="樱花粉"></button>' +
      '<button class="hue-reset" id="hueReset" type="button">重置</button>' +
    '</div>';

  // 3. 紧凑星空横幅 + 4 层动态波浪
  var banner = document.createElement('div');
  banner.className = 'v3-post-banner';
  banner.setAttribute('aria-hidden', 'true');
  banner.innerHTML =
    '<div class="v3-post-banner-bg"></div>' +
    '<div class="v3-post-banner-overlay"></div>' +
    '<svg class="v3-post-waves" viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">' +
      '<defs><path id="post-gentle-wave" d="M-160 44c30 0 58-18 88-18s 58 18 88 18 58-18 88-18 58 18 88 18 v44h-352z" /></defs>' +
      '<g class="parallax">' +
        '<use href="#post-gentle-wave" x="48" y="0" />' +
        '<use href="#post-gentle-wave" x="48" y="3" />' +
        '<use href="#post-gentle-wave" x="48" y="5" />' +
        '<use href="#post-gentle-wave" x="48" y="7" />' +
      '</g>' +
    '</svg>';

  var wrap = document.querySelector('.wrap');
  if (wrap) {
    body.insertBefore(navWrap, wrap);
    body.insertBefore(palettePopover, wrap);
    body.insertBefore(banner, wrap);
  } else {
    body.prepend(banner);
    body.prepend(palettePopover);
    body.prepend(navWrap);
  }

  // 4. 统一页脚文案
  var footer = document.querySelector('.site-footer');
  if (footer) {
    footer.innerHTML =
      '<span>© 2026 繁星若尘 · aosudh.github.io</span>' +
      '<span><a href="/">返回首页</a> · <a href="/classic.html">原版入口</a> · ' +
      '<a href="https://www.xiaohongshu.com/user/profile/60cb6efc000000000101d62b" target="_blank" rel="noopener">小红书</a> · ' +
      '由 <a href="https://pages.github.com" target="_blank" rel="noopener">GitHub Pages</a> 托管</span>';
  }

  // 5. 明暗主题切换（与首页同步 localStorage）
  var themeToggle = document.getElementById('themeToggle');
  var themeIcon = document.getElementById('themeIcon');
  var mediaDark = window.matchMedia('(prefers-color-scheme: dark)');
  function effTheme() {
    var a = root.getAttribute('data-theme');
    return (a === 'dark' || a === 'light') ? a : (mediaDark.matches ? 'dark' : 'light');
  }
  function syncThemeIcon() {
    var isDark = effTheme() === 'dark';
    themeIcon.innerHTML = isDark
      ? '<circle cx="12" cy="12" r="4"></circle><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"></path>'
      : '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>';
    themeToggle.title = isDark ? '切换到浅色模式' : '切换到深色模式';
  }
  syncThemeIcon();
  themeToggle.addEventListener('click', function () {
    var next = effTheme() === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem('site-theme', next); } catch (e) {}
    syncThemeIcon();
  });

  // 6. 主题色盘（与首页同步 localStorage）
  var paletteToggle = document.getElementById('paletteToggle');
  var hueSlider = document.getElementById('hueSlider');
  var hueVal = document.getElementById('hueVal');
  var hueReset = document.getElementById('hueReset');
  function setHue(val) {
    var v = String(Math.min(360, Math.max(0, Number(val) || 222)));
    root.style.setProperty('--hue', v);
    hueSlider.value = v;
    hueVal.textContent = v;
    try { localStorage.setItem('site-v3-hue', v); } catch (e) {}
  }
  try {
    var savedHue = localStorage.getItem('site-v3-hue');
    if (savedHue !== null) setHue(savedHue);
  } catch (e) {}

  paletteToggle.addEventListener('click', function (e) {
    e.stopPropagation();
    var open = palettePopover.classList.toggle('is-open');
    paletteToggle.classList.toggle('is-active', open);
  });
  document.addEventListener('click', function (e) {
    if (!palettePopover.contains(e.target) && e.target !== paletteToggle) {
      palettePopover.classList.remove('is-open');
      paletteToggle.classList.remove('is-active');
    }
  });
  hueSlider.addEventListener('input', function () { setHue(this.value); });
  hueReset.addEventListener('click', function () { setHue(222); });
  Array.prototype.forEach.call(palettePopover.querySelectorAll('.hue-dot'), function (dot) {
    dot.addEventListener('click', function () { setHue(this.getAttribute('data-hue')); });
  });

  // 7. 悬浮快捷目录 + 返回顶部
  var fabStack = document.createElement('div');
  fabStack.className = 'v3-fab-stack';

  var article = document.querySelector('article.post-content');
  var headings = article
    ? Array.prototype.slice.call(article.querySelectorAll('h2, h3')).filter(function (h) {
        return !h.closest('.article-toc, .toc, .manual-toc, .section-nav') && h.textContent.trim().length > 0;
      })
    : [];

  var tocLinks = [];
  if (headings.length >= 3) {
    var tocDrawer = document.createElement('aside');
    tocDrawer.className = 'v3-toc-drawer';
    tocDrawer.setAttribute('aria-label', '文章目录');
    tocDrawer.innerHTML =
      '<div class="v3-toc-head"><span>文章目录</span><button class="v3-toc-close" type="button" aria-label="关闭目录">×</button></div>' +
      '<ul class="v3-toc-list"></ul>';
    var tocList = tocDrawer.querySelector('.v3-toc-list');

    headings.forEach(function (h, idx) {
      if (!h.id) h.id = 'sec-auto-' + (idx + 1);
      var li = document.createElement('li');
      if (h.tagName === 'H3') li.className = 'is-h3';
      var a = document.createElement('a');
      a.href = '#' + h.id;
      a.textContent = h.textContent.trim();
      a.addEventListener('click', function () {
        if (window.innerWidth <= 760) {
          tocDrawer.classList.remove('is-open');
          tocBtn.classList.remove('is-active');
        }
      });
      li.appendChild(a);
      tocList.appendChild(li);
      tocLinks.push({ id: h.id, el: h, link: a });
    });

    var tocBtn = document.createElement('button');
    tocBtn.className = 'v3-fab';
    tocBtn.type = 'button';
    tocBtn.title = '文章目录';
    tocBtn.setAttribute('aria-label', '打开文章目录');
    tocBtn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round"><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></svg>';
    tocBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      var open = tocDrawer.classList.toggle('is-open');
      tocBtn.classList.toggle('is-active', open);
    });
    tocDrawer.querySelector('.v3-toc-close').addEventListener('click', function () {
      tocDrawer.classList.remove('is-open');
      tocBtn.classList.remove('is-active');
    });
    document.addEventListener('click', function (e) {
      if (!tocDrawer.contains(e.target) && e.target !== tocBtn) {
        tocDrawer.classList.remove('is-open');
        tocBtn.classList.remove('is-active');
      }
    });
    fabStack.appendChild(tocBtn);
    body.appendChild(tocDrawer);
  }

  var backTop = document.createElement('button');
  backTop.className = 'v3-fab is-backtop';
  backTop.type = 'button';
  backTop.title = '返回顶部';
  backTop.setAttribute('aria-label', '返回顶部');
  backTop.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg>';
  backTop.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
  fabStack.appendChild(backTop);
  body.appendChild(fabStack);

  // 8. 滚动联动：顶栏毛玻璃 + 进度条 + 返回顶部 + 当前目录高亮
  var navbar = document.getElementById('v3Navbar');
  function onScroll() {
    var y = window.scrollY || 0;
    navbar.classList.toggle('is-scrolled', y > 100);
    backTop.classList.toggle('is-visible', y > 320);
    var docH = document.documentElement.scrollHeight - window.innerHeight;
    var pct = docH > 0 ? Math.min(100, Math.max(0, (y / docH) * 100)) : 0;
    progress.style.width = pct.toFixed(1) + '%';

    if (tocLinks.length) {
      var active = tocLinks[0];
      for (var i = 0; i < tocLinks.length; i++) {
        if (tocLinks[i].el.getBoundingClientRect().top <= 120) active = tocLinks[i];
        else break;
      }
      tocLinks.forEach(function (item) {
        item.link.classList.toggle('is-active', item === active);
      });
    }
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();
