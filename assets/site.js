// Hermetic site behaviour: theme toggle, mobile menu, tabs, copy buttons, hero word, scroll reveal.
(function () {
  var root = document.documentElement;
  // Reveal-on-scroll styles apply only once this script runs, so a page whose
  // script failed to load still shows everything.
  root.classList.add('js');
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Theme toggle
  var toggle = document.getElementById('theme-toggle');
  if (toggle) {
    toggle.addEventListener('click', function () {
      var next = root.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem('hermetic-theme', next); } catch (e) {}
    });
  }

  // Mobile drawer
  var menuBtn = document.getElementById('menu-btn');
  var drawer = document.getElementById('drawer');
  if (menuBtn && drawer) {
    menuBtn.addEventListener('click', function () {
      var open = drawer.classList.toggle('open');
      menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    drawer.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') {
        drawer.classList.remove('open');
        menuBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // Tabs (ARIA tablist)
  Array.prototype.forEach.call(document.querySelectorAll('[role="tablist"]'), function (list) {
    var tabs = Array.prototype.slice.call(list.querySelectorAll('[role="tab"]'));
    function select(tab) {
      tabs.forEach(function (t) {
        var on = t === tab;
        t.setAttribute('aria-selected', on ? 'true' : 'false');
        t.tabIndex = on ? 0 : -1;
        var p = document.getElementById(t.getAttribute('aria-controls'));
        if (p) p.hidden = !on;
      });
    }
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () { select(t); });
      t.addEventListener('keydown', function (e) {
        var j = null;
        if (e.key === 'ArrowRight') j = (i + 1) % tabs.length;
        if (e.key === 'ArrowLeft') j = (i - 1 + tabs.length) % tabs.length;
        if (j !== null) { e.preventDefault(); tabs[j].focus(); select(tabs[j]); }
      });
    });
  });

  // Copy buttons copy the text of the <pre> they sit above, without prompts or comments
  Array.prototype.forEach.call(document.querySelectorAll('.copy'), function (btn) {
    btn.addEventListener('click', function () {
      var pre = btn.closest('.term').querySelector('pre');
      var lines = pre.innerText.split('\n').filter(function (l) { return /^\$ /.test(l); })
        .map(function (l) { return l.slice(2); });
      var text = lines.length ? lines.join('\n') : pre.innerText;
      if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = 'copied';
          setTimeout(function () { btn.textContent = 'copy'; }, 1400);
        }, function () {});
      }
    });
  });

  // Hero word
  var swap = document.querySelector('.swap');
  if (swap && !reduce) {
    var words = (swap.getAttribute('data-words') || '').split('|').filter(Boolean);
    var i = 0;
    if (words.length > 1) {
      setInterval(function () {
        i = (i + 1) % words.length;
        swap.classList.remove('fade');
        void swap.offsetWidth;
        swap.textContent = words[i];
        swap.classList.add('fade');
      }, 2600);
    }
  }

  // Scroll reveal
  var items = document.querySelectorAll('.rv');
  if (!('IntersectionObserver' in window) || reduce) {
    Array.prototype.forEach.call(items, function (el) { el.classList.add('in'); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
      });
    }, { rootMargin: '0px 0px -8% 0px' });
    Array.prototype.forEach.call(items, function (el) { io.observe(el); });
  }

  var y = document.getElementById('year');
  if (y) y.textContent = String(new Date().getFullYear());
})();
