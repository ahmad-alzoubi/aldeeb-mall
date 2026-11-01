/**
 * AURA — The Infinite Creative Matrix
 * High-Performance Physics & Generative Web Audio Engine
 */

// =============================================================================
// 1. STATE & CONFIGURATION
// =============================================================================
const CONFIG = {
  particles: {
    count: 600,
    speed: 1.2,
    gravity: 1.8,
    connectDistance: 110,
    maxSpeed: 4.5,
    damping: 0.985
  },
  sound: {
    enabled: true,
    volume: 0.15
  },
  palette: 'emerald', // emerald | gold | cyan | violet
  lang: 'ar'
};

const PALETTES = {
  emerald: {
    primary: '#10B981',
    rgb: [16, 185, 129],
    secondary: '#06B6D4'
  },
  gold: {
    primary: '#F59E0B',
    rgb: [245, 158, 11],
    secondary: '#EF4444'
  },
  cyan: {
    primary: '#06B6D4',
    rgb: [6, 182, 212],
    secondary: '#3B82F6'
  },
  violet: {
    primary: '#8B5CF6',
    rgb: [139, 92, 246],
    secondary: '#EC4899'
  }
};

// =============================================================================
// 2. AUDIO SYNTHESIZER (WEB AUDIO API)
// =============================================================================
class GenerativeSynth {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.isInitialized = false;
  }

  init() {
    if (this.isInitialized) return;
    try {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioContextClass();
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.setValueAtTime(CONFIG.sound.volume, this.ctx.currentTime);
      this.masterGain.connect(this.ctx.destination);
      this.isInitialized = true;
    } catch (e) {
      console.warn('Web Audio API not supported or blocked:', e);
    }
  }

  playNote(frequency, duration = 0.6, type = 'sine', gainLevel = 1.0) {
    if (!CONFIG.sound.enabled) return;
    this.init();
    if (!this.ctx) return;

    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = type;
    osc.frequency.setValueAtTime(frequency, now);

    // Subtle pitch bend for modern organic feel
    osc.frequency.exponentialRampToValueAtTime(frequency * 1.01, now + duration * 0.2);
    osc.frequency.exponentialRampToValueAtTime(frequency, now + duration);

    // Fast attack, smooth exponential decay
    const peakGain = 0.25 * gainLevel;
    gain.gain.setValueAtTime(0.001, now);
    gain.gain.exponentialRampToValueAtTime(peakGain, now + 0.04);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

    osc.connect(gain);
    gain.connect(this.masterGain);

    osc.start(now);
    osc.stop(now + duration + 0.05);

    this.animateWaveVisualizer();
  }

  playChord(frequencies, duration = 1.2) {
    frequencies.forEach((freq, idx) => {
      setTimeout(() => {
        this.playNote(freq, duration, 'triangle', 0.65);
      }, idx * 60);
    });
  }

  playSupernovaSound() {
    if (!CONFIG.sound.enabled) return;
    this.init();
    if (!this.ctx) return;
    
    // Low rumble boom + shimmering celestial chimes
    this.playNote(75, 1.6, 'sine', 1.8);
    setTimeout(() => this.playChord([261.63, 329.63, 392.00, 523.25, 659.25], 1.5), 100);
  }

  animateWaveVisualizer() {
    const bars = document.querySelectorAll('#wave-bars .bar');
    bars.forEach(bar => {
      const randHeight = Math.floor(Math.random() * 75 + 25);
      bar.style.height = `${randHeight}%`;
      setTimeout(() => {
        bar.style.height = '35%';
      }, 350);
    });
  }
}

const synth = new GenerativeSynth();

// =============================================================================
// 3. HIGH-PERFORMANCE 2D/3D PARTICLE ENGINE
// =============================================================================
class ParticleEngine {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d', { alpha: false });
    this.particles = [];
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.dpr = Math.min(window.devicePixelRatio || 1, 2);

    this.mouse = {
      x: this.width * 0.5,
      y: this.height * 0.4,
      targetX: this.width * 0.5,
      targetY: this.height * 0.4,
      isDown: false,
      isHovering: false,
      radius: 180
    };

    this.shockwaves = [];
    this.vortexActive = false;
    this.vortexAngle = 0;

    // Performance Tracking
    this.lastFrameTime = performance.now();
    this.fps = 60;
    this.frameCount = 0;
    this.lastFpsUpdate = performance.now();

    this.init();
  }

  init() {
    this.resize();
    window.addEventListener('resize', () => this.resize());

    // Mouse & Touch Tracking
    window.addEventListener('mousemove', (e) => {
      this.mouse.targetX = e.clientX;
      this.mouse.targetY = e.clientY;
      this.mouse.isHovering = true;
    });

    window.addEventListener('touchmove', (e) => {
      if (e.touches.length > 0) {
        this.mouse.targetX = e.touches[0].clientX;
        this.mouse.targetY = e.touches[0].clientY;
        this.mouse.isHovering = true;
      }
    }, { passive: true });

    window.addEventListener('mousedown', (e) => {
      this.mouse.isDown = true;
      this.triggerShockwave(e.clientX, e.clientY, 14);
      synth.playNote(220 + Math.random() * 220, 0.4, 'triangle');
    });

    window.addEventListener('mouseup', () => {
      this.mouse.isDown = false;
    });

    this.createParticles(CONFIG.particles.count);
    this.animate();
  }

  resize() {
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = this.width * this.dpr;
    this.canvas.height = this.height * this.dpr;
    this.ctx.scale(this.dpr, this.dpr);
  }

  createParticles(count) {
    this.particles = [];
    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * this.width,
        y: Math.random() * this.height,
        vx: (Math.random() - 0.5) * 1.5 * CONFIG.particles.speed,
        vy: (Math.random() - 0.5) * 1.5 * CONFIG.particles.speed,
        baseRadius: Math.random() * 1.8 + 0.8,
        radius: Math.random() * 1.8 + 0.8,
        alpha: Math.random() * 0.6 + 0.2,
        pulseSpeed: Math.random() * 0.04 + 0.01,
        pulseAngle: Math.random() * Math.PI * 2,
        mass: Math.random() * 0.5 + 0.8
      });
    }
    const counterEl = document.getElementById('particle-counter');
    if (counterEl) counterEl.textContent = count;
  }

  triggerShockwave(x, y, force = 20) {
    this.shockwaves.push({
      x,
      y,
      radius: 5,
      maxRadius: Math.max(this.width, this.height) * 0.45,
      force,
      alpha: 0.9
    });
  }

  triggerSupernova() {
    const cx = this.width * 0.5;
    const cy = this.height * 0.45;
    this.triggerShockwave(cx, cy, 32);

    this.particles.forEach(p => {
      const dx = p.x - cx;
      const dy = p.y - cy;
      const dist = Math.hypot(dx, dy) || 1;
      const angle = Math.atan2(dy, dx);
      const blastPower = (1 - Math.min(dist / (this.width * 0.6), 1)) * 25 + 5;
      p.vx += Math.cos(angle) * blastPower;
      p.vy += Math.sin(angle) * blastPower;
    });

    synth.playSupernovaSound();
    logToTerminal('SUPERNOVA_TRIGGER: Gravitational shockwave emitted with blast magnitude 32.0G');
  }

  toggleVortex() {
    this.vortexActive = !this.vortexActive;
    const statusEl = document.getElementById('physics-status');
    if (statusEl) {
      statusEl.textContent = this.vortexActive 
        ? (CONFIG.lang === 'ar' ? 'دوامة كوانتية' : 'Quantum Vortex') 
        : (CONFIG.lang === 'ar' ? 'نشطة' : 'Active');
    }
    logToTerminal(`VORTEX_TOGGLE: Mode set to ${this.vortexActive ? 'ENABLED' : 'DISABLED'}`);
  }

  updatePhysics() {
    // Smooth mouse inertia
    this.mouse.x += (this.mouse.targetX - this.mouse.x) * 0.12;
    this.mouse.y += (this.mouse.targetY - this.mouse.y) * 0.12;

    const gravityStrength = CONFIG.particles.gravity * 0.0035;
    const speedMult = CONFIG.particles.speed;
    const maxSpd = CONFIG.particles.maxSpeed;
    const damping = CONFIG.particles.damping;
    const vortexCenter = { x: this.width * 0.5, y: this.height * 0.45 };

    // Update Shockwaves
    for (let i = this.shockwaves.length - 1; i >= 0; i--) {
      const sw = this.shockwaves[i];
      sw.radius += 14;
      sw.alpha *= 0.94;
      if (sw.alpha < 0.02 || sw.radius > sw.maxRadius) {
        this.shockwaves.splice(i, 1);
      }
    }

    // Update Particles
    for (let i = 0; i < this.particles.length; i++) {
      const p = this.particles[i];

      // Natural pulse
      p.pulseAngle += p.pulseSpeed;
      p.radius = p.baseRadius + Math.sin(p.pulseAngle) * 0.5;

      // Mouse gravity attraction / repulsion
      if (this.mouse.isHovering) {
        const dx = this.mouse.x - p.x;
        const dy = this.mouse.y - p.y;
        const dist = Math.hypot(dx, dy);

        if (dist < this.mouse.radius && dist > 1) {
          const force = (1 - dist / this.mouse.radius) * gravityStrength * (this.mouse.isDown ? -2.5 : 1.2);
          p.vx += (dx / dist) * force * 15;
          p.vy += (dy / dist) * force * 15;
        }
      }

      // Quantum Vortex Mode
      if (this.vortexActive) {
        const vdx = vortexCenter.x - p.x;
        const vdy = vortexCenter.y - p.y;
        const vdist = Math.hypot(vdx, vdy) || 1;
        const angle = Math.atan2(vdy, vdx);
        
        // Tangential angular acceleration + mild central pull
        p.vx += Math.cos(angle + Math.PI / 2) * (250 / (vdist + 50));
        p.vy += Math.sin(angle + Math.PI / 2) * (250 / (vdist + 50));
        p.vx += (vdx / vdist) * 0.4;
        p.vy += (vdy / vdist) * 0.4;
      }

      // Shockwave push
      for (const sw of this.shockwaves) {
        const sdx = p.x - sw.x;
        const sdy = p.y - sw.y;
        const sdist = Math.hypot(sdx, sdy);
        const waveDelta = Math.abs(sdist - sw.radius);

        if (waveDelta < 35 && sdist > 1) {
          const pushForce = (1 - waveDelta / 35) * sw.force * sw.alpha;
          p.vx += (sdx / sdist) * pushForce;
          p.vy += (sdy / sdist) * pushForce;
        }
      }

      // Apply velocity and drag
      p.vx *= damping;
      p.vy *= damping;

      // Speed limits
      const curSpeed = Math.hypot(p.vx, p.vy);
      if (curSpeed > maxSpd) {
        p.vx = (p.vx / curSpeed) * maxSpd;
        p.vy = (p.vy / curSpeed) * maxSpd;
      }

      p.x += p.vx * speedMult;
      p.y += p.vy * speedMult;

      // Screen wrap-around with gentle margins
      if (p.x < -10) p.x = this.width + 10;
      else if (p.x > this.width + 10) p.x = -10;
      if (p.y < -10) p.y = this.height + 10;
      else if (p.y > this.height + 10) p.y = -10;
    }
  }

  draw() {
    const curPal = PALETTES[CONFIG.palette];
    const [r, g, b] = curPal.rgb;

    // Deep space background with subtle motion trail
    this.ctx.fillStyle = 'rgba(6, 8, 13, 0.28)';
    this.ctx.fillRect(0, 0, this.width, this.height);

    // Draw Shockwaves
    for (const sw of this.shockwaves) {
      this.ctx.save();
      this.ctx.beginPath();
      this.ctx.arc(sw.x, sw.y, sw.radius, 0, Math.PI * 2);
      this.ctx.strokeStyle = `rgba(${r}, ${g}, ${b}, ${sw.alpha * 0.7})`;
      this.ctx.lineWidth = 2.5;
      this.ctx.stroke();
      this.ctx.restore();
    }

    // Draw Synaptic Neural Connections
    const connectDist = CONFIG.particles.connectDistance;
    const len = this.particles.length;

    // Optimized connection drawing: check subset or nearby
    for (let i = 0; i < len; i += 2) {
      const p1 = this.particles[i];
      for (let j = i + 1; j < len; j += 3) {
        const p2 = this.particles[j];
        const dx = p1.x - p2.x;
        const dy = p1.y - p2.y;
        const dist = Math.hypot(dx, dy);

        if (dist < connectDist) {
          const alpha = (1 - dist / connectDist) * 0.22;
          this.ctx.beginPath();
          this.ctx.moveTo(p1.x, p1.y);
          this.ctx.lineTo(p2.x, p2.y);
          this.ctx.strokeStyle = `rgba(${r}, ${g}, ${b}, ${alpha})`;
          this.ctx.lineWidth = 0.8;
          this.ctx.stroke();
        }
      }
    }

    // Draw Particles
    for (let i = 0; i < len; i++) {
      const p = this.particles[i];
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      this.ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${p.alpha})`;
      this.ctx.fill();

      // Gleam halo on energetic particles
      if (Math.hypot(p.vx, p.vy) > 1.8) {
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, p.radius * 2.2, 0, Math.PI * 2);
        this.ctx.fillStyle = `rgba(${r}, ${g}, ${b}, 0.15)`;
        this.ctx.fill();
      }
    }
  }

  animate() {
    this.updatePhysics();
    this.draw();

    // FPS Counter Calculation
    this.frameCount++;
    const now = performance.now();
    if (now - this.lastFpsUpdate >= 500) {
      this.fps = Math.round((this.frameCount * 1000) / (now - this.lastFpsUpdate));
      const fpsEl = document.getElementById('fps-counter');
      if (fpsEl) fpsEl.textContent = this.fps;

      // Update Live Latency Simulation
      const latencyEl = document.getElementById('metric-latency');
      if (latencyEl) {
        const latency = (1000 / (this.fps || 60) * 0.03 + 0.35).toFixed(2);
        latencyEl.textContent = `${latency} ms`;
      }

      this.frameCount = 0;
      this.lastFpsUpdate = now;
    }

    requestAnimationFrame(() => this.animate());
  }
}

// =============================================================================
// 4. 3D TILT EFFECT & MICRO-INTERACTIONS
// =============================================================================
function initTiltCards() {
  const cards = document.querySelectorAll('[data-tilt]');
  cards.forEach(card => {
    card.addEventListener('mousemove', (e) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      const rotateX = ((y - centerY) / centerY) * -12;
      const rotateY = ((x - centerX) / centerX) * 12;

      card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
      card.style.setProperty('--mouse-x', `${(x / rect.width) * 100}%`);
      card.style.setProperty('--mouse-y', `${(y / rect.height) * 100}%`);
    });

    card.addEventListener('mouseenter', () => {
      synth.playNote(440 + Math.random() * 80, 0.25, 'sine', 0.4);
    });

    card.addEventListener('mouseleave', () => {
      card.style.transform = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateY(0px)';
    });
  });
}

// =============================================================================
// 5. LOCALIZATION DICTIONARY (AR / EN)
// =============================================================================
const I18N = {
  ar: {
    badge: 'CREATIVE MATRIX v2.5',
    particles: 'الجسيمات:',
    physics: 'الفيزياء:',
    active: 'نشطة',
    audio_btn: 'الصوت: نشط',
    audio_btn_off: 'الصوت: صامت',
    hero_eyebrow: 'هندسة تفاعلية بصرية فائقة الدقة والذكاء',
    hero_title_1: 'إبداع رقمي بلا قيود.',
    hero_title_2: 'حيث تتلاقى الفيزياء والخوارزميات الفاخرة',
    hero_subtitle: 'منظومة ويب متطورة فائقة السرعة، تجمع بين محاكاة الجسيمات الكوانتية ثنائية وثلاثية الأبعاد، التوليد الصوتي التوافقي التفاعلي (Web Audio Synth)، والتصميم الهندسي المصقول بمعايير أرقى الاستوديوهات العالمية.',
    trigger_supernova: 'إطلاق انفجار السوبرنوفا',
    trigger_vortex: 'تفعيل الدوامة الكوانتية',
    trigger_shockwave: 'نبضة مغناطيسية',
    mouse_hint: 'حرك المؤشر أو انقر في أي مكان للتفاعل مع حقل الجاذبية والصوت الترددي',
    lab_title: 'غرفة التحكم الفيزيائي بالمصفوفة الحية',
    color_theme: 'طيف الطاقة:',
    ctrl_particles: 'كثافة الجسيمات',
    ctrl_gravity: 'قوة الجاذبية التفاعلية',
    ctrl_speed: 'سرعة التدفق الحركي',
    ctrl_connect: 'مدى الترابط العصبي (Web Distance)',
    matrix_title: 'ركائز الإتقان والهندسة الإبداعية',
    matrix_sub: 'كل بطاقة تفاعلية ثلاثية الأبعاد تستجيب لحركة الماوس وتحتوي على محاكاة معمارية حية',
    card1_title: 'محركات الحوسبة فائقة السرعة',
    card1_desc: 'بناء أنظمة برمجية مصقولة بمعدل تحديث 120 إطاراً في الثانية، مع استهلاك مثالي لذاكرة الوصول العشوائي ومعالجة الحسابات المتجهة في الوقت الفعلي.',
    render_latency: 'زمن المعالجة (Latency):',
    card2_title: 'وكلاء الذكاء الاصطناعي متعددو الوسائط',
    card2_desc: 'تصميم وتنفيذ أنظمة ذكاء اصطناعي تفاعلية متعددة الوكلاء (Autonomous Multi-Agent Networks) مع ذاكرة سياقية وتفكير منطقي عميق واستخراج مهيكل.',
    card3_title: 'أنظمة التصميم الفاخرة والزجاج السائل',
    card3_desc: 'تجارب بصرية سينمائية تستلهم معايير Apple وLinear وStripe، متوافقة كلياً مع الاتجاهين العربي (RTL) والإنجليزي (LTR) وظلال متعددة الطبقات.',
    btn_sample1: 'نبضة لمسية',
    btn_sample2: 'طيف متدرج',
    card4_title: 'التخليق الصوتي التفاعلي بالمتصفح',
    card4_desc: 'توليد النغمات والموجات الصوتية الحسابية عبر Web Audio API مع ترددات البنتاتونيك الموسيقية المتناسقة وفلاتر صدى متقدمة بدون ملفات صوت خارجية.',
    synth_title: 'لوحة الترددات البنتاتونيكية التفاعلية',
    synth_sub: 'مرر الماوس أو المس المقاطع التالية لتوليد نغمات موسيقية كريستالية تتناغم مع حركة الجسيمات',
    back_top: 'العودة للأعلى'
  },
  en: {
    badge: 'CREATIVE MATRIX v2.5',
    particles: 'Particles:',
    physics: 'Physics:',
    active: 'Active',
    audio_btn: 'Sound: On',
    audio_btn_off: 'Sound: Muted',
    hero_eyebrow: 'Hyper-Precise Intelligent Visual Engineering',
    hero_title_1: 'Unbounded Digital Creativity.',
    hero_title_2: 'Where Quantum Physics Meets Haute Algorithmics',
    hero_subtitle: 'A high-velocity web matrix blending 2D/3D quantum particle simulations, real-time Web Audio harmonic synthesis, and state-of-the-art luxury design calibrated to world-class studio standards.',
    trigger_supernova: 'Ignite Supernova Burst',
    trigger_vortex: 'Engage Quantum Vortex',
    trigger_shockwave: 'Magnetic Shockwave',
    mouse_hint: 'Move cursor or click anywhere to warp gravitational spacetime and trigger acoustic harmonics',
    lab_title: 'Real-Time Spacetime Physics Console',
    color_theme: 'Energy Spectrum:',
    ctrl_particles: 'Particle Density',
    ctrl_gravity: 'Gravitational Pull',
    ctrl_speed: 'Flow Velocity',
    ctrl_connect: 'Neural Web Distance',
    matrix_title: 'Pillars of Creative & Architectural Mastery',
    matrix_sub: 'Interactive 3D tilt cards reacting to mouse trajectory with live architectural telemetry',
    card1_title: 'Ultra-High Velocity Computation',
    card1_desc: 'Architecting butter-smooth 120 FPS systems with minimal memory footprints, sub-millisecond event loops, and vectorized math pipelines.',
    render_latency: 'Frame Latency:',
    card2_title: 'Autonomous Multi-Modal AI Agents',
    card2_desc: 'Designing distributed multi-agent neural swarms equipped with structured JSON output, long-horizon planning, and tool-augmented workflows.',
    card3_title: 'Haute UI & Liquid Glassmorphism',
    card3_desc: 'Cinematic visual languages inspired by Apple, Linear, and Stripe, boasting bi-directional RTL/LTR perfection and multi-layered elevation.',
    btn_sample1: 'Haptic Tap',
    btn_sample2: 'Prism Shift',
    card4_title: 'In-Browser Algorithmic Synthesizer',
    card4_desc: 'Real-time Web Audio procedural tone generation utilizing harmonic pentatonic frequencies and spatial reverb without external assets.',
    synth_title: 'Interactive Pentatonic Harmonic Matrix',
    synth_sub: 'Hover or tap chime cells to trigger resonant crystalline frequencies in concert with particle kinetics',
    back_top: 'Back to Top'
  }
};

function setLanguage(lang) {
  CONFIG.lang = lang;
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';

  const strings = I18N[lang];
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (strings[key]) {
      el.textContent = strings[key];
    }
  });

  const langText = document.getElementById('lang-text');
  if (langText) langText.textContent = lang === 'ar' ? 'English' : 'العربية';

  logToTerminal(`LOCALE_CHANGE: Language switched to [${lang.toUpperCase()}]`);
}

// =============================================================================
// 6. TERMINAL LOGGING UTILITY
// =============================================================================
function logToTerminal(message) {
  const terminal = document.getElementById('console-logs');
  if (!terminal) return;
  const line = document.createElement('div');
  line.className = 'log-line';
  const time = new Date().toLocaleTimeString();
  line.textContent = `[${time}] > ${message}`;
  terminal.appendChild(line);
  terminal.scrollTop = terminal.scrollHeight;
}

// =============================================================================
// 7. INITIALIZATION & EVENT BINDINGS
// =============================================================================
document.addEventListener('DOMContentLoaded', () => {
  const canvas = document.getElementById('universe-canvas');
  const engine = new ParticleEngine(canvas);

  // Initialize Tilt Cards
  initTiltCards();

  // Scroll Progress Fallback (modern-web-guidance compliance)
  if (!CSS.supports('animation-timeline', 'scroll()')) {
    const progress = document.getElementById('scroll-progress');
    window.addEventListener('scroll', () => {
      const scrollable = document.documentElement.scrollHeight - window.innerHeight;
      const scrolled = window.scrollY;
      const progressPercentage = scrollable > 0 ? scrolled / scrollable : 0;
      progress.style.transform = `scaleX(${progressPercentage})`;
    });
  }

  // Supernova CTA
  document.getElementById('supernova-btn')?.addEventListener('click', () => {
    engine.triggerSupernova();
  });

  // Vortex CTA
  document.getElementById('vortex-btn')?.addEventListener('click', () => {
    engine.toggleVortex();
  });

  // Magnetic Shockwave CTA
  document.getElementById('reset-physics-btn')?.addEventListener('click', () => {
    engine.triggerShockwave(window.innerWidth * 0.5, window.innerHeight * 0.45, 24);
    synth.playChord([392.00, 523.25, 659.25]);
    logToTerminal('MAGNETIC_PULSE: Spacetime distortion pulse triggered');
  });

  // Sound Toggle
  const audioBtn = document.getElementById('audio-toggle');
  audioBtn?.addEventListener('click', () => {
    CONFIG.sound.enabled = !CONFIG.sound.enabled;
    const soundOnIcon = audioBtn.querySelector('.sound-on');
    const soundOffIcon = audioBtn.querySelector('.sound-off');
    const btnText = audioBtn.querySelector('.btn-text');

    if (CONFIG.sound.enabled) {
      soundOnIcon?.classList.remove('hidden');
      soundOffIcon?.classList.add('hidden');
      if (btnText) btnText.textContent = I18N[CONFIG.lang].audio_btn;
      synth.playNote(523.25, 0.4, 'sine');
      logToTerminal('AUDIO_STATUS: Sound generator active');
    } else {
      soundOnIcon?.classList.add('hidden');
      soundOffIcon?.classList.remove('hidden');
      if (btnText) btnText.textContent = I18N[CONFIG.lang].audio_btn_off;
      logToTerminal('AUDIO_STATUS: Sound muted');
    }
  });

  // Language Toggle
  document.getElementById('lang-toggle')?.addEventListener('click', () => {
    const nextLang = CONFIG.lang === 'ar' ? 'en' : 'ar';
    setLanguage(nextLang);
  });

  // Color Theme Palette Picker
  document.querySelectorAll('.palette-dots .dot-btn').forEach(dot => {
    dot.addEventListener('click', () => {
      document.querySelectorAll('.palette-dots .dot-btn').forEach(d => d.classList.remove('active'));
      dot.classList.add('active');

      const palette = dot.getAttribute('data-palette');
      CONFIG.palette = palette;

      // Update body classes
      document.body.classList.remove('palette-gold', 'palette-cyan', 'palette-violet');
      if (palette !== 'emerald') {
        document.body.classList.add(`palette-${palette}`);
      }

      synth.playNote(587.33, 0.35, 'triangle');
      logToTerminal(`THEME_SHIFT: Switched energy spectrum to [${palette.toUpperCase()}]`);
    });
  });

  // Physics Lab Sliders
  const sliderParticles = document.getElementById('slider-particles');
  const valParticles = document.getElementById('val-particles');
  sliderParticles?.addEventListener('input', (e) => {
    const val = parseInt(e.target.value, 10);
    CONFIG.particles.count = val;
    if (valParticles) valParticles.textContent = val;
    engine.createParticles(val);
  });

  const sliderGravity = document.getElementById('slider-gravity');
  const valGravity = document.getElementById('val-gravity');
  sliderGravity?.addEventListener('input', (e) => {
    const val = parseFloat(e.target.value);
    CONFIG.particles.gravity = val;
    if (valGravity) valGravity.textContent = `${val.toFixed(1)}x`;
  });

  const sliderSpeed = document.getElementById('slider-speed');
  const valSpeed = document.getElementById('val-speed');
  sliderSpeed?.addEventListener('input', (e) => {
    const val = parseFloat(e.target.value);
    CONFIG.particles.speed = val;
    if (valSpeed) valSpeed.textContent = `${val.toFixed(1)}x`;
  });

  const sliderConnect = document.getElementById('slider-connect');
  const valConnect = document.getElementById('val-connect');
  sliderConnect?.addEventListener('input', (e) => {
    const val = parseInt(e.target.value, 10);
    CONFIG.particles.connectDistance = val;
    if (valConnect) valConnect.textContent = `${val}px`;
  });

  // Pentatonic Chime Pads
  document.querySelectorAll('.chime-pad').forEach(pad => {
    const freq = parseFloat(pad.getAttribute('data-freq'));
    const playChime = () => {
      pad.classList.add('active');
      synth.playNote(freq, 0.7, 'triangle', 0.85);
      engine.triggerShockwave(
        pad.getBoundingClientRect().left + pad.offsetWidth / 2,
        pad.getBoundingClientRect().top + pad.offsetHeight / 2,
        8
      );
      setTimeout(() => pad.classList.remove('active'), 250);
    };

    pad.addEventListener('mouseenter', playChime);
    pad.addEventListener('click', playChime);
  });

  // Micro Magnetic sample buttons
  document.querySelectorAll('.micro-magnetic-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      synth.playNote(659.25, 0.25, 'sine');
      btn.style.transform = 'scale(0.92)';
      setTimeout(() => btn.style.transform = '', 150);
    });
  });

  // Scroll to Top
  document.getElementById('scroll-top-btn')?.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  logToTerminal('DOM_READY: All visual matrices, physics bindings, and luxury listeners engaged.');
});
