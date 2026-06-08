// Nav scroll behaviour
const nav = document.querySelector('.nav');
if (nav) {
  window.addEventListener('scroll', () => {
    nav.classList.toggle('scrolled', window.scrollY > 40);
  });
}

// Home hero loaded class for slow zoom
const hero = document.querySelector('.home-hero');
if (hero) {
  setTimeout(() => hero.classList.add('loaded'), 100);
}

function toggleLatest() {
  const drawer = document.getElementById('latest-drawer');
  drawer.classList.toggle('open');
}

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    document.getElementById('latest-drawer').classList.remove('open');
  }
});
