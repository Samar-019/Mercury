// -------------------------------------------------------------
// Liquid Mercury Comet Particle Tail & Magnetic Cursor System
// -------------------------------------------------------------
const cursorDot = document.getElementById('cursor-dot');
const cursorRing = document.getElementById('cursor-ring');
const trailCanvas = document.getElementById('cursor-trail-canvas');
const trailCtx = trailCanvas ? trailCanvas.getContext('2d') : null;

let cursorX = window.innerWidth / 2;
let cursorY = window.innerHeight / 2;
let ringX = cursorX;
let ringY = cursorY;

function resizeTrail() {
  if (trailCanvas) {
    trailCanvas.width = window.innerWidth;
    trailCanvas.height = window.innerHeight;
  }
}
window.addEventListener('resize', resizeTrail);
resizeTrail();

// Trailing points history for smooth liquid ribbon
const trailPoints = [];
const MAX_TRAIL = 18;

window.addEventListener('mousemove', (e) => {
  cursorX = e.clientX;
  cursorY = e.clientY;

  // Add trail point with timestamp
  trailPoints.push({ x: cursorX, y: cursorY, age: 0 });
  if (trailPoints.length > MAX_TRAIL) trailPoints.shift();

  // Instant update for center core dot
  if (cursorDot) {
    cursorDot.style.left = `${cursorX}px`;
    cursorDot.style.top = `${cursorY}px`;
  }
});

// Smooth Lerp animation for trailing ring & ribbon draw
function renderCursor() {
  ringX += (cursorX - ringX) * 0.18;
  ringY += (cursorY - ringY) * 0.18;

  if (cursorRing) {
    cursorRing.style.left = `${ringX}px`;
    cursorRing.style.top = `${ringY}px`;
  }

  // Draw smooth liquid rainbow chromatic ribbon tail
  if (trailCtx && trailCanvas) {
    trailCtx.clearRect(0, 0, trailCanvas.width, trailCanvas.height);

    const now = Date.now() * 0.15;
    if (trailPoints.length > 2) {
      for (let i = 0; i < trailPoints.length - 1; i++) {
        trailPoints[i].age += 1;
        const pt = trailPoints[i];
        const progress = i / trailPoints.length;
        const radius = progress * 6.5;
        const alpha = progress * 0.75;

        // Dynamic 360-degree rainbow hue calculation
        const hue = (now + i * 14) % 360;

        trailCtx.beginPath();
        trailCtx.arc(pt.x, pt.y, Math.max(0.8, radius), 0, Math.PI * 2);
        trailCtx.fillStyle = `hsla(${hue}, 95%, 65%, ${alpha})`;
        trailCtx.shadowBlur = 12;
        trailCtx.shadowColor = `hsl(${hue}, 100%, 60%)`;
        trailCtx.fill();
      }
    }
  }

  requestAnimationFrame(renderCursor);
}
renderCursor();

// Mouse down / up click effects
window.addEventListener('mousedown', () => document.body.classList.add('cursor-clicking'));
window.addEventListener('mouseup', () => document.body.classList.remove('cursor-clicking'));

// Interactive hover bindings on clickable & glass items
function bindCursorHovers() {
  const hoverables = document.querySelectorAll('a, button, .bento-card, .spatial-badge, .showcase-window');
  hoverables.forEach(el => {
    el.addEventListener('mouseenter', () => {
      document.body.classList.add('cursor-hover');
    });
    el.addEventListener('mouseleave', () => {
      document.body.classList.remove('cursor-hover');
    });
  });
}
bindCursorHovers();

// -------------------------------------------------------------
// Interactive Spotlight Tracking & 3D Card Tilt on Mouse Move
// -------------------------------------------------------------
const interactiveCards = document.querySelectorAll('.bento-card, .showcase-window, .sound-strip, .download-banner');
interactiveCards.forEach(card => {
  card.addEventListener('mousemove', (e) => {
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    // Pass coordinates to CSS variable for radial dynamic spotlight
    card.style.setProperty('--mouse-x', `${x}px`);
    card.style.setProperty('--mouse-y', `${y}px`);

    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    
    const rotateX = ((y - centerY) / centerY) * -6; // tilt up/down
    const rotateY = ((x - centerX) / centerX) * 6;  // tilt left/right
    
    card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
  });

  card.addEventListener('mouseleave', () => {
    card.style.transform = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateY(0px)';
  });
});

// Ambient Canvas 60fps Particle & Wave Field
const canvas = document.getElementById('ambient-canvas');
const ctx = canvas.getContext('2d');

let width, height;
let particles = [];
let mouse = { x: null, y: null, radius: 180 };

function resize() {
  width = canvas.width = window.innerWidth;
  height = canvas.height = window.innerHeight;
}

window.addEventListener('resize', resize);
resize();

class Particle {
  constructor() {
    this.x = Math.random() * width;
    this.y = Math.random() * height;
    this.size = Math.random() * 2 + 0.6;
    this.baseX = this.x;
    this.baseY = this.y;
    this.speedX = (Math.random() - 0.5) * 0.4;
    this.speedY = (Math.random() - 0.5) * 0.4;
    this.alpha = Math.random() * 0.5 + 0.2;
  }

  update() {
    this.x += this.speedX;
    this.y += this.speedY;

    if (this.x < 0) this.x = width;
    if (this.x > width) this.x = 0;
    if (this.y < 0) this.y = height;
    if (this.y > height) this.y = 0;

    // Mouse repulsion
    if (mouse.x !== null) {
      let dx = mouse.x - this.x;
      let dy = mouse.y - this.y;
      let dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < mouse.radius) {
        let force = (mouse.radius - dist) / mouse.radius;
        this.x -= (dx / dist) * force * 3;
        this.y -= (dy / dist) * force * 3;
      }
    }
  }

  draw() {
    ctx.fillStyle = `rgba(56, 189, 248, ${this.alpha * 0.4})`;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
    ctx.fill();
  }
}

for (let i = 0; i < 48; i++) {
  particles.push(new Particle());
}

window.addEventListener('mousemove', (e) => {
  mouse.x = e.clientX;
  mouse.y = e.clientY;

  // Parallax on glow orbs
  const orb1 = document.querySelector('.orb-1');
  const orb2 = document.querySelector('.orb-2');
  const moveX = (e.clientX - width / 2) * 0.03;
  const moveY = (e.clientY - height / 2) * 0.03;
  if (orb1) orb1.style.transform = `translate(${moveX}px, ${moveY}px)`;
  if (orb2) orb2.style.transform = `translate(${-moveX * 1.2}px, ${-moveY * 1.2}px)`;
});

window.addEventListener('mouseleave', () => {
  mouse.x = null;
  mouse.y = null;
});

function animateCanvas() {
  ctx.clearRect(0, 0, width, height);

  for (let i = 0; i < particles.length; i++) {
    particles[i].update();
    particles[i].draw();

    // Subtle connection lines between close particles
    for (let j = i + 1; j < particles.length; j++) {
      let dx = particles[i].x - particles[j].x;
      let dy = particles[i].y - particles[j].y;
      let dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 110) {
        ctx.strokeStyle = `rgba(56, 189, 248, ${0.08 * (1 - dist / 110)})`;
        ctx.lineWidth = 0.6;
        ctx.beginPath();
        ctx.moveTo(particles[i].x, particles[i].y);
        ctx.lineTo(particles[j].x, particles[j].y);
        ctx.stroke();
      }
    }
  }
  requestAnimationFrame(animateCanvas);
}

animateCanvas();

// Equalizer Sound Strip Interaction
const eqContainer = document.getElementById('equalizer-bars');
const playBtn = document.getElementById('toggle-sound-btn');
const playIcon = document.getElementById('play-icon');

let isPlaying = true;
const NUM_BARS = 36;
const bars = [];

if (eqContainer) {
  for (let i = 0; i < NUM_BARS; i++) {
    const bar = document.createElement('div');
    bar.className = 'eq-bar';
    bar.style.height = '8px';
    eqContainer.appendChild(bar);
    bars.push(bar);
  }
}

let eqTimer;
function updateEqualizer() {
  if (!isPlaying) {
    bars.forEach(b => b.style.height = '4px');
    return;
  }

  bars.forEach((bar, idx) => {
    const time = Date.now() * 0.005;
    const wave = Math.sin(time + idx * 0.25) * Math.cos(time * 0.5 - idx * 0.1);
    const height = Math.max(4, Math.abs(wave) * 34);
    bar.style.height = `${height}px`;
    
    // Dynamic color gradient based on height
    const ratio = height / 34;
    if (ratio > 0.7) {
      bar.style.background = '#818cf8';
    } else {
      bar.style.background = '#38bdf8';
    }
  });

  requestAnimationFrame(updateEqualizer);
}

updateEqualizer();

if (playBtn) {
  playBtn.addEventListener('click', () => {
    isPlaying = !isPlaying;
    if (isPlaying) {
      playBtn.innerHTML = '<i data-lucide="pause"></i>';
      updateEqualizer();
    } else {
      playBtn.innerHTML = '<i data-lucide="play"></i>';
    }
    lucide.createIcons();
  });
}
