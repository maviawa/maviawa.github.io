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
