// Sound demos for slides "Loudness is amplitude", "Pitch is frequency" and
// "Timbre is the mix of overtones" (session 19). Each figure wrapped in
// <div class="tone-demo" data-mode="amplitude|pitch|timbre"> gets a Play
// button. Pressing it plays a synthetic voice-like tone, made in the browser
// with the Web Audio API, and draws the live wave over the figure; the figure
// comes back when the sound ends or the slide changes. While it plays, the
// button pauses it; pressed again, it resumes.
//
// The tone: a pitch and its overtones at 2, 3, 4 ... times it, each weaker
// than the last (1/h), the way the vocal folds sound, shaped by the mouth
// into the vowel "ah". Amplitude steps the loudness at 145 Hz; pitch steps
// the pitch at one loudness; timbre keeps 145 Hz and one loudness and
// changes the overtones.
(function () {
  const INK = "#222222", ACC = "#B31B1B", BLUE = "#3A6C9C", GREY = "#666666", RULE = "#BBBBBB";
  const F0 = 145;                 // Powell's "afternoon"
  const STEP = 1.4;               // seconds per step
  const VOLUME = 0.35;            // speaker level, after the analyser

  // Overtone amplitudes 1..n for a pitch f0: a 1/h source shaped by formants
  // (resonances of the throat and mouth at F1, F2, F3 Hz) for the vowels.
  function buzz(n) { return Array.from({ length: n }, (_, i) => 1 / (i + 1)); }
  function vowel(f0, formants) {
    const n = Math.floor(4000 / f0);
    return Array.from({ length: n }, function (_, i) {
      const f = (i + 1) * f0;
      const gain = formants.reduce((s, F) => s + 1 / (1 + Math.pow((f - F) / 90, 2)), 0);
      return (0.05 + gain) / (i + 1);
    });
  }
  const TIMBRES = [
    { name: "pure tone: the pitch alone", amps: [1] },
    { name: "soft, like a flute: weak overtones", amps: [1, 0.25, 0.08, 0.03] },
    { name: "hollow, like a clarinet: odd overtones only", amps: buzz(25).map((a, i) => (i % 2 === 0 ? a : 0)) },
    { name: "buzzy: every overtone, like the vocal folds", amps: buzz(25) },
    { name: "vowel \"ah\": the mouth boosts 730 and 1,090 Hz", amps: vowel(F0, [730, 1090, 2440]) },
    { name: "vowel \"ee\": the mouth boosts 270 and 2,290 Hz", amps: vowel(F0, [270, 2290, 3010]) }
  ];

  const AH = [730, 1090, 2440];
  // Each mode: a list of steps {f0, gain, amps, label}.
  const MODES = {
    amplitude: [0.06, 0.25, 0.9, 0.25, 0.06].map(g => ({ f0: F0, gain: g, amps: vowel(F0, AH) })),
    pitch: [100, 145, 220, 330, 440].map(f => ({ f0: f, gain: 0.6, amps: vowel(f, AH) })),
    timbre: TIMBRES.map(t => ({ f0: F0, gain: 0.6, amps: t.amps, label: t.name }))
  };

  let ctx = null, playing = null;
  function audio() {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }
  // Pausing suspends the audio clock, so the steps scheduled on it wait too.
  function pause() {
    if (!playing) return;
    if (ctx.state === "running") { ctx.suspend(); playing.demo.button.textContent = "▶ Resume"; }
    else { ctx.resume(); playing.demo.button.textContent = "❚❚ Pause"; }
  }
  function wave(ac, amps) {
    const re = new Float32Array(amps.length + 1), im = new Float32Array(amps.length + 1);
    amps.forEach((a, i) => { im[i + 1] = a; });
    return ac.createPeriodicWave(re, im, { disableNormalization: false });
  }

  function stop() {
    if (!playing) return;
    const p = playing; playing = null;
    try { p.osc.stop(); } catch (e) {}
    p.osc.disconnect(); p.env.disconnect(); p.an.disconnect(); p.out.disconnect();
    cancelAnimationFrame(p.raf);
    p.demo.canvas.style.display = "none";
    p.demo.button.textContent = "▶ Play";
    if (ctx.state === "suspended") ctx.resume();
  }

  function play(demo) {
    if (playing && playing.demo === demo) { pause(); return; }
    stop();
    const ac = audio(), steps = MODES[demo.mode];
    const osc = ac.createOscillator(), env = ac.createGain(), an = ac.createAnalyser(), out = ac.createGain();
    an.fftSize = 8192;
    out.gain.value = VOLUME;
    osc.connect(env); env.connect(an); an.connect(out); out.connect(ac.destination);
    const t0 = ac.currentTime + 0.05;
    env.gain.setValueAtTime(0, ac.currentTime);
    // A PeriodicWave is normalised to peak 1, so each step's gain sets its
    // peak: the readout on the slide is that peak on the 16-bit scale.
    steps.forEach(function (s, k) {
      const t = t0 + k * STEP;
      env.gain.linearRampToValueAtTime(s.gain, t + 0.08);
      env.gain.setValueAtTime(s.gain, t + STEP - 0.08);
      osc.frequency.setValueAtTime(s.f0, t);
      if (k === 0) osc.setPeriodicWave(wave(ac, s.amps));
    });
    env.gain.linearRampToValueAtTime(0, t0 + steps.length * STEP);
    osc.start(ac.currentTime);
    osc.stop(t0 + steps.length * STEP + 0.05);
    osc.onended = function () { if (playing && playing.osc === osc) stop(); };

    const c = demo.canvas, img = demo.img;
    c.style.left = img.offsetLeft + "px"; c.style.top = img.offsetTop + "px";
    c.style.width = img.offsetWidth + "px"; c.style.height = img.offsetHeight + "px";
    c.width = img.offsetWidth * 2; c.height = img.offsetHeight * 2;
    c.style.display = "block";
    demo.button.textContent = "❚❚ Pause";
    const buf = new Float32Array(an.fftSize);
    playing = { demo: demo, osc: osc, env: env, an: an, out: out, raf: 0 };
    let shown = 0;
    function frame() {
      if (!playing || playing.osc !== osc) return;
      const k = Math.min(steps.length - 1, Math.max(0, Math.floor((ac.currentTime - t0) / STEP)));
      // Pitch and timbre change the overtones at each step.
      if (k !== shown) { if (steps[k].amps !== steps[shown].amps) osc.setPeriodicWave(wave(ac, steps[k].amps)); shown = k; }
      if (ac.state === "running") {
        an.getFloatTimeDomainData(buf);
        draw(c, demo.mode, buf, ac.sampleRate, steps[k]);
      }
      playing.raf = requestAnimationFrame(frame);
    }
    frame();
  }

  function fmt(x) { return Math.round(x).toLocaleString("en-US"); }

  function draw(c, mode, buf, sr, step) {
    const g = c.getContext("2d"), W = c.width, H = c.height, u = H / 100;
    const big = "bold 32px sans-serif", small = "28px sans-serif";
    g.fillStyle = "#ffffff"; g.fillRect(0, 0, W, H);
    g.font = big; g.fillStyle = INK; g.textBaseline = "top";
    let title;
    let peak = 0;
    for (let i = buf.length - 2400; i < buf.length; i++) peak = Math.max(peak, Math.abs(buf[i]));
    if (mode === "amplitude") title = "peak amplitude now: " + fmt(peak * 32767) + " of 32,767, at the same pitch, " + F0 + " Hz";
    if (mode === "pitch") title = "pitch now: " + step.f0 + " Hz, one cycle " + (1000 / step.f0).toFixed(1) + " ms, at the same loudness";
    if (mode === "timbre") title = step.label;
    g.fillText(title, 2 * u, 2 * u);

    const right = mode === "timbre" ? W * 0.56 : W - 2 * u;
    const x0 = 120, y0 = 54, y1 = H - 40, ym = (y0 + y1) / 2, half = (y1 - y0) / 2;
    const ms = mode === "pitch" ? 30 : 25;     // window shown, in milliseconds
    const n = Math.round(sr * ms / 1000);
    // Start the window at an upward zero crossing so the wave stands still.
    let s0 = buf.length - n - 1;
    for (let i = buf.length - n - 1; i > buf.length - n - 1 - sr / 60 && i > 1; i--) {
      if (buf[i - 1] < 0 && buf[i] >= 0) { s0 = i; break; }
    }
    // Axes: 0, and the loudest the file can hold.
    g.lineWidth = u * 0.3; g.strokeStyle = RULE; g.setLineDash([u, u]);
    [ym - half, ym, ym + half].forEach(function (y) { g.beginPath(); g.moveTo(x0, y); g.lineTo(right, y); g.stroke(); });
    g.setLineDash([]);
    g.font = small; g.fillStyle = GREY; g.textBaseline = "middle"; g.textAlign = "right";
    g.fillText("32,767", x0 - u, ym - half); g.fillText("0", x0 - u, ym); g.fillText("−32,768", x0 - u, ym + half);
    g.textAlign = "center"; g.textBaseline = "top";
    g.fillText(ms + " milliseconds", (x0 + right) / 2, y1 + 6);
    g.textAlign = "left";
    if (mode === "amplitude") {
      g.strokeStyle = ACC; g.setLineDash([2 * u, u]);
      [ym - half * 8000 / 32767, ym + half * 8000 / 32767].forEach(function (y) { g.beginPath(); g.moveTo(x0, y); g.lineTo(right, y); g.stroke(); });
      g.setLineDash([]); g.fillStyle = ACC; g.textBaseline = "bottom";
      g.fillText("Powell's \"Good\" reaches about 8,000", x0 + u, ym - half * 8000 / 32767 - u);
    }
    g.strokeStyle = mode === "pitch" ? BLUE : INK; g.lineWidth = u * 0.6; g.beginPath();
    for (let i = 0; i < n; i++) {
      const x = x0 + (right - x0) * i / (n - 1), y = ym - half * buf[s0 + i];
      if (i === 0) g.moveTo(x, y); else g.lineTo(x, y);
    }
    g.stroke();

    if (mode === "timbre") {
      // Right: the overtones, energy at each multiple of the pitch, in dB.
      const bx0 = W * 0.62, bx1 = W - 60, fmax = 3000, floor = -40;
      const top = Math.max(...step.amps);
      g.strokeStyle = RULE; g.lineWidth = u * 0.3;
      g.beginPath(); g.moveTo(bx0, y1); g.lineTo(bx1, y1); g.stroke();
      g.fillStyle = GREY; g.font = small; g.textBaseline = "top"; g.textAlign = "center";
      [0, 1000, 2000, 3000].forEach(f => g.fillText(fmt(f) + (f === 3000 ? " Hz" : ""), bx0 + (bx1 - bx0) * f / fmax, y1 + 6));
      g.textAlign = "left"; g.textBaseline = "bottom";
      g.fillStyle = ACC; g.fillText("the pitch", bx0, y0 + 20);
      g.fillStyle = BLUE; g.fillText("and its overtones, energy in dB", bx0 + g.measureText("the pitch ").width, y0 + 20);
      step.amps.forEach(function (a, i) {
        const f = (i + 1) * step.f0;
        if (a <= 0 || f > fmax) return;
        const db = Math.max(floor, 20 * Math.log10(a / top));
        const x = bx0 + (bx1 - bx0) * f / fmax, h = (y1 - y0 - 34) * (db - floor) / -floor;
        g.fillStyle = i === 0 ? ACC : BLUE;
        g.fillRect(x - 0.6 * u, y1 - h, 1.2 * u, h);
      });
    }
  }

  function setup() {
    document.querySelectorAll(".tone-demo").forEach(function (box) {
      const img = box.querySelector("img");
      if (!img || box.dataset.ready) return;
      box.dataset.ready = "1";
      const holder = img.parentElement;
      holder.style.position = "relative";
      const canvas = document.createElement("canvas");
      canvas.className = "tone-canvas";
      holder.appendChild(canvas);
      const button = document.createElement("button");
      button.className = "tone-play";
      button.type = "button";
      button.textContent = "▶ Play";
      holder.appendChild(button);
      const demo = { mode: box.dataset.mode, img: img, canvas: canvas, button: button };
      const place = () => { button.style.left = (img.offsetLeft + img.offsetWidth) + "px"; button.style.top = (img.offsetTop + img.offsetHeight) + "px"; };
      place(); img.addEventListener("load", place); window.addEventListener("resize", place);
      button.addEventListener("click", function (e) { e.stopPropagation(); place(); play(demo); });
    });
  }
  // Clip buttons: <button class="clip-play" data-src data-start data-end>
  // play one stretch of a recording (seconds into the file) and stop at its
  // end; pressed while playing, they pause, then resume.
  let clip = null;
  function clipStop() {
    if (!clip) return;
    clip.audio.pause(); clip.button.textContent = clip.label; clip = null;
  }
  function clips() {
    document.querySelectorAll(".clip-play").forEach(function (b) {
      if (b.dataset.ready) return;
      b.dataset.ready = "1";
      const label = b.textContent, t0 = +b.dataset.start, t1 = +b.dataset.end;
      const audio = new Audio(b.dataset.src);
      audio.preload = "none";
      audio.addEventListener("timeupdate", function () { if (audio.currentTime >= t1) clipStop(); });
      audio.addEventListener("ended", clipStop);
      b.addEventListener("click", function (e) {
        e.stopPropagation();
        stop();
        if (clip && clip.button === b) {
          if (audio.paused) { audio.play(); b.textContent = "❚❚ Pause"; }
          else { audio.pause(); b.textContent = "▶ Resume"; }
          return;
        }
        clipStop();
        clip = { audio: audio, button: b, label: label };
        b.textContent = "❚❚ Pause";
        const go = function () { audio.currentTime = t0; audio.play(); };
        if (audio.readyState >= 1) go(); else { audio.addEventListener("loadedmetadata", go, { once: true }); audio.load(); }
      });
    });
  }
  const setupAll = function () { setup(); clips(); };
  window.__toneClip = function () { return clip && clip.audio; };   // for testing
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", setupAll); else setupAll();
  // reveal.js loads after the slides, so its events are bound on load.
  window.addEventListener("load", function () {
    setupAll();
    if (window.Reveal) Reveal.on("slidechanged", function () { stop(); clipStop(); });
  });
})();
