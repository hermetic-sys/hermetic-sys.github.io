// Runs before first paint: stored choice, then the system preference, then dark.
(function () {
  var t = null;
  try { t = localStorage.getItem('hermetic-theme'); } catch (e) {}
  if (t !== 'light' && t !== 'dark') {
    t = (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) ? 'light' : 'dark';
  }
  document.documentElement.setAttribute('data-theme', t);
})();
