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
