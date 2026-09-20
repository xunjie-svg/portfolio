// Tan Xun Jie — portfolio
// Small, functional enhancements only: active-section nav highlighting (site nav and the
// work section's project jump-nav) and the image lightbox.
// No frameworks, no build step.

function initSectionNav(linkSelector) {
  var navLinks = Array.prototype.slice.call(document.querySelectorAll(linkSelector));
  var sections = navLinks
    .map(function (link) {
      var id = link.getAttribute('href').slice(1);
      return document.getElementById(id);
    })
    .filter(Boolean);

  if (!('IntersectionObserver' in window) || !sections.length) return;

  var setCurrent = function (id) {
    navLinks.forEach(function (link) {
      var isCurrent = link.getAttribute('href') === '#' + id;
      if (isCurrent) {
        link.setAttribute('data-current', 'true');
        link.setAttribute('aria-current', 'true');
      } else {
        link.removeAttribute('data-current');
        link.removeAttribute('aria-current');
      }
    });
  };

  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          setCurrent(entry.target.id);
        }
      });
    },
    { rootMargin: '-45% 0px -50% 0px', threshold: 0 }
  );

  sections.forEach(function (section) { observer.observe(section); });
}

initSectionNav('.nav a[data-nav]');
initSectionNav('.work-nav a[data-work-nav]');
initSectionNav('.work-nav a[data-student-nav]');

function initDropdownNav(toggleId, dropdownId) {
  var toggle = document.getElementById(toggleId);
  var dropdown = document.getElementById(dropdownId);
  if (!toggle || !dropdown) return;

  var MOBILE_QUERY = '(max-width: 1779.98px)';

  var isOpen = function () { return !dropdown.hidden; };

  var close = function () {
    dropdown.hidden = true;
    toggle.setAttribute('aria-expanded', 'false');
  };

  var open = function () {
    dropdown.hidden = false;
    toggle.setAttribute('aria-expanded', 'true');
  };

  toggle.addEventListener('click', function (e) {
    if (!window.matchMedia(MOBILE_QUERY).matches) return;
    e.preventDefault();
    if (isOpen()) { close(); } else { open(); }
  });

  document.addEventListener('click', function (e) {
    if (!isOpen()) return;
    if (e.target === toggle || toggle.contains(e.target) || dropdown.contains(e.target)) return;
    close();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && isOpen()) {
      close();
      toggle.focus();
    }
  });

  dropdown.addEventListener('click', function (e) {
    if (e.target.tagName === 'A') close();
  });
}

initDropdownNav('work-toggle', 'work-dropdown');
initDropdownNav('student-work-toggle', 'student-work-dropdown');

(function () {
  var lightbox = document.getElementById('lightbox');
  if (!lightbox) return;

  var lbImg = lightbox.querySelector('.lightbox-img');
  var lbCaption = lightbox.querySelector('.lightbox-caption');
  var closeBtn = lightbox.querySelector('.lightbox-close');
  var lastTrigger = null;

  var onKeydown = function (e) {
    if (e.key === 'Escape') close();
  };

  var open = function (trigger) {
    var img = trigger.querySelector('img');
    var caption = trigger.closest('figure').querySelector('figcaption');
    lastTrigger = trigger;
    lbImg.src = img.src;
    lbImg.alt = img.alt;
    lbCaption.textContent = caption ? caption.textContent : '';
    lightbox.hidden = false;
    document.documentElement.classList.add('lightbox-open');
    closeBtn.focus();
    document.addEventListener('keydown', onKeydown);
  };

  var close = function () {
    lightbox.hidden = true;
    document.documentElement.classList.remove('lightbox-open');
    lbImg.src = '';
    document.removeEventListener('keydown', onKeydown);
    if (lastTrigger) lastTrigger.focus();
  };

  Array.prototype.slice.call(document.querySelectorAll('.img-zoom')).forEach(function (btn) {
    btn.addEventListener('click', function () { open(btn); });
  });

  closeBtn.addEventListener('click', close);
  lightbox.addEventListener('click', function (e) {
    if (e.target === lightbox) close();
  });
})();
