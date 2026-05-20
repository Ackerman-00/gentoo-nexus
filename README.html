<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>gentoo-nexus</title>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:ital,wght@0,400;0,500;0,600;1,400&family=Syne:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet"/>
<style>
  :root {
    --bg: #0b0f0c;
    --bg2: #101510;
    --bg3: #151c16;
    --bg4: #1a2419;
    --surface: #1e281e;
    --surface2: #243124;
    --border: rgba(78,140,90,0.15);
    --border2: rgba(78,140,90,0.28);
    --green: #4f8a5a;
    --green-bright: #6db97c;
    --green-dim: #3a6644;
    --green-glow: rgba(79,138,90,0.12);
    --green-glow2: rgba(79,138,90,0.22);
    --text: #d4e8d6;
    --text2: #8aab8e;
    --text3: #526c55;
    --code-bg: #0d130e;
    --code-border: rgba(79,138,90,0.2);
    --amber: #c8943a;
    --amber-bg: rgba(200,148,58,0.1);
    --amber-border: rgba(200,148,58,0.25);
    --step-size: 32px;
    --radius: 8px;
    --radius-lg: 12px;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  html { scroll-behavior: smooth; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Inter', sans-serif;
    font-size: 15px;
    line-height: 1.75;
    min-height: 100vh;
    overflow-x: hidden;
  }

  /* ── GRID LAYOUT ── */
  .layout {
    display: grid;
    grid-template-columns: 220px 1fr;
    grid-template-rows: auto 1fr;
    max-width: 1100px;
    margin: 0 auto;
    min-height: 100vh;
  }

  /* ── HEADER ── */
  header {
    grid-column: 1 / -1;
    padding: 64px 0 48px;
    text-align: center;
    border-bottom: 1px solid var(--border);
    position: relative;
    overflow: hidden;
  }

  header::before {
    content: '';
    position: absolute;
    inset: 0;
    background: radial-gradient(ellipse 70% 60% at 50% 0%, rgba(79,138,90,0.09) 0%, transparent 70%);
    pointer-events: none;
  }

  .logo-wrap {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 18px;
    margin-bottom: 20px;
  }

  .logo-img {
    width: 52px;
    height: 52px;
    filter: hue-rotate(20deg) saturate(0.8) brightness(0.95);
  }

  .logo-title {
    font-family: 'Syne', sans-serif;
    font-size: 36px;
    font-weight: 800;
    letter-spacing: -1px;
    color: var(--text);
    line-height: 1;
  }

  .logo-title span {
    color: var(--green-bright);
  }

  .tagline {
    font-size: 14px;
    color: var(--text2);
    letter-spacing: 0.5px;
    margin-bottom: 28px;
    font-weight: 300;
  }

  .badges {
    display: flex;
    gap: 10px;
    justify-content: center;
    flex-wrap: wrap;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 5px 13px;
    border-radius: 4px;
    font-size: 11px;
    font-weight: 600;
    font-family: 'IBM Plex Mono', monospace;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    text-decoration: none;
    border: 1px solid var(--border2);
    background: var(--surface);
    color: var(--green-bright);
    transition: background 0.2s, border-color 0.2s;
  }

  .badge:hover { background: var(--surface2); border-color: var(--green); }
  .badge svg { width: 12px; height: 12px; opacity: 0.8; }

  /* ── SIDEBAR ── */
  nav {
    grid-column: 1;
    padding: 40px 0 40px 0;
    border-right: 1px solid var(--border);
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    scrollbar-width: none;
  }

  nav::-webkit-scrollbar { display: none; }

  .nav-section {
    margin-bottom: 28px;
    padding: 0 28px;
  }

  .nav-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--text3);
    margin-bottom: 10px;
    font-family: 'IBM Plex Mono', monospace;
  }

  nav a {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 10px;
    border-radius: var(--radius);
    text-decoration: none;
    font-size: 13px;
    color: var(--text2);
    transition: all 0.15s;
    line-height: 1.4;
  }

  nav a:hover {
    color: var(--text);
    background: var(--green-glow);
  }

  nav a .num {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 11px;
    color: var(--green-dim);
    min-width: 16px;
  }

  /* ── MAIN CONTENT ── */
  main {
    grid-column: 2;
    padding: 40px 48px 80px;
    max-width: 760px;
  }

  /* ── OVERVIEW BLOCK ── */
  .overview-block {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 24px 28px;
    margin-bottom: 48px;
  }

  .overview-block p {
    color: var(--text2);
    font-size: 14px;
    margin-bottom: 20px;
    line-height: 1.7;
  }

  .pipeline-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1px;
    background: var(--border);
    border-radius: var(--radius);
    overflow: hidden;
  }

  .pipeline-item {
    background: var(--code-bg);
    padding: 14px 16px;
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .pipeline-item .key {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 11px;
    color: var(--green-bright);
    font-weight: 600;
  }

  .pipeline-item .val {
    font-size: 12px;
    color: var(--text3);
  }

  /* ── SECTION HEADING ── */
  h2 {
    font-family: 'Syne', sans-serif;
    font-size: 22px;
    font-weight: 700;
    color: var(--text);
    margin: 56px 0 24px;
    letter-spacing: -0.3px;
    display: flex;
    align-items: center;
    gap: 12px;
  }

  h2::before {
    content: '';
    display: block;
    width: 3px;
    height: 22px;
    background: var(--green);
    border-radius: 2px;
    flex-shrink: 0;
  }

  /* ── PACKAGES TABLE ── */
  .pkg-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
    margin-bottom: 16px;
  }

  .pkg-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 14px 16px;
    display: flex;
    flex-direction: column;
    gap: 5px;
    transition: border-color 0.2s;
  }

  .pkg-card:hover { border-color: var(--border2); }

  .pkg-atom {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 12px;
    color: var(--green-bright);
    font-weight: 500;
  }

  .pkg-desc {
    font-size: 13px;
    color: var(--text2);
    line-height: 1.4;
  }

  .pkg-track {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 10px;
    color: var(--text3);
    letter-spacing: 0.05em;
  }

  .pkg-track.live { color: var(--green-dim); }

  .pkg-note {
    font-size: 13px;
    color: var(--text3);
    font-style: italic;
    margin-top: 4px;
  }

  /* ── INSTALL GUIDE STEPS ── */
  .guide-intro {
    background: var(--bg3);
    border-left: 2px solid var(--green);
    border-radius: 0 var(--radius) var(--radius) 0;
    padding: 14px 18px;
    font-size: 13px;
    color: var(--text2);
    margin-bottom: 40px;
    line-height: 1.6;
  }

  .steps { display: flex; flex-direction: column; gap: 0; }

  .step {
    display: grid;
    grid-template-columns: var(--step-size) 1fr;
    gap: 0 20px;
    position: relative;
  }

  .step-col-left {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .step-num {
    width: var(--step-size);
    height: var(--step-size);
    border-radius: 50%;
    background: var(--surface);
    border: 1px solid var(--green);
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'IBM Plex Mono', monospace;
    font-size: 13px;
    font-weight: 600;
    color: var(--green-bright);
    flex-shrink: 0;
    position: relative;
    z-index: 1;
  }

  .step-line {
    width: 1px;
    flex: 1;
    background: var(--border2);
    min-height: 24px;
  }

  .step:last-child .step-line { display: none; }

  .step-body {
    padding: 4px 0 40px;
  }

  .step-title {
    font-family: 'Syne', sans-serif;
    font-size: 17px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 14px;
    letter-spacing: -0.2px;
    line-height: 1.3;
  }

  .step-body p {
    font-size: 13.5px;
    color: var(--text2);
    margin-bottom: 12px;
    line-height: 1.65;
  }

  /* ── CODE BLOCKS ── */
  .code-block {
    background: var(--code-bg);
    border: 1px solid var(--code-border);
    border-radius: var(--radius);
    overflow: hidden;
    margin: 12px 0;
    position: relative;
  }

  .code-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 14px;
    border-bottom: 1px solid var(--code-border);
    background: rgba(0,0,0,0.2);
  }

  .code-lang {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 10px;
    color: var(--text3);
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  .copy-btn {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 10px;
    color: var(--text3);
    background: none;
    border: none;
    cursor: pointer;
    padding: 2px 6px;
    border-radius: 4px;
    transition: color 0.15s, background 0.15s;
    letter-spacing: 0.05em;
  }

  .copy-btn:hover { color: var(--green-bright); background: var(--green-glow); }
  .copy-btn.copied { color: var(--green-bright); }

  pre {
    padding: 16px 18px;
    overflow-x: auto;
    scrollbar-width: thin;
    scrollbar-color: var(--border2) transparent;
  }

  pre::-webkit-scrollbar { height: 4px; }
  pre::-webkit-scrollbar-track { background: transparent; }
  pre::-webkit-scrollbar-thumb { background: var(--border2); border-radius: 2px; }

  code {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 13px;
    line-height: 1.65;
    color: var(--text);
    display: block;
    white-space: pre;
  }

  /* token colors */
  .t-comment { color: var(--text3); font-style: italic; }
  .t-key     { color: #7ec8a0; }
  .t-val     { color: #d4b896; }
  .t-str     { color: #c8d48a; }
  .t-cmd     { color: var(--green-bright); }
  .t-flag    { color: #8ab4c8; }
  .t-section { color: var(--amber); }
  .t-prompt  { color: var(--text3); user-select: none; }

  /* ── NOTE / WARNING ── */
  .note {
    background: var(--amber-bg);
    border: 1px solid var(--amber-border);
    border-radius: var(--radius);
    padding: 12px 16px;
    font-size: 13px;
    color: #d4a85a;
    margin: 12px 0;
    line-height: 1.6;
  }

  .note strong { color: var(--amber); }

  /* ── TROUBLESHOOTING ── */
  .trouble-list { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }

  details {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    transition: border-color 0.2s;
  }

  details:hover { border-color: var(--border2); }
  details[open] { border-color: var(--green-dim); }

  summary {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 18px;
    cursor: pointer;
    list-style: none;
    font-size: 14px;
    font-weight: 500;
    color: var(--text);
    user-select: none;
  }

  summary::-webkit-details-marker { display: none; }

  .sum-arrow {
    margin-left: auto;
    color: var(--text3);
    font-size: 16px;
    transition: transform 0.2s;
  }

  details[open] .sum-arrow { transform: rotate(180deg); }

  .sum-icon {
    width: 24px;
    height: 24px;
    border-radius: 4px;
    background: var(--green-glow2);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .sum-icon svg { width: 14px; height: 14px; color: var(--green-bright); }

  .details-body {
    padding: 0 18px 16px;
    border-top: 1px solid var(--border);
  }

  .details-body p {
    font-size: 13px;
    color: var(--text2);
    margin: 12px 0 8px;
    line-height: 1.65;
  }

  /* ── DISTROBOX SECTION ── */
  .distrobox-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
    margin-top: 12px;
  }

  .db-step {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 14px 16px;
  }

  .db-step-num {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 10px;
    color: var(--green-dim);
    letter-spacing: 0.1em;
    margin-bottom: 6px;
  }

  .db-step p {
    font-size: 13px;
    color: var(--text2);
    margin-bottom: 10px;
    line-height: 1.5;
  }

  /* ── INLINE CODE ── */
  :not(pre) > code {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 12.5px;
    background: var(--code-bg);
    border: 1px solid var(--code-border);
    border-radius: 4px;
    padding: 1px 6px;
    color: var(--green-bright);
    display: inline;
    white-space: nowrap;
  }

  /* ── UPDATE SECTION ── */
  .update-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 24px 28px;
    display: flex;
    align-items: center;
    gap: 24px;
  }

  .update-icon {
    width: 44px;
    height: 44px;
    border-radius: 10px;
    background: var(--green-glow2);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .update-icon svg { width: 22px; height: 22px; color: var(--green-bright); }

  .update-text p { font-size: 13.5px; color: var(--text2); margin-bottom: 12px; }

  /* ── FOOTER ── */
  footer {
    grid-column: 1 / -1;
    border-top: 1px solid var(--border);
    padding: 28px;
    text-align: center;
    font-size: 12px;
    color: var(--text3);
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    font-family: 'IBM Plex Mono', monospace;
    letter-spacing: 0.05em;
  }

  footer a { color: var(--green-dim); text-decoration: none; }
  footer a:hover { color: var(--green-bright); }

  .dot { color: var(--border2); }

  /* ── RESPONSIVE ── */
  @media (max-width: 780px) {
    .layout { grid-template-columns: 1fr; }
    nav { display: none; }
    main { padding: 28px 20px 60px; max-width: 100%; }
    h2 { font-size: 18px; margin: 40px 0 18px; }
    .pkg-grid { grid-template-columns: 1fr; }
    .distrobox-grid { grid-template-columns: 1fr; }
    .pipeline-grid { grid-template-columns: 1fr; }
    .update-card { flex-direction: column; gap: 16px; }
    .logo-title { font-size: 28px; }
  }
</style>
</head>
<body>

<div class="layout">

<!-- HEADER -->
<header>
  <div class="logo-wrap">
    <img class="logo-img" src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" alt="Gentoo"/>
    <div class="logo-title">gentoo<span>-nexus</span></div>
  </div>
  <p class="tagline">bleeding-edge Gentoo overlay &amp; binary host · built for the niri Wayland desktop</p>
  <div class="badges">
    <a class="badge" href="https://github.com/Ackerman-00/gentoo-nexus/actions">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
      FORGE · CI
    </a>
    <a class="badge" href="https://github.com/Ackerman-00/gentoo-nexus/releases/tag/rolling">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
      BINHOST · LIVE
    </a>
    <a class="badge" href="https://github.com/Ackerman-00/gentoo-nexus/blob/main/LICENSE">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      LICENSE · MIT
    </a>
  </div>
</header>

<!-- NAV -->
<nav>
  <div class="nav-section">
    <div class="nav-label">Overview</div>
    <a href="#overview">Overview</a>
    <a href="#packages">Packages</a>
  </div>
  <div class="nav-section">
    <div class="nav-label">Installation</div>
    <a href="#s1"><span class="num">①</span> make.conf</a>
    <a href="#s2"><span class="num">②</span> Config dirs &amp; sync</a>
    <a href="#s3"><span class="num">③</span> Binary host</a>
    <a href="#s4"><span class="num">④</span> Overlay</a>
    <a href="#s5"><span class="num">⑤</span> GPG trust</a>
    <a href="#s6"><span class="num">⑥</span> Kernel</a>
    <a href="#s7"><span class="num">⑦</span> Accept keywords</a>
    <a href="#s8"><span class="num">⑧</span> USE flags</a>
    <a href="#s9"><span class="num">⑨</span> niri + greetd</a>
  </div>
  <div class="nav-section">
    <div class="nav-label">More</div>
    <a href="#update">Staying updated</a>
    <a href="#distrobox">Distrobox testing</a>
    <a href="#contributing">Contributing</a>
    <a href="#troubleshooting">Troubleshooting</a>
  </div>
</nav>

<!-- MAIN -->
<main>

  <!-- OVERVIEW -->
  <section id="overview">
    <div class="overview-block">
      <p><strong style="color:var(--text)">gentoo-nexus</strong> is an autonomous Gentoo overlay and binary host targeting a fully configured <a href="https://github.com/niri-wm/niri" style="color:var(--green-bright)">niri</a> scrollable-tiling Wayland desktop. Packages are compiled nightly via GitHub Actions and served as ready-to-install <code>gpkg</code> binaries — no waiting for local compilation.</p>
      <div class="pipeline-grid">
        <div class="pipeline-item">
          <span class="key">overlay</span>
          <span class="val">ebuilds tracked &amp; auto-updated from upstream</span>
        </div>
        <div class="pipeline-item">
          <span class="key">binhost</span>
          <span class="val">pre-built gpkg binaries via GitHub Releases</span>
        </div>
        <div class="pipeline-item">
          <span class="key">CI</span>
          <span class="val">rebuilds on every version bump or commit</span>
        </div>
      </div>
    </div>
  </section>

  <!-- PACKAGES -->
  <section id="packages">
    <h2>Packages</h2>
    <div class="pkg-grid">
      <div class="pkg-card">
        <span class="pkg-atom">gui-wm/niri</span>
        <span class="pkg-desc">Scrollable-tiling Wayland compositor</span>
        <span class="pkg-track live">9999 · tracks upstream HEAD</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">x11-misc/xwayland-satellite</span>
        <span class="pkg-desc">Rootless XWayland for any Wayland compositor</span>
        <span class="pkg-track live">9999 · tracks upstream HEAD</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">gui-libs/greetd</span>
        <span class="pkg-desc">Minimal login manager daemon</span>
        <span class="pkg-track">stable</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">gui-apps/tuigreet</span>
        <span class="pkg-desc">TUI greeter frontend for greetd</span>
        <span class="pkg-track">stable</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">gui-apps/quickshell</span>
        <span class="pkg-desc">Scriptable desktop widget engine</span>
        <span class="pkg-track">stable</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">app-misc/matugen</span>
        <span class="pkg-desc">Material You color token generator</span>
        <span class="pkg-track">stable</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">gui-apps/dgop</span>
        <span class="pkg-desc">Fast application launcher</span>
        <span class="pkg-track">stable</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">gui-apps/dank-material-shell</span>
        <span class="pkg-desc">Material Design shell for niri</span>
        <span class="pkg-track">stable</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom">app-misc/danksearch</span>
        <span class="pkg-desc">System-wide fuzzy search</span>
        <span class="pkg-track">stable</span>
      </div>
    </div>
    <p class="pkg-note"><code>9999</code> ebuilds rebuild automatically on every new upstream commit.</p>
  </section>

  <!-- INSTALL GUIDE -->
  <section id="install">
    <h2>Installation Guide</h2>
    <div class="guide-intro">
      This guide walks through a complete Gentoo + niri setup using the nexus binhost. All overlay packages are pulled as pre-built <code>gpkg</code> binaries — no local compilation required.
    </div>

    <div class="steps">

      <!-- Step 1 -->
      <div class="step" id="s1">
        <div class="step-col-left">
          <div class="step-num">1</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Configure make.conf</div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">nano</span> /etc/portage/make.conf</code></pre>
          </div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">make.conf</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-comment"># Default flags</span>
<span class="t-key">COMMON_FLAGS</span>=<span class="t-str">"-O2 -march=x86-64 -pipe"</span>
<span class="t-key">CFLAGS</span>=<span class="t-str">"${COMMON_FLAGS}"</span>
<span class="t-key">CXXFLAGS</span>=<span class="t-str">"${COMMON_FLAGS}"</span>
<span class="t-key">FCFLAGS</span>=<span class="t-str">"${COMMON_FLAGS}"</span>
<span class="t-key">FFLAGS</span>=<span class="t-str">"${COMMON_FLAGS}"</span>

<span class="t-comment"># Wayland/Desktop flags</span>
<span class="t-key">USE</span>=<span class="t-str">"elogind -systemd dbus wayland egl"</span>

<span class="t-comment"># Binary host flags</span>
<span class="t-key">FEATURES</span>=<span class="t-str">"getbinpkg parallel-install -binpkg-verify-signature"</span>
<span class="t-key">EMERGE_DEFAULT_OPTS</span>=<span class="t-str">"--getbinpkg --quiet-build=y --keep-going"</span>
<span class="t-key">BINPKG_FORMAT</span>=<span class="t-str">"gpkg"</span>
<span class="t-key">PORTAGE_BINPKG_SIGVERIFY</span>=<span class="t-str">"0"</span>

<span class="t-key">ACCEPT_LICENSE</span>=<span class="t-str">"*"</span>
<span class="t-key">ACCEPT_KEYWORDS</span>=<span class="t-str">"~amd64"</span>
<span class="t-key">MAKEOPTS</span>=<span class="t-str">"-j4"</span>
<span class="t-key">LC_MESSAGES</span>=<span class="t-str">C.UTF-8</span>

<span class="t-comment"># AMD GPU &amp; codec support</span>
<span class="t-key">VIDEO_CARDS</span>=<span class="t-str">"amdgpu radeonsi"</span>
<span class="t-key">USE</span>=<span class="t-str">"${USE} vaapi vdpau vulkan amdgpu ffmpeg encode"</span></code></pre>
          </div>
        </div>
      </div>

      <!-- Step 2 -->
      <div class="step" id="s2">
        <div class="step-col-left">
          <div class="step-num">2</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Prepare config directories &amp; sync Portage</div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">mkdir</span> <span class="t-flag">-p</span> /etc/portage/repos.conf
<span class="t-prompt">$ </span><span class="t-cmd">mkdir</span> <span class="t-flag">-p</span> /etc/portage/binrepos.conf
<span class="t-prompt">$ </span><span class="t-cmd">emerge-webrsync</span></code></pre>
          </div>
        </div>
      </div>

      <!-- Step 3 -->
      <div class="step" id="s3">
        <div class="step-col-left">
          <div class="step-num">3</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Configure the binary host</div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">nano</span> /etc/portage/binrepos.conf/gentoo-nexus.conf</code></pre>
          </div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">ini</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-section">[gentoo-nexus]</span>
<span class="t-key">priority</span> = <span class="t-val">9999</span>
<span class="t-key">sync-uri</span> = <span class="t-str">https://github.com/Ackerman-00/gentoo-nexus/releases/download/rolling/</span></code></pre>
          </div>
        </div>
      </div>

      <!-- Step 4 -->
      <div class="step" id="s4">
        <div class="step-col-left">
          <div class="step-num">4</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Add the overlay</div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">nano</span> /etc/portage/repos.conf/gentoo-nexus.conf</code></pre>
          </div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">ini</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-section">[gentoo-nexus]</span>
<span class="t-key">location</span>   = <span class="t-str">/var/db/repos/gentoo-nexus</span>
<span class="t-key">sync-type</span>  = <span class="t-val">git</span>
<span class="t-key">sync-uri</span>   = <span class="t-str">https://github.com/Ackerman-00/gentoo-nexus.git</span>
<span class="t-key">priority</span>   = <span class="t-val">9999</span>
<span class="t-key">auto-sync</span>  = <span class="t-val">yes</span></code></pre>
          </div>
          <p>Install git and sync the overlay:</p>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">emerge</span> dev-vcs/git
<span class="t-prompt">$ </span><span class="t-cmd">emaint</span> sync <span class="t-flag">-r</span> gentoo-nexus</code></pre>
          </div>
        </div>
      </div>

      <!-- Step 5 -->
      <div class="step" id="s5">
        <div class="step-col-left">
          <div class="step-num">5</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Initialize Gentoo GPG trust</div>
          <p>Required on fresh stage3 installs — without this, Portage rejects signed packages from the official Gentoo binhost.</p>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">getuto</span></code></pre>
          </div>
        </div>
      </div>

      <!-- Step 6 -->
      <div class="step" id="s6">
        <div class="step-col-left">
          <div class="step-num">6</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Install the kernel</div>
          <p>Pull the pre-built distribution kernel. No manual compilation required.</p>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">emerge</span> <span class="t-flag">-g</span> sys-kernel/gentoo-kernel:7.0.5
<span class="t-prompt">$ </span><span class="t-cmd">emerge</span> <span class="t-flag">--config</span> sys-kernel/gentoo-kernel:7.0.5</code></pre>
          </div>
          <div class="note">
            <strong>Note:</strong> <code>sys-kernel/gentoo-kernel</code> is Gentoo's distribution kernel. It installs itself automatically via Portage with sane defaults for most desktop hardware.
          </div>
        </div>
      </div>

      <!-- Step 7 -->
      <div class="step" id="s7">
        <div class="step-col-left">
          <div class="step-num">7</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Accept keywords for nexus packages</div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">mkdir</span> <span class="t-flag">-p</span> /etc/portage/package.accept_keywords
<span class="t-prompt">$ </span><span class="t-cmd">echo</span> <span class="t-str">"*/*::gentoo-nexus **"</span> > /etc/portage/package.accept_keywords/nexus</code></pre>
          </div>
        </div>
      </div>

      <!-- Step 8 -->
      <div class="step" id="s8">
        <div class="step-col-left">
          <div class="step-num">8</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Configure USE flags for graphics &amp; media</div>
          <p>AMD GPU / 32-bit compatibility (needed for Steam and similar):</p>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">echo</span> <span class="t-str">"media-libs/mesa abi_x86_32"</span> | tee /etc/portage/package.use/graphics
<span class="t-prompt">$ </span><span class="t-cmd">echo</span> <span class="t-str">"media-libs/vulkan-loader abi_x86_32"</span> | tee <span class="t-flag">-a</span> /etc/portage/package.use/graphics
<span class="t-prompt">$ </span><span class="t-cmd">echo</span> <span class="t-str">"x11-libs/libdrm abi_x86_32"</span> | tee <span class="t-flag">-a</span> /etc/portage/package.use/graphics</code></pre>
          </div>
          <p>PipeWire extras (required for screen sharing, audio routing):</p>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">mkdir</span> <span class="t-flag">-p</span> /etc/portage/package.use
<span class="t-prompt">$ </span><span class="t-cmd">echo</span> <span class="t-str">"media-video/pipewire extra"</span> >> /etc/portage/package.use/pipewire
<span class="t-prompt">$ </span><span class="t-cmd">echo</span> <span class="t-str">"media-video/ffmpeg -sdl"</span> >> /etc/portage/package.use/ffmpeg</code></pre>
          </div>
        </div>
      </div>

      <!-- Step 9 -->
      <div class="step" id="s9">
        <div class="step-col-left">
          <div class="step-num">9</div>
          <div class="step-line"></div>
        </div>
        <div class="step-body">
          <div class="step-title">Install niri, greetd &amp; tuigreet</div>
          <div class="code-block">
            <div class="code-header">
              <span class="code-lang">bash</span>
              <button class="copy-btn" onclick="copyCode(this)">copy</button>
            </div>
            <pre><code><span class="t-prompt">$ </span><span class="t-cmd">emerge</span> <span class="t-flag">-g</span> gui-wm/niri gui-libs/greetd gui-apps/tuigreet</code></pre>
          </div>
        </div>
      </div>

    </div><!-- /steps -->
  </section>

  <!-- STAYING UPDATED -->
  <section id="update">
    <h2>Staying Updated</h2>
    <div class="update-card">
      <div class="update-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 12a9 9 0 11-9-9c2.52 0 4.93 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/></svg>
      </div>
      <div class="update-text">
        <p>No manual intervention needed. Packages update with your system. The CI pipeline handles version bumps, binary rebuilds, and index updates automatically.</p>
        <div class="code-block">
          <div class="code-header">
            <span class="code-lang">bash</span>
            <button class="copy-btn" onclick="copyCode(this)">copy</button>
          </div>
          <pre><code><span class="t-prompt">$ </span><span class="t-cmd">emerge</span> <span class="t-flag">-g -uDN</span> @world</code></pre>
        </div>
      </div>
    </div>
  </section>

  <!-- DISTROBOX -->
  <section id="distrobox">
    <h2>Testing with Distrobox</h2>
    <p style="font-size:13.5px;color:var(--text2);margin-bottom:16px;">Try the overlay and binhost safely inside an isolated container — no risk to your host system.</p>
    <div class="distrobox-grid">
      <div class="db-step">
        <div class="db-step-num">STEP 01 · HOST</div>
        <p>Create and enter a Gentoo container:</p>
        <div class="code-block">
          <div class="code-header"><span class="code-lang">bash</span><button class="copy-btn" onclick="copyCode(this)">copy</button></div>
          <pre><code><span class="t-prompt">$ </span><span class="t-cmd">distrobox</span> create \
  <span class="t-flag">--image</span> gentoo/stage3:amd64-desktop-openrc \
  <span class="t-flag">--name</span> gentoo-nexus-test

<span class="t-prompt">$ </span><span class="t-cmd">distrobox</span> enter gentoo-nexus-test</code></pre>
        </div>
      </div>
      <div class="db-step">
        <div class="db-step-num">STEP 02 · CONTAINER</div>
        <p>Then follow the installation guide above from inside the container.</p>
        <div class="note" style="font-size:12px;margin:0;">Start from step 1 (make.conf) — all steps apply identically inside the container.</div>
      </div>
    </div>
  </section>

  <!-- CONTRIBUTING -->
  <section id="contributing">
    <h2>Contributing</h2>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-bottom:8px;">
      <div class="pkg-card">
        <span class="pkg-atom" style="color:var(--text2)">Request a package</span>
        <span class="pkg-desc">Open an issue with the package atom</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom" style="color:var(--text2)">Fix an ebuild</span>
        <span class="pkg-desc">Submit a PR following the existing category structure</span>
      </div>
      <div class="pkg-card">
        <span class="pkg-atom" style="color:var(--text2)">Report a CI failure</span>
        <span class="pkg-desc">Actions → Gentoo Build Relay → Run workflow with the atom</span>
      </div>
    </div>
    <p style="font-size:13px;color:var(--text3);margin-top:8px;">Version bumps are automated — no need to bump manually.</p>
  </section>

  <!-- TROUBLESHOOTING -->
  <section id="troubleshooting">
    <h2>Troubleshooting</h2>
    <div class="trouble-list">

      <details>
        <summary>
          <div class="sum-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
          Portage ignores the binhost and compiles from source
          <span class="sum-arrow">&#8964;</span>
        </summary>
        <div class="details-body">
          <p>Verify your <code>make.conf</code> contains all three binary host directives and run <code>emerge --info | grep FEATURES</code> to confirm they are active:</p>
          <div class="code-block"><div class="code-header"><span class="code-lang">bash</span><button class="copy-btn" onclick="copyCode(this)">copy</button></div>
          <pre><code><span class="t-key">BINPKG_FORMAT</span>=<span class="t-str">"gpkg"</span>
<span class="t-key">FEATURES</span>=<span class="t-str">"getbinpkg -binpkg-verify-signature"</span>
<span class="t-key">EMERGE_DEFAULT_OPTS</span>=<span class="t-str">"--getbinpkg --quiet-build=y --keep-going"</span>
<span class="t-key">PORTAGE_BINPKG_SIGVERIFY</span>=<span class="t-str">"0"</span></code></pre></div>
        </div>
      </details>

      <details>
        <summary>
          <div class="sum-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg></div>
          Signature verification error on binhost packages
          <span class="sum-arrow">&#8964;</span>
        </summary>
        <div class="details-body">
          <p>The nexus binhost does not ship signed package indexes. Ensure <code>make.conf</code> has:</p>
          <div class="code-block"><div class="code-header"><span class="code-lang">bash</span><button class="copy-btn" onclick="copyCode(this)">copy</button></div>
          <pre><code><span class="t-key">FEATURES</span>=<span class="t-str">"... -binpkg-verify-signature"</span>
<span class="t-key">PORTAGE_BINPKG_SIGVERIFY</span>=<span class="t-str">"0"</span></code></pre></div>
        </div>
      </details>

      <details>
        <summary>
          <div class="sum-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4"/></svg></div>
          A package failed to build in CI
          <span class="sum-arrow">&#8964;</span>
        </summary>
        <div class="details-body">
          <p>Go to <strong style="color:var(--text)">Actions → Gentoo Build Relay → Run workflow</strong>, enter the package atom (e.g. <code>gui-wm/niri</code>), and retry after a few minutes.</p>
        </div>
      </details>

      <details>
        <summary>
          <div class="sum-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h18M3 18h18"/></svg></div>
          eselect repository crashes on duplicate
          <span class="sum-arrow">&#8964;</span>
        </summary>
        <div class="details-body">
          <p>If the repo was previously added manually, remove the conflicting entry first, then re-add via <code>repos.conf</code> as shown in step 4:</p>
          <div class="code-block"><div class="code-header"><span class="code-lang">bash</span><button class="copy-btn" onclick="copyCode(this)">copy</button></div>
          <pre><code><span class="t-prompt">$ </span><span class="t-cmd">eselect</span> repository remove gentoo-nexus</code></pre></div>
        </div>
      </details>

      <details>
        <summary>
          <div class="sum-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/></svg></div>
          404 Not Found or packages missing after a CI update
          <span class="sum-arrow">&#8964;</span>
        </summary>
        <div class="details-body">
          <p>Portage caches the <code>Packages</code> index locally. Bust the cache and re-sync:</p>
          <div class="code-block"><div class="code-header"><span class="code-lang">bash</span><button class="copy-btn" onclick="copyCode(this)">copy</button></div>
          <pre><code><span class="t-prompt">$ </span><span class="t-cmd">rm</span> <span class="t-flag">-rf</span> /var/cache/binhost/*
<span class="t-prompt">$ </span><span class="t-cmd">emaint</span> sync <span class="t-flag">-r</span> gentoo-nexus</code></pre></div>
        </div>
      </details>

      <details>
        <summary>
          <div class="sum-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg></div>
          Mesa / Vulkan not working after install
          <span class="sum-arrow">&#8964;</span>
        </summary>
        <div class="details-body">
          <p>Confirm the USE flags were applied before the mesa emerge. If flags were added after, force a rebuild:</p>
          <div class="code-block"><div class="code-header"><span class="code-lang">bash</span><button class="copy-btn" onclick="copyCode(this)">copy</button></div>
          <pre><code><span class="t-prompt">$ </span><span class="t-cmd">cat</span> /etc/portage/package.use/graphics
<span class="t-comment"># expected:</span>
<span class="t-str">media-libs/mesa abi_x86_32</span>
<span class="t-str">media-libs/vulkan-loader abi_x86_32</span>
<span class="t-str">x11-libs/libdrm abi_x86_32</span>

<span class="t-prompt">$ </span><span class="t-cmd">emerge</span> <span class="t-flag">-g --oneshot</span> media-libs/mesa media-libs/vulkan-loader</code></pre></div>
        </div>
      </details>

    </div>
  </section>

</main>

<!-- FOOTER -->
<footer>
  <span>built on Gentoo</span>
  <span class="dot">·</span>
  <span>powered by Portage</span>
  <span class="dot">·</span>
  <span>automated with GitHub Actions</span>
  <span class="dot">·</span>
  <a href="https://github.com/Ackerman-00/gentoo-nexus">Ackerman-00/gentoo-nexus</a>
</footer>

</div><!-- /layout -->

<script>
function copyCode(btn) {
  const pre = btn.closest('.code-block').querySelector('pre');
  const text = pre.innerText.replace(/^\$\s*/gm, '').trim();
  navigator.clipboard.writeText(text).then(() => {
    btn.textContent = 'copied!';
    btn.classList.add('copied');
    setTimeout(() => { btn.textContent = 'copy'; btn.classList.remove('copied'); }, 1800);
  });
}
</script>

</body>
</html>
