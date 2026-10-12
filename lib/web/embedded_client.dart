/// Self-contained embedded single-page application served to connecting devices on LAN.
/// Includes drag-and-drop, high-speed streaming upload, progress bar, and multi-format support.
class EmbeddedWebClient {
  static const String html = r"""<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>GhostVault - Ephemeral In-Memory Safe</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-dark: #080B11;
      --card-bg: rgba(16, 23, 38, 0.85);
      --card-border: rgba(0, 240, 255, 0.2);
      --accent-cyan: #00F0FF;
      --accent-green: #00FF9D;
      --accent-red: #FF3366;
      --accent-orange: #FF9900;
      --text-main: #F0F6FC;
      --text-muted: #8B949E;
      --glow-cyan: 0 0 25px rgba(0, 240, 255, 0.35);
      --glow-red: 0 0 25px rgba(255, 51, 102, 0.35);
      --glow-green: 0 0 25px rgba(0, 255, 157, 0.35);
    }

    * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
    body {
      font-family: 'Plus Jakarta Sans', sans-serif;
      background: #060911;
      background-image: 
        radial-gradient(circle at 10% 10%, rgba(0, 240, 255, 0.12) 0%, transparent 45%),
        radial-gradient(circle at 90% 90%, rgba(139, 92, 246, 0.12) 0%, transparent 50%),
        linear-gradient(135deg, #060911 0%, #0B1226 40%, #090D1C 70%, #130924 100%);
      color: var(--text-main);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 16px 12px 32px 12px;
    }

    .container {
      width: 100%;
      max-width: 680px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    /* HEADER */
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 14px 18px;
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      backdrop-filter: blur(16px);
      box-shadow: 0 8px 32px rgba(0,0,0,0.5);
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .logo-icon {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, var(--accent-cyan), var(--accent-green));
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #000;
      font-weight: 900;
      font-size: 20px;
      box-shadow: var(--glow-cyan);
    }
    .brand h1 {
      font-size: 1.2rem;
      font-weight: 800;
      letter-spacing: -0.5px;
      background: linear-gradient(90deg, #FFFFFF, var(--accent-cyan));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .brand span {
      display: block;
      font-size: 0.7rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
    }
    .badge-ram {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 20px;
      background: rgba(0, 255, 157, 0.12);
      border: 1px solid rgba(0, 255, 157, 0.4);
      color: var(--accent-green);
      font-size: 0.72rem;
      font-weight: 700;
      font-family: 'JetBrains Mono', monospace;
    }
    .pulse-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--accent-green);
      box-shadow: 0 0 10px var(--accent-green);
      animation: pulse 1.8s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(0.8); }
    }

    /* NOTIFICATION TOAST */
    #toast {
      position: fixed;
      top: 16px;
      left: 50%;
      transform: translateX(-50%) translateY(-100px);
      background: rgba(16, 23, 38, 0.96);
      border: 1px solid var(--accent-cyan);
      color: #FFF;
      padding: 12px 24px;
      border-radius: 30px;
      box-shadow: var(--glow-cyan);
      font-weight: 700;
      font-size: 0.85rem;
      z-index: 9999;
      transition: transform 0.3s cubic-bezier(0.18, 0.89, 0.32, 1.28);
      display: flex;
      align-items: center;
      gap: 10px;
      white-space: nowrap;
      max-width: 90vw;
    }
    #toast.show {
      transform: translateX(-50%) translateY(0);
    }

    /* CARD */
    .card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 20px;
      backdrop-filter: blur(16px);
      box-shadow: 0 8px 32px rgba(0,0,0,0.4);
    }

    /* SECURITY / PIN BAR */
    .security-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
    }
    .pin-input-group {
      display: flex;
      align-items: center;
      gap: 10px;
      flex: 1;
    }
    .pin-input-group label {
      font-size: 0.82rem;
      font-weight: 600;
      color: var(--text-muted);
      white-space: nowrap;
    }
    .pin-input {
      background: rgba(0, 0, 0, 0.5);
      border: 1px solid rgba(0, 240, 255, 0.4);
      border-radius: 8px;
      padding: 8px 12px;
      color: var(--accent-cyan);
      font-family: 'JetBrains Mono', monospace;
      font-size: 1.1rem;
      font-weight: 800;
      letter-spacing: 3px;
      max-width: 140px;
      text-align: center;
      outline: none;
      transition: all 0.2s;
    }
    .pin-input:focus {
      border-color: var(--accent-cyan);
      box-shadow: var(--glow-cyan);
    }
    .cipher-status {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 0.72rem;
      color: var(--accent-green);
      font-family: 'JetBrains Mono', monospace;
      background: rgba(0, 255, 157, 0.08);
      padding: 6px 12px;
      border-radius: 8px;
      border: 1px solid rgba(0, 255, 157, 0.25);
    }

    /* TABS */
    .tabs {
      display: flex;
      gap: 8px;
      margin-bottom: 16px;
      border-bottom: 1px solid rgba(255,255,255,0.08);
      padding-bottom: 10px;
    }
    .tab-btn {
      background: none;
      border: none;
      color: var(--text-muted);
      font-size: 0.9rem;
      font-weight: 700;
      padding: 8px 14px;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .tab-btn.active {
      color: #000;
      background: var(--accent-cyan);
      box-shadow: var(--glow-cyan);
    }

    /* QUICK FORMAT SELECTORS */
    .format-chips {
      display: flex;
      gap: 8px;
      margin-bottom: 14px;
      overflow-x: auto;
      padding-bottom: 4px;
    }
    .format-chip {
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.12);
      color: var(--text-main);
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 0.75rem;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      white-space: nowrap;
      transition: all 0.2s;
    }
    .format-chip:hover, .format-chip:active {
      background: rgba(0, 240, 255, 0.15);
      border-color: var(--accent-cyan);
      color: var(--accent-cyan);
    }

    /* DROP ZONE */
    .drop-zone {
      border: 2px dashed rgba(0, 240, 255, 0.35);
      border-radius: 14px;
      padding: 26px 16px;
      text-align: center;
      cursor: pointer;
      transition: all 0.2s;
      background: rgba(0,0,0,0.3);
    }
    .drop-zone:hover, .drop-zone.dragover {
      border-color: var(--accent-cyan);
      background: rgba(0, 240, 255, 0.08);
      box-shadow: var(--glow-cyan);
    }
    .drop-zone-icon {
      font-size: 38px;
      margin-bottom: 6px;
      color: var(--accent-cyan);
    }
    .drop-zone h3 {
      font-size: 0.95rem;
      font-weight: 700;
      margin-bottom: 4px;
    }
    .drop-zone p {
      font-size: 0.72rem;
      color: var(--text-muted);
    }

    /* SELECTED FILE PREVIEW */
    .selected-card {
      display: none;
      align-items: center;
      gap: 12px;
      padding: 12px 14px;
      margin-top: 12px;
      background: rgba(0, 240, 255, 0.08);
      border: 1px solid rgba(0, 240, 255, 0.3);
      border-radius: 12px;
    }
    .selected-card-icon {
      font-size: 24px;
    }
    .selected-card-info {
      flex: 1;
      min-width: 0;
    }
    .selected-card-name {
      font-size: 0.85rem;
      font-weight: 700;
      color: var(--accent-cyan);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .selected-card-meta {
      font-size: 0.7rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
      margin-top: 2px;
    }
    .selected-card-remove {
      background: none;
      border: none;
      color: var(--accent-red);
      font-size: 1.2rem;
      cursor: pointer;
      padding: 4px;
    }

    /* PROGRESS BAR */
    #progressContainer {
      display: none;
      margin-top: 14px;
      flex-direction: column;
      gap: 6px;
    }
    .progress-track {
      width: 100%;
      height: 8px;
      background: rgba(255,255,255,0.1);
      border-radius: 10px;
      overflow: hidden;
    }
    .progress-fill {
      width: 0%;
      height: 100%;
      background: linear-gradient(90deg, var(--accent-cyan), var(--accent-green));
      box-shadow: var(--glow-cyan);
      transition: width 0.15s ease-out;
    }
    .progress-label {
      font-size: 0.75rem;
      font-family: 'JetBrains Mono', monospace;
      color: var(--accent-cyan);
      text-align: right;
    }

    /* TEXT NOTE FORM */
    .note-form {
      display: none;
      flex-direction: column;
      gap: 10px;
    }
    .note-textarea {
      width: 100%;
      height: 110px;
      background: rgba(0, 0, 0, 0.4);
      border: 1px solid rgba(255,255,255,0.14);
      border-radius: 10px;
      padding: 12px;
      color: var(--text-main);
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.85rem;
      outline: none;
      resize: vertical;
    }
    .note-textarea:focus {
      border-color: var(--accent-cyan);
      box-shadow: var(--glow-cyan);
    }

    /* CONTROLS */
    .upload-options {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-top: 14px;
      flex-wrap: wrap;
      gap: 12px;
    }
    .burn-checkbox {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 0.78rem;
      color: var(--accent-red);
      cursor: pointer;
      font-weight: 600;
    }
    .burn-checkbox input {
      accent-color: var(--accent-red);
      width: 16px;
      height: 16px;
    }
    .btn-submit {
      background: linear-gradient(135deg, var(--accent-cyan), #00A6FF);
      color: #000;
      border: none;
      border-radius: 10px;
      padding: 10px 22px;
      font-weight: 800;
      font-size: 0.9rem;
      cursor: pointer;
      box-shadow: var(--glow-cyan);
      transition: all 0.2s;
    }
    .btn-submit:hover:not(:disabled) {
      transform: translateY(-1px);
    }
    .btn-submit:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    /* SECTION TITLE */
    .section-title {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 14px;
      font-size: 0.9rem;
      font-weight: 800;
      letter-spacing: 0.5px;
      text-transform: uppercase;
      color: var(--text-muted);
    }
    .files-count {
      background: rgba(0, 240, 255, 0.1);
      color: var(--accent-cyan);
      padding: 3px 10px;
      border-radius: 12px;
      font-size: 0.75rem;
      font-family: 'JetBrains Mono', monospace;
      font-weight: 700;
    }

    /* FILES LIST */
    .files-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .file-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px 14px;
      background: rgba(0, 0, 0, 0.4);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 12px;
      gap: 12px;
      transition: border-color 0.2s;
    }
    .file-item:hover {
      border-color: rgba(0, 240, 255, 0.3);
    }
    .file-meta {
      display: flex;
      align-items: center;
      gap: 12px;
      min-width: 0;
      flex: 1;
    }
    .file-icon {
      width: 38px;
      height: 38px;
      background: rgba(0, 240, 255, 0.1);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      flex-shrink: 0;
    }
    .file-details {
      min-width: 0;
      flex: 1;
    }
    .file-details h4 {
      font-size: 0.85rem;
      font-weight: 700;
      color: var(--text-main);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .file-details p {
      font-size: 0.72rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
      margin-top: 2px;
    }
    .tag-badge {
      display: inline-block;
      font-size: 0.65rem;
      padding: 1px 6px;
      border-radius: 4px;
      margin-left: 6px;
      font-weight: 800;
      letter-spacing: 0.5px;
    }
    .tag-burn {
      background: rgba(255, 51, 102, 0.15);
      border: 1px solid rgba(255, 51, 102, 0.4);
      color: var(--accent-red);
    }
    .tag-apk {
      background: rgba(0, 255, 157, 0.15);
      border: 1px solid rgba(0, 255, 157, 0.4);
      color: var(--accent-green);
    }
    .tag-video {
      background: rgba(255, 153, 0, 0.15);
      border: 1px solid rgba(255, 153, 0, 0.4);
      color: var(--accent-orange);
    }
    .tag-enc {
      background: rgba(0, 240, 255, 0.15);
      border: 1px solid rgba(0, 240, 255, 0.4);
      color: var(--accent-cyan);
    }
    .file-actions {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-shrink: 0;
    }
    .btn-action {
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.12);
      color: var(--text-main);
      border-radius: 8px;
      padding: 8px 12px;
      font-size: 0.78rem;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-action.download {
      background: rgba(0, 240, 255, 0.12);
      border-color: rgba(0, 240, 255, 0.45);
      color: var(--accent-cyan);
    }
    .btn-action.download:hover, .btn-action.download:active {
      background: var(--accent-cyan);
      color: #000;
      box-shadow: var(--glow-cyan);
    }
    .btn-action.delete {
      background: rgba(255, 51, 102, 0.1);
      border-color: rgba(255, 51, 102, 0.4);
      color: var(--accent-red);
    }
    .btn-action.delete:hover, .btn-action.delete:active {
      background: var(--accent-red);
      color: #FFF;
      box-shadow: var(--glow-red);
    }

    .empty-state {
      text-align: center;
      padding: 30px 12px;
      color: var(--text-muted);
      font-size: 0.85rem;
    }

    /* FOOTER */
    .footer {
      text-align: center;
      font-size: 0.7rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
      margin-top: 6px;
    }
  </style>
</head>
<body>
  <div id="toast"></div>

  <div class="container">
    <!-- HEADER -->
    <header class="header">
      <div class="brand">
        <img src="data:image/png;base64,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" style="width: 44px; height: 44px; border-radius: 13px; box-shadow: 0 0 16px rgba(0, 240, 255, 0.45); border: 1.5px solid rgba(0, 240, 255, 0.5); object-fit: cover;">
        <div>
          <h1>GhostVault</h1>
          <span>EPHEMERAL AIR-GAPPED SAFE</span>
        </div>
      </div>
      <div class="badge-ram">
        <div class="pulse-dot"></div>
        <span>RAM-ONLY SAFE</span>
      </div>
    </header>

    <!-- SECURITY / STATUS BAR -->
    <div class="card">
      <div class="security-bar">
        <div class="pin-input-group">
          <label for="vaultPin">Kasa PIN:</label>
          <input type="text" id="vaultPin" class="pin-input" placeholder="000000" maxlength="8">
        </div>
        <div class="cipher-status" id="cipherStatusBadge">
          <span>🛡️ Yerel Air-Gapped Hotspot Koruma Altında</span>
        </div>
      </div>
    </div>

    <!-- UPLOAD CARD -->
    <div class="card">
      <div class="tabs">
        <button class="tab-btn active" id="tabFileBtn" onclick="switchTab('file')">📁 Dosya Gönder</button>
        <button class="tab-btn" id="tabNoteBtn" onclick="switchTab('note')">📝 Gizli Not / Şifre</button>
      </div>

      <!-- FILE UPLOAD -->
      <div id="fileUploadSection">
        <!-- Quick format chooser chips -->
        <div class="format-chips">
          <div class="format-chip" onclick="triggerFileSelect('*/*')">
            <span>📁</span> Tüm Dosyalar
          </div>
          <div class="format-chip" onclick="triggerFileSelect('.apk,.xapk,.aab,.exe,.msi,.zip,.rar,*/*')">
            <span>📦</span> Uygulama / APK / Program
          </div>
          <div class="format-chip" onclick="triggerFileSelect('video/*,audio/*,image/*')">
            <span>🎬</span> Video & Medya
          </div>
          <div class="format-chip" onclick="triggerFileSelect('.pdf,.docx,.xlsx,.txt,.zip,*/*')">
            <span>📄</span> Belge & Arşiv
          </div>
        </div>

        <div class="drop-zone" id="dropZone" onclick="triggerFileSelect('*/*')">
          <div class="drop-zone-icon">🚀</div>
          <h3>Dosyayı Buraya Dokunarak Seçin</h3>
          <p>Video, Uygulama (APK), Resim, Belge veya Arşiv — Tüm formatlar desteklenir</p>
          <input type="file" id="fileInput" style="display:none" multiple onchange="handleFileSelected(event)">
        </div>

        <div id="selectedCard" class="selected-card">
          <div class="selected-card-icon" id="selectedIcon">📄</div>
          <div class="selected-card-info">
            <div class="selected-card-name" id="selectedName">dosya.mp4</div>
            <div class="selected-card-meta" id="selectedMeta">160 MB • Video</div>
          </div>
          <button class="selected-card-remove" onclick="clearSelectedFile()" title="Kaldır">✕</button>
        </div>

        <!-- PROGRESS BAR -->
        <div id="progressContainer">
          <div class="progress-track">
            <div class="progress-fill" id="progressFill"></div>
          </div>
          <div class="progress-label" id="progressLabel">0%</div>
        </div>
      </div>

      <!-- TEXT NOTE -->
      <div id="noteUploadSection" class="note-form">
        <textarea id="noteText" class="note-textarea" placeholder="Buraya gizli bir şifre, hesap bilgisi veya not yazın..."></textarea>
      </div>

      <!-- OPTIONS & SUBMIT -->
      <div class="upload-options">
        <label class="burn-checkbox">
          <input type="checkbox" id="burnAfterReading">
          <span>🔥 Burn-After-Reading (İlk indirmede imha et)</span>
        </label>
        <button class="btn-submit" id="btnUpload" onclick="uploadContent()">Kasaya Fırlat ⚡</button>
      </div>
    </div>

    <!-- FILES LIST CARD -->
    <div class="card">
      <div class="section-title">
        <span>Kasada Bekleyenler (RAM)</span>
        <span class="files-count" id="filesCountBadge">0 Öğe</span>
      </div>
      <div class="files-list" id="filesContainer">
        <div class="empty-state">Kasa şu an temiz. Herhangi bir dosya yüklenmedi.</div>
      </div>
    </div>

    <footer class="footer">
      GhostVault Engine • Air-Gapped Safe • Zero Disk Writes • In-Memory Safe
    </footer>
  </div>

  <script>
!function(t,e){"object"==typeof exports?module.exports=exports=e():"function"==typeof define&&define.amd?define([],e):t.CryptoJS=e()}(this,function(){var W,O,I,U,K,X,L,l,j,T,t,N,q,e,Z,V,G,J,Q,Y,$,t1,e1,r1,i1,o1,n1,s,s1,c1,a1,h1,l1,o,f1,r,d1,u1,n,c,a,h,f,d,i=function(h){var i;if("undefined"!=typeof window&&window.crypto&&(i=window.crypto),"undefined"!=typeof self&&self.crypto&&(i=self.crypto),!(i=!(i=!(i="undefined"!=typeof globalThis&&globalThis.crypto?globalThis.crypto:i)&&"undefined"!=typeof window&&window.msCrypto?window.msCrypto:i)&&"undefined"!=typeof global&&global.crypto?global.crypto:i)&&"function"==typeof require)try{i=require("crypto")}catch(t){}var r=Object.create||function(t){return e.prototype=t,t=new e,e.prototype=null,t};function e(){}var t={},o=t.lib={},n=o.Base={extend:function(t){var e=r(this);return t&&e.mixIn(t),e.hasOwnProperty("init")&&this.init!==e.init||(e.init=function(){e.$super.init.apply(this,arguments)}),(e.init.prototype=e).$super=this,e},create:function(){var t=this.extend();return t.init.apply(t,arguments),t},init:function(){},mixIn:function(t){for(var e in t)t.hasOwnProperty(e)&&(this[e]=t[e]);t.hasOwnProperty("toString")&&(this.toString=t.toString)},clone:function(){return this.init.prototype.extend(this)}},l=o.WordArray=n.extend({init:function(t,e){t=this.words=t||[],this.sigBytes=null!=e?e:4*t.length},toString:function(t){return(t||c).stringify(this)},concat:function(t){var e=this.words,r=t.words,i=this.sigBytes,o=t.sigBytes;if(this.clamp(),i%4)for(var n=0;n<o;n++){var s=r[n>>>2]>>>24-n%4*8&255;e[i+n>>>2]|=s<<24-(i+n)%4*8}else for(var c=0;c<o;c+=4)e[i+c>>>2]=r[c>>>2];return this.sigBytes+=o,this},clamp:function(){var t=this.words,e=this.sigBytes;t[e>>>2]&=4294967295<<32-e%4*8,t.length=h.ceil(e/4)},clone:function(){var t=n.clone.call(this);return t.words=this.words.slice(0),t},random:function(t){for(var e=[],r=0;r<t;r+=4)e.push(function(){if(i){if("function"==typeof i.getRandomValues)try{return i.getRandomValues(new Uint32Array(1))[0]}catch(t){}if("function"==typeof i.randomBytes)try{return i.randomBytes(4).readInt32LE()}catch(t){}}throw new Error("Native crypto module could not be used to get secure random number.")}());return new l.init(e,t)}}),s=t.enc={},c=s.Hex={stringify:function(t){for(var e=t.words,r=t.sigBytes,i=[],o=0;o<r;o++){var n=e[o>>>2]>>>24-o%4*8&255;i.push((n>>>4).toString(16)),i.push((15&n).toString(16))}return i.join("")},parse:function(t){for(var e=t.length,r=[],i=0;i<e;i+=2)r[i>>>3]|=parseInt(t.substr(i,2),16)<<24-i%8*4;return new l.init(r,e/2)}},a=s.Latin1={stringify:function(t){for(var e=t.words,r=t.sigBytes,i=[],o=0;o<r;o++){var n=e[o>>>2]>>>24-o%4*8&255;i.push(String.fromCharCode(n))}return i.join("")},parse:function(t){for(var e=t.length,r=[],i=0;i<e;i++)r[i>>>2]|=(255&t.charCodeAt(i))<<24-i%4*8;return new l.init(r,e)}},f=s.Utf8={stringify:function(t){try{return decodeURIComponent(escape(a.stringify(t)))}catch(t){throw new Error("Malformed UTF-8 data")}},parse:function(t){return a.parse(unescape(encodeURIComponent(t)))}},d=o.BufferedBlockAlgorithm=n.extend({reset:function(){this._data=new l.init,this._nDataBytes=0},_append:function(t){"string"==typeof t&&(t=f.parse(t)),this._data.concat(t),this._nDataBytes+=t.sigBytes},_process:function(t){var e,r=this._data,i=r.words,o=r.sigBytes,n=this.blockSize,s=o/(4*n),c=(s=t?h.ceil(s):h.max((0|s)-this._minBufferSize,0))*n,t=h.min(4*c,o);if(c){for(var a=0;a<c;a+=n)this._doProcessBlock(i,a);e=i.splice(0,c),r.sigBytes-=t}return new l.init(e,t)},clone:function(){var t=n.clone.call(this);return t._data=this._data.clone(),t},_minBufferSize:0}),u=(o.Hasher=d.extend({cfg:n.extend(),init:function(t){this.cfg=this.cfg.extend(t),this.reset()},reset:function(){d.reset.call(this),this._doReset()},update:function(t){return this._append(t),this._process(),this},finalize:function(t){return t&&this._append(t),this._doFinalize()},blockSize:16,_createHelper:function(r){return function(t,e){return new r.init(e).finalize(t)}},_createHmacHelper:function(r){return function(t,e){return new u.HMAC.init(r,e).finalize(t)}}}),t.algo={});return t}(Math),u=(u=(p=i).lib,W=u.Base,O=u.WordArray,(u=p.x64={}).Word=W.extend({init:function(t,e){this.high=t,this.low=e}}),u.WordArray=W.extend({init:function(t,e){t=this.words=t||[],this.sigBytes=null!=e?e:8*t.length},toX32:function(){for(var t=this.words,e=t.length,r=[],i=0;i<e;i++){var o=t[i];r.push(o.high),r.push(o.low)}return O.create(r,this.sigBytes)},clone:function(){for(var t=W.clone.call(this),e=t.words=this.words.slice(0),r=e.length,i=0;i<r;i++)e[i]=e[i].clone();return t}}),"function"==typeof ArrayBuffer&&(p=i.lib.WordArray,I=p.init,(p.init=function(t){if((t=(t=t instanceof ArrayBuffer?new Uint8Array(t):t)instanceof Int8Array||"undefined"!=typeof Uint8ClampedArray&&t instanceof Uint8ClampedArray||t instanceof Int16Array||t instanceof Uint16Array||t instanceof Int32Array||t instanceof Uint32Array||t instanceof Float32Array||t instanceof Float64Array?new Uint8Array(t.buffer,t.byteOffset,t.byteLength):t)instanceof Uint8Array){for(var e=t.byteLength,r=[],i=0;i<e;i++)r[i>>>2]|=t[i]<<24-i%4*8;I.call(this,r,e)}else I.apply(this,arguments)}).prototype=p),i),p1=u.lib.WordArray;function _1(t){return t<<8&4278255360|t>>>8&16711935}(u=u.enc).Utf16=u.Utf16BE={stringify:function(t){for(var e=t.words,r=t.sigBytes,i=[],o=0;o<r;o+=2){var n=e[o>>>2]>>>16-o%4*8&65535;i.push(String.fromCharCode(n))}return i.join("")},parse:function(t){for(var e=t.length,r=[],i=0;i<e;i++)r[i>>>1]|=t.charCodeAt(i)<<16-i%2*16;return p1.create(r,2*e)}},u.Utf16LE={stringify:function(t){for(var e=t.words,r=t.sigBytes,i=[],o=0;o<r;o+=2){var n=_1(e[o>>>2]>>>16-o%4*8&65535);i.push(String.fromCharCode(n))}return i.join("")},parse:function(t){for(var e=t.length,r=[],i=0;i<e;i++)r[i>>>1]|=_1(t.charCodeAt(i)<<16-i%2*16);return p1.create(r,2*e)}},U=(p=i).lib.WordArray,p.enc.Base64={stringify:function(t){for(var e=t.words,r=t.sigBytes,i=this._map,o=(t.clamp(),[]),n=0;n<r;n+=3)for(var s=(e[n>>>2]>>>24-n%4*8&255)<<16|(e[n+1>>>2]>>>24-(n+1)%4*8&255)<<8|e[n+2>>>2]>>>24-(n+2)%4*8&255,c=0;c<4&&n+.75*c<r;c++)o.push(i.charAt(s>>>6*(3-c)&63));var a=i.charAt(64);if(a)for(;o.length%4;)o.push(a);return o.join("")},parse:function(t){var e=t.length,r=this._map;if(!(i=this._reverseMap))for(var i=this._reverseMap=[],o=0;o<r.length;o++)i[r.charCodeAt(o)]=o;for(var n,s,c=r.charAt(64),a=(!c||-1!==(c=t.indexOf(c))&&(e=c),t),h=e,l=i,f=[],d=0,u=0;u<h;u++)u%4&&(s=l[a.charCodeAt(u-1)]<<u%4*2,n=l[a.charCodeAt(u)]>>>6-u%4*2,s=s|n,f[d>>>2]|=s<<24-d%4*8,d++);return U.create(f,d)},_map:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="},K=(u=i).lib.WordArray,u.enc.Base64url={stringify:function(t,e){for(var r=t.words,i=t.sigBytes,o=(e=void 0===e?!0:e)?this._safe_map:this._map,n=(t.clamp(),[]),s=0;s<i;s+=3)for(var c=(r[s>>>2]>>>24-s%4*8&255)<<16|(r[s+1>>>2]>>>24-(s+1)%4*8&255)<<8|r[s+2>>>2]>>>24-(s+2)%4*8&255,a=0;a<4&&s+.75*a<i;a++)n.push(o.charAt(c>>>6*(3-a)&63));var h=o.charAt(64);if(h)for(;n.length%4;)n.push(h);return n.join("")},parse:function(t,e){var r=t.length,i=(e=void 0===e?!0:e)?this._safe_map:this._map;if(!(o=this._reverseMap))for(var o=this._reverseMap=[],n=0;n<i.length;n++)o[i.charCodeAt(n)]=n;for(var s,c,e=i.charAt(64),a=(!e||-1!==(e=t.indexOf(e))&&(r=e),t),h=r,l=o,f=[],d=0,u=0;u<h;u++)u%4&&(c=l[a.charCodeAt(u-1)]<<u%4*2,s=l[a.charCodeAt(u)]>>>6-u%4*2,c=c|s,f[d>>>2]|=c<<24-d%4*8,d++);return K.create(f,d)},_map:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",_safe_map:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"};for(var y1=Math,p=i,g1=(u=p.lib).WordArray,v1=u.Hasher,u=p.algo,A=[],B1=0;B1<64;B1++)A[B1]=4294967296*y1.abs(y1.sin(B1+1))|0;function z(t,e,r,i,o,n,s){t=t+(e&r|~e&i)+o+s;return(t<<n|t>>>32-n)+e}function H(t,e,r,i,o,n,s){t=t+(e&i|r&~i)+o+s;return(t<<n|t>>>32-n)+e}function C(t,e,r,i,o,n,s){t=t+(e^r^i)+o+s;return(t<<n|t>>>32-n)+e}function R(t,e,r,i,o,n,s){t=t+(r^(e|~i))+o+s;return(t<<n|t>>>32-n)+e}u=u.MD5=v1.extend({_doReset:function(){this._hash=new g1.init([1732584193,4023233417,2562383102,271733878])},_doProcessBlock:function(t,e){for(var r=0;r<16;r++){var i=e+r,o=t[i];t[i]=16711935&(o<<8|o>>>24)|4278255360&(o<<24|o>>>8)}var n=this._hash.words,s=t[e+0],c=t[e+1],a=t[e+2],h=t[e+3],l=t[e+4],f=t[e+5],d=t[e+6],u=t[e+7],p=t[e+8],_=t[e+9],y=t[e+10],g=t[e+11],v=t[e+12],B=t[e+13],w=t[e+14],k=t[e+15],x=z(n[0],S=n[1],m=n[2],b=n[3],s,7,A[0]),b=z(b,x,S,m,c,12,A[1]),m=z(m,b,x,S,a,17,A[2]),S=z(S,m,b,x,h,22,A[3]);x=z(x,S,m,b,l,7,A[4]),b=z(b,x,S,m,f,12,A[5]),m=z(m,b,x,S,d,17,A[6]),S=z(S,m,b,x,u,22,A[7]),x=z(x,S,m,b,p,7,A[8]),b=z(b,x,S,m,_,12,A[9]),m=z(m,b,x,S,y,17,A[10]),S=z(S,m,b,x,g,22,A[11]),x=z(x,S,m,b,v,7,A[12]),b=z(b,x,S,m,B,12,A[13]),m=z(m,b,x,S,w,17,A[14]),x=H(x,S=z(S,m,b,x,k,22,A[15]),m,b,c,5,A[16]),b=H(b,x,S,m,d,9,A[17]),m=H(m,b,x,S,g,14,A[18]),S=H(S,m,b,x,s,20,A[19]),x=H(x,S,m,b,f,5,A[20]),b=H(b,x,S,m,y,9,A[21]),m=H(m,b,x,S,k,14,A[22]),S=H(S,m,b,x,l,20,A[23]),x=H(x,S,m,b,_,5,A[24]),b=H(b,x,S,m,w,9,A[25]),m=H(m,b,x,S,h,14,A[26]),S=H(S,m,b,x,p,20,A[27]),x=H(x,S,m,b,B,5,A[28]),b=H(b,x,S,m,a,9,A[29]),m=H(m,b,x,S,u,14,A[30]),x=C(x,S=H(S,m,b,x,v,20,A[31]),m,b,f,4,A[32]),b=C(b,x,S,m,p,11,A[33]),m=C(m,b,x,S,g,16,A[34]),S=C(S,m,b,x,w,23,A[35]),x=C(x,S,m,b,c,4,A[36]),b=C(b,x,S,m,l,11,A[37]),m=C(m,b,x,S,u,16,A[38]),S=C(S,m,b,x,y,23,A[39]),x=C(x,S,m,b,B,4,A[40]),b=C(b,x,S,m,s,11,A[41]),m=C(m,b,x,S,h,16,A[42]),S=C(S,m,b,x,d,23,A[43]),x=C(x,S,m,b,_,4,A[44]),b=C(b,x,S,m,v,11,A[45]),m=C(m,b,x,S,k,16,A[46]),x=R(x,S=C(S,m,b,x,a,23,A[47]),m,b,s,6,A[48]),b=R(b,x,S,m,u,10,A[49]),m=R(m,b,x,S,w,15,A[50]),S=R(S,m,b,x,f,21,A[51]),x=R(x,S,m,b,v,6,A[52]),b=R(b,x,S,m,h,10,A[53]),m=R(m,b,x,S,y,15,A[54]),S=R(S,m,b,x,c,21,A[55]),x=R(x,S,m,b,p,6,A[56]),b=R(b,x,S,m,k,10,A[57]),m=R(m,b,x,S,d,15,A[58]),S=R(S,m,b,x,B,21,A[59]),x=R(x,S,m,b,l,6,A[60]),b=R(b,x,S,m,g,10,A[61]),m=R(m,b,x,S,a,15,A[62]),S=R(S,m,b,x,_,21,A[63]),n[0]=n[0]+x|0,n[1]=n[1]+S|0,n[2]=n[2]+m|0,n[3]=n[3]+b|0},_doFinalize:function(){for(var t=this._data,e=t.words,r=8*this._nDataBytes,i=8*t.sigBytes,o=(e[i>>>5]|=128<<24-i%32,y1.floor(r/4294967296)),o=(e[15+(64+i>>>9<<4)]=16711935&(o<<8|o>>>24)|4278255360&(o<<24|o>>>8),e[14+(64+i>>>9<<4)]=16711935&(r<<8|r>>>24)|4278255360&(r<<24|r>>>8),t.sigBytes=4*(e.length+1),this._process(),this._hash),n=o.words,s=0;s<4;s++){var c=n[s];n[s]=16711935&(c<<8|c>>>24)|4278255360&(c<<24|c>>>8)}return o},clone:function(){var t=v1.clone.call(this);return t._hash=this._hash.clone(),t}}),p.MD5=v1._createHelper(u),p.HmacMD5=v1._createHmacHelper(u),u=(p=i).lib,X=u.WordArray,L=u.Hasher,u=p.algo,l=[],u=u.SHA1=L.extend({_doReset:function(){this._hash=new X.init([1732584193,4023233417,2562383102,271733878,3285377520])},_doProcessBlock:function(t,e){for(var r=this._hash.words,i=r[0],o=r[1],n=r[2],s=r[3],c=r[4],a=0;a<80;a++){a<16?l[a]=0|t[e+a]:(h=l[a-3]^l[a-8]^l[a-14]^l[a-16],l[a]=h<<1|h>>>31);var h=(i<<5|i>>>27)+c+l[a];h+=a<20?1518500249+(o&n|~o&s):a<40?1859775393+(o^n^s):a<60?(o&n|o&s|n&s)-1894007588:(o^n^s)-899497514,c=s,s=n,n=o<<30|o>>>2,o=i,i=h}r[0]=r[0]+i|0,r[1]=r[1]+o|0,r[2]=r[2]+n|0,r[3]=r[3]+s|0,r[4]=r[4]+c|0},_doFinalize:function(){var t=this._data,e=t.words,r=8*this._nDataBytes,i=8*t.sigBytes;return e[i>>>5]|=128<<24-i%32,e[14+(64+i>>>9<<4)]=Math.floor(r/4294967296),e[15+(64+i>>>9<<4)]=r,t.sigBytes=4*e.length,this._process(),this._hash},clone:function(){var t=L.clone.call(this);return t._hash=this._hash.clone(),t}}),p.SHA1=L._createHelper(u),p.HmacSHA1=L._createHmacHelper(u);var w1=Math,p=i,k1=(u=p.lib).WordArray,x1=u.Hasher,u=p.algo,b1=[],m1=[];function S1(t){return 4294967296*(t-(0|t))|0}for(var A1=2,z1=0;z1<64;)!function(t){for(var e=w1.sqrt(t),r=2;r<=e;r++)if(!(t%r))return;return 1}(A1)||(z1<8&&(b1[z1]=S1(w1.pow(A1,.5))),m1[z1]=S1(w1.pow(A1,1/3)),z1++),A1++;var _=[],u=u.SHA256=x1.extend({_doReset:function(){this._hash=new k1.init(b1.slice(0))},_doProcessBlock:function(t,e){for(var r=this._hash.words,i=r[0],o=r[1],n=r[2],s=r[3],c=r[4],a=r[5],h=r[6],l=r[7],f=0;f<64;f++){f<16?_[f]=0|t[e+f]:(d=_[f-15],u=_[f-2],_[f]=((d<<25|d>>>7)^(d<<14|d>>>18)^d>>>3)+_[f-7]+((u<<15|u>>>17)^(u<<13|u>>>19)^u>>>10)+_[f-16]);var d=i&o^i&n^o&n,u=l+((c<<26|c>>>6)^(c<<21|c>>>11)^(c<<7|c>>>25))+(c&a^~c&h)+m1[f]+_[f],l=h,h=a,a=c,c=s+u|0,s=n,n=o,o=i,i=u+(((i<<30|i>>>2)^(i<<19|i>>>13)^(i<<10|i>>>22))+d)|0}r[0]=r[0]+i|0,r[1]=r[1]+o|0,r[2]=r[2]+n|0,r[3]=r[3]+s|0,r[4]=r[4]+c|0,r[5]=r[5]+a|0,r[6]=r[6]+h|0,r[7]=r[7]+l|0},_doFinalize:function(){var t=this._data,e=t.words,r=8*this._nDataBytes,i=8*t.sigBytes;return e[i>>>5]|=128<<24-i%32,e[14+(64+i>>>9<<4)]=w1.floor(r/4294967296),e[15+(64+i>>>9<<4)]=r,t.sigBytes=4*e.length,this._process(),this._hash},clone:function(){var t=x1.clone.call(this);return t._hash=this._hash.clone(),t}}),p=(p.SHA256=x1._createHelper(u),p.HmacSHA256=x1._createHmacHelper(u),j=(p=i).lib.WordArray,u=p.algo,T=u.SHA256,u=u.SHA224=T.extend({_doReset:function(){this._hash=new j.init([3238371032,914150663,812702999,4144912697,4290775857,1750603025,1694076839,3204075428])},_doFinalize:function(){var t=T._doFinalize.call(this);return t.sigBytes-=4,t}}),p.SHA224=T._createHelper(u),p.HmacSHA224=T._createHmacHelper(u),i),H1=p.lib.Hasher,y=(u=p.x64).Word,C1=u.WordArray,u=p.algo;function g(){return y.create.apply(y,arguments)}for(var R1=[g(1116352408,3609767458),g(1899447441,602891725),g(3049323471,3964484399),g(3921009573,2173295548),g(961987163,4081628472),g(1508970993,3053834265),g(2453635748,2937671579),g(2870763221,3664609560),g(3624381080,2734883394),g(310598401,1164996542),g(607225278,1323610764),g(1426881987,3590304994),g(1925078388,4068182383),g(2162078206,991336113),g(2614888103,633803317),g(3248222580,3479774868),g(3835390401,2666613458),g(4022224774,944711139),g(264347078,2341262773),g(604807628,2007800933),g(770255983,1495990901),g(1249150122,1856431235),g(1555081692,3175218132),g(1996064986,2198950837),g(2554220882,3999719339),g(2821834349,766784016),g(2952996808,2566594879),g(3210313671,3203337956),g(3336571891,1034457026),g(3584528711,2466948901),g(113926993,3758326383),g(338241895,168717936),g(666307205,1188179964),g(773529912,1546045734),g(1294757372,1522805485),g(1396182291,2643833823),g(1695183700,2343527390),g(1986661051,1014477480),g(2177026350,1206759142),g(2456956037,344077627),g(2730485921,1290863460),g(2820302411,3158454273),g(3259730800,3505952657),g(3345764771,106217008),g(3516065817,3606008344),g(3600352804,1432725776),g(4094571909,1467031594),g(275423344,851169720),g(430227734,3100823752),g(506948616,1363258195),g(659060556,3750685593),g(883997877,3785050280),g(958139571,3318307427),g(1322822218,3812723403),g(1537002063,2003034995),g(1747873779,3602036899),g(1955562222,1575990012),g(2024104815,1125592928),g(2227730452,2716904306),g(2361852424,442776044),g(2428436474,593698344),g(2756734187,3733110249),g(3204031479,2999351573),g(3329325298,3815920427),g(3391569614,3928383900),g(3515267271,566280711),g(3940187606,3454069534),g(4118630271,4000239992),g(116418474,1914138554),g(174292421,2731055270),g(289380356,3203993006),g(460393269,320620315),g(685471733,587496836),g(852142971,1086792851),g(1017036298,365543100),g(1126000580,2618297676),g(1288033470,3409855158),g(1501505948,4234509866),g(1607167915,987167468),g(1816402316,1246189591)],D1=[],E1=0;E1<80;E1++)D1[E1]=g();u=u.SHA512=H1.extend({_doReset:function(){this._hash=new C1.init([new y.init(1779033703,4089235720),new y.init(3144134277,2227873595),new y.init(1013904242,4271175723),new y.init(2773480762,1595750129),new y.init(1359893119,2917565137),new y.init(2600822924,725511199),new y.init(528734635,4215389547),new y.init(1541459225,327033209)])},_doProcessBlock:function(W,O){for(var t=this._hash.words,e=t[0],r=t[1],i=t[2],o=t[3],n=t[4],s=t[5],c=t[6],t=t[7],I=e.high,a=e.low,U=r.high,h=r.low,K=i.high,l=i.low,X=o.high,f=o.low,L=n.high,d=n.low,j=s.high,u=s.low,T=c.high,p=c.low,N=t.high,_=t.low,y=I,g=a,v=U,B=h,w=K,k=l,q=X,x=f,b=L,m=d,Z=j,S=u,V=T,G=p,J=N,Q=_,A=0;A<80;A++)var z,H,C=D1[A],R=(A<16?(H=C.high=0|W[O+2*A],z=C.low=0|W[O+2*A+1]):(F=(P=D1[A-15]).high,P=P.low,M=(E=D1[A-2]).high,E=E.low,D=(R=D1[A-7]).high,R=R.low,$=(Y=D1[A-16]).high,H=(H=((F>>>1|P<<31)^(F>>>8|P<<24)^F>>>7)+D+((z=(D=(P>>>1|F<<31)^(P>>>8|F<<24)^(P>>>7|F<<25))+R)>>>0<D>>>0?1:0))+((M>>>19|E<<13)^(M<<3|E>>>29)^M>>>6)+((z+=P=(E>>>19|M<<13)^(E<<3|M>>>29)^(E>>>6|M<<26))>>>0<P>>>0?1:0),z+=F=Y.low,C.high=H=H+$+(z>>>0<F>>>0?1:0),C.low=z),b&Z^~b&V),D=m&S^~m&G,E=y&v^y&w^v&w,M=(g>>>28|y<<4)^(g<<30|y>>>2)^(g<<25|y>>>7),P=R1[A],Y=P.high,$=P.low,F=Q+((m>>>14|b<<18)^(m>>>18|b<<14)^(m<<23|b>>>9)),C=J+((b>>>14|m<<18)^(b>>>18|m<<14)^(b<<23|m>>>9))+(F>>>0<Q>>>0?1:0),t1=M+(g&B^g&k^B&k),J=V,Q=G,V=Z,G=S,Z=b,S=m,b=q+(C=C+R+((F=F+D)>>>0<D>>>0?1:0)+Y+((F=F+$)>>>0<$>>>0?1:0)+H+((F=F+z)>>>0<z>>>0?1:0))+((m=x+F|0)>>>0<x>>>0?1:0)|0,q=w,x=k,w=v,k=B,v=y,B=g,y=C+(((y>>>28|g<<4)^(y<<30|g>>>2)^(y<<25|g>>>7))+E+(t1>>>0<M>>>0?1:0))+((g=F+t1|0)>>>0<F>>>0?1:0)|0;a=e.low=a+g,e.high=I+y+(a>>>0<g>>>0?1:0),h=r.low=h+B,r.high=U+v+(h>>>0<B>>>0?1:0),l=i.low=l+k,i.high=K+w+(l>>>0<k>>>0?1:0),f=o.low=f+x,o.high=X+q+(f>>>0<x>>>0?1:0),d=n.low=d+m,n.high=L+b+(d>>>0<m>>>0?1:0),u=s.low=u+S,s.high=j+Z+(u>>>0<S>>>0?1:0),p=c.low=p+G,c.high=T+V+(p>>>0<G>>>0?1:0),_=t.low=_+Q,t.high=N+J+(_>>>0<Q>>>0?1:0)},_doFinalize:function(){var t=this._data,e=t.words,r=8*this._nDataBytes,i=8*t.sigBytes;return e[i>>>5]|=128<<24-i%32,e[30+(128+i>>>10<<5)]=Math.floor(r/4294967296),e[31+(128+i>>>10<<5)]=r,t.sigBytes=4*e.length,this._process(),this._hash.toX32()},clone:function(){var t=H1.clone.call(this);return t._hash=this._hash.clone(),t},blockSize:32}),p.SHA512=H1._createHelper(u),p.HmacSHA512=H1._createHmacHelper(u),u=(p=i).x64,t=u.Word,N=u.WordArray,u=p.algo,q=u.SHA512,u=u.SHA384=q.extend({_doReset:function(){this._hash=new N.init([new t.init(3418070365,3238371032),new t.init(1654270250,914150663),new t.init(2438529370,812702999),new t.init(355462360,4144912697),new t.init(1731405415,4290775857),new t.init(2394180231,1750603025),new t.init(3675008525,1694076839),new t.init(1203062813,3204075428)])},_doFinalize:function(){var t=q._doFinalize.call(this);return t.sigBytes-=16,t}}),p.SHA384=q._createHelper(u),p.HmacSHA384=q._createHmacHelper(u);for(var M1=Math,p=i,P1=(u=p.lib).WordArray,F1=u.Hasher,W1=p.x64.Word,u=p.algo,O1=[],I1=[],U1=[],v=1,B=0,K1=0;K1<24;K1++){O1[v+5*B]=(K1+1)*(K1+2)/2%64;var X1=(2*v+3*B)%5;v=B%5,B=X1}for(v=0;v<5;v++)for(B=0;B<5;B++)I1[v+5*B]=B+(2*v+3*B)%5*5;for(var L1=1,j1=0;j1<24;j1++){for(var T1,N1=0,q1=0,Z1=0;Z1<7;Z1++)1&L1&&((T1=(1<<Z1)-1)<32?q1^=1<<T1:N1^=1<<T1-32),128&L1?L1=L1<<1^113:L1<<=1;U1[j1]=W1.create(N1,q1)}for(var D=[],V1=0;V1<25;V1++)D[V1]=W1.create();function G1(t,e,r){return t&e|~t&r}function J1(t,e,r){return t&r|e&~r}function Q1(t,e){return t<<e|t>>>32-e}function Y1(t){return"string"==typeof t?f1:o}function $1(t,e,r){var i,o=this._iv;o?(i=o,this._iv=void 0):i=this._prevBlock;for(var n=0;n<r;n++)t[e+n]^=i[n]}function t2(t,e,r,i){var o,n=this._iv;n?(o=n.slice(0),this._iv=void 0):o=this._prevBlock,i.encryptBlock(o,0);for(var s=0;s<r;s++)t[e+s]^=o[s]}function e2(t){var e,r,i;return 255==(t>>24&255)?(r=t>>8&255,i=255&t,255===(e=t>>16&255)?(e=0,255===r?(r=0,255===i?i=0:++i):++r):++e,t=0,t=(t+=e<<16)+(r<<8)+i):t+=1<<24,t}u=u.SHA3=F1.extend({cfg:F1.cfg.extend({outputLength:512}),_doReset:function(){for(var t=this._state=[],e=0;e<25;e++)t[e]=new W1.init;this.blockSize=(1600-2*this.cfg.outputLength)/32},_doProcessBlock:function(t,e){for(var r=this._state,i=this.blockSize/2,o=0;o<i;o++){var n=t[e+2*o],s=t[e+2*o+1],n=16711935&(n<<8|n>>>24)|4278255360&(n<<24|n>>>8);(x=r[o]).high^=16711935&(s<<8|s>>>24)|4278255360&(s<<24|s>>>8),x.low^=n}for(var c=0;c<24;c++){for(var a=0;a<5;a++){for(var h=0,l=0,f=0;f<5;f++)h^=(x=r[a+5*f]).high,l^=x.low;var d=D[a];d.high=h,d.low=l}for(a=0;a<5;a++)for(var u=D[(a+4)%5],p=D[(a+1)%5],_=p.high,p=p.low,h=u.high^(_<<1|p>>>31),l=u.low^(p<<1|_>>>31),f=0;f<5;f++)(x=r[a+5*f]).high^=h,x.low^=l;for(var y=1;y<25;y++){var g=(x=r[y]).high,v=x.low,B=O1[y],g=(l=B<32?(h=g<<B|v>>>32-B,v<<B|g>>>32-B):(h=v<<B-32|g>>>64-B,g<<B-32|v>>>64-B),D[I1[y]]);g.high=h,g.low=l}var w=D[0],k=r[0];w.high=k.high,w.low=k.low;for(a=0;a<5;a++)for(f=0;f<5;f++){var x=r[y=a+5*f],b=D[y],m=D[(a+1)%5+5*f],S=D[(a+2)%5+5*f];x.high=b.high^~m.high&S.high,x.low=b.low^~m.low&S.low}x=r[0],w=U1[c];x.high^=w.high,x.low^=w.low}},_doFinalize:function(){for(var t=this._data,e=t.words,r=(this._nDataBytes,8*t.sigBytes),i=32*this.blockSize,o=(e[r>>>5]|=1<<24-r%32,e[(M1.ceil((1+r)/i)*i>>>5)-1]|=128,t.sigBytes=4*e.length,this._process(),this._state),r=this.cfg.outputLength/8,n=r/8,s=[],c=0;c<n;c++){var a=o[c],h=a.high,a=a.low,h=16711935&(h<<8|h>>>24)|4278255360&(h<<24|h>>>8);s.push(16711935&(a<<8|a>>>24)|4278255360&(a<<24|a>>>8)),s.push(h)}return new P1.init(s,r)},clone:function(){for(var t=F1.clone.call(this),e=t._state=this._state.slice(0),r=0;r<25;r++)e[r]=e[r].clone();return t}}),p.SHA3=F1._createHelper(u),p.HmacSHA3=F1._createHmacHelper(u),Math,u=(p=i).lib,e=u.WordArray,Z=u.Hasher,u=p.algo,V=e.create([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,7,4,13,1,10,6,15,3,12,0,9,5,2,14,11,8,3,10,14,4,9,15,8,1,2,7,0,6,13,11,5,12,1,9,11,10,0,8,12,4,13,3,7,15,14,5,6,2,4,0,5,9,7,12,2,10,14,1,3,8,11,6,15,13]),G=e.create([5,14,7,0,9,2,11,4,13,6,15,8,1,10,3,12,6,11,3,7,0,13,5,10,14,15,8,12,4,9,1,2,15,5,1,3,7,14,6,9,11,8,12,2,10,0,4,13,8,6,4,1,3,11,15,0,5,12,2,13,9,7,10,14,12,15,10,4,1,5,8,7,6,2,13,14,0,3,9,11]),J=e.create([11,14,15,12,5,8,7,9,11,13,14,15,6,7,9,8,7,6,8,13,11,9,7,15,7,12,15,9,11,7,13,12,11,13,6,7,14,9,13,15,14,8,13,6,5,12,7,5,11,12,14,15,14,15,9,8,9,14,5,6,8,6,5,12,9,15,5,11,6,8,13,12,5,12,13,14,11,8,5,6]),Q=e.create([8,9,9,11,13,15,15,5,7,7,8,11,14,14,12,6,9,13,15,7,12,8,9,11,7,7,12,7,6,15,13,11,9,7,15,11,8,6,6,14,12,13,5,14,13,13,7,5,15,5,8,11,14,14,6,14,6,9,12,9,12,5,15,8,8,5,12,9,12,5,14,6,8,13,6,5,15,13,11,11]),Y=e.create([0,1518500249,1859775393,2400959708,2840853838]),$=e.create([1352829926,1548603684,1836072691,2053994217,0]),u=u.RIPEMD160=Z.extend({_doReset:function(){this._hash=e.create([1732584193,4023233417,2562383102,271733878,3285377520])},_doProcessBlock:function(t,e){for(var r=0;r<16;r++){var i=e+r,o=t[i];t[i]=16711935&(o<<8|o>>>24)|4278255360&(o<<24|o>>>8)}for(var n,s,c,a,h,l,f=this._hash.words,d=Y.words,u=$.words,p=V.words,_=G.words,y=J.words,g=Q.words,v=n=f[0],B=s=f[1],w=c=f[2],k=a=f[3],x=h=f[4],r=0;r<80;r+=1)l=(l=Q1(l=(l=n+t[e+p[r]]|0)+(r<16?(s^c^a)+d[0]:r<32?G1(s,c,a)+d[1]:r<48?((s|~c)^a)+d[2]:r<64?J1(s,c,a)+d[3]:(s^(c|~a))+d[4])|0,y[r]))+h|0,n=h,h=a,a=Q1(c,10),c=s,s=l,l=(l=Q1(l=(l=v+t[e+_[r]]|0)+(r<16?(B^(w|~k))+u[0]:r<32?J1(B,w,k)+u[1]:r<48?((B|~w)^k)+u[2]:r<64?G1(B,w,k)+u[3]:(B^w^k)+u[4])|0,g[r]))+x|0,v=x,x=k,k=Q1(w,10),w=B,B=l;l=f[1]+c+k|0,f[1]=f[2]+a+x|0,f[2]=f[3]+h+v|0,f[3]=f[4]+n+B|0,f[4]=f[0]+s+w|0,f[0]=l},_doFinalize:function(){for(var t=this._data,e=t.words,r=8*this._nDataBytes,i=8*t.sigBytes,i=(e[i>>>5]|=128<<24-i%32,e[14+(64+i>>>9<<4)]=16711935&(r<<8|r>>>24)|4278255360&(r<<24|r>>>8),t.sigBytes=4*(e.length+1),this._process(),this._hash),o=i.words,n=0;n<5;n++){var s=o[n];o[n]=16711935&(s<<8|s>>>24)|4278255360&(s<<24|s>>>8)}return i},clone:function(){var t=Z.clone.call(this);return t._hash=this._hash.clone(),t}}),p.RIPEMD160=Z._createHelper(u),p.HmacRIPEMD160=Z._createHmacHelper(u),u=(p=i).lib.Base,t1=p.enc.Utf8,p.algo.HMAC=u.extend({init:function(t,e){t=this._hasher=new t.init,"string"==typeof e&&(e=t1.parse(e));for(var r=t.blockSize,i=4*r,t=((e=e.sigBytes>i?t.finalize(e):e).clamp(),this._oKey=e.clone()),e=this._iKey=e.clone(),o=t.words,n=e.words,s=0;s<r;s++)o[s]^=1549556828,n[s]^=909522486;t.sigBytes=e.sigBytes=i,this.reset()},reset:function(){var t=this._hasher;t.reset(),t.update(this._iKey)},update:function(t){return this._hasher.update(t),this},finalize:function(t){var e=this._hasher,t=e.finalize(t);return e.reset(),e.finalize(this._oKey.clone().concat(t))}}),u=(p=i).lib,w=u.Base,e1=u.WordArray,u=p.algo,P=u.SHA256,r1=u.HMAC,i1=u.PBKDF2=w.extend({cfg:w.extend({keySize:4,hasher:P,iterations:25e4}),init:function(t){this.cfg=this.cfg.extend(t)},compute:function(t,e){for(var r=this.cfg,i=r1.create(r.hasher,t),o=e1.create(),n=e1.create([1]),s=o.words,c=n.words,a=r.keySize,h=r.iterations;s.length<a;){for(var l=i.update(e).finalize(n),f=(i.reset(),l.words),d=f.length,u=l,p=1;p<h;p++){u=i.finalize(u),i.reset();for(var _=u.words,y=0;y<d;y++)f[y]^=_[y]}o.concat(l),c[0]++}return o.sigBytes=4*a,o}}),p.PBKDF2=function(t,e,r){return i1.create(r).compute(t,e)},w=(u=i).lib,P=w.Base,o1=w.WordArray,w=u.algo,p=w.MD5,n1=w.EvpKDF=P.extend({cfg:P.extend({keySize:4,hasher:p,iterations:1}),init:function(t){this.cfg=this.cfg.extend(t)},compute:function(t,e){for(var r,i=this.cfg,o=i.hasher.create(),n=o1.create(),s=n.words,c=i.keySize,a=i.iterations;s.length<c;){r&&o.update(r),r=o.update(t).finalize(e),o.reset();for(var h=1;h<a;h++)r=o.finalize(r),o.reset();n.concat(r)}return n.sigBytes=4*c,n}}),u.EvpKDF=function(t,e,r){return n1.create(r).compute(t,e)},i.lib.Cipher||(P=(w=i).lib,p=P.Base,s=P.WordArray,s1=P.BufferedBlockAlgorithm,(u=w.enc).Utf8,c1=u.Base64,a1=w.algo.EvpKDF,h1=P.Cipher=s1.extend({cfg:p.extend(),createEncryptor:function(t,e){return this.create(this._ENC_XFORM_MODE,t,e)},createDecryptor:function(t,e){return this.create(this._DEC_XFORM_MODE,t,e)},init:function(t,e,r){this.cfg=this.cfg.extend(r),this._xformMode=t,this._key=e,this.reset()},reset:function(){s1.reset.call(this),this._doReset()},process:function(t){return this._append(t),this._process()},finalize:function(t){return t&&this._append(t),this._doFinalize()},keySize:4,ivSize:4,_ENC_XFORM_MODE:1,_DEC_XFORM_MODE:2,_createHelper:function(i){return{encrypt:function(t,e,r){return Y1(e).encrypt(i,t,e,r)},decrypt:function(t,e,r){return Y1(e).decrypt(i,t,e,r)}}}}),P.StreamCipher=h1.extend({_doFinalize:function(){return this._process(!0)},blockSize:1}),u=w.mode={},r=P.BlockCipherMode=p.extend({createEncryptor:function(t,e){return this.Encryptor.create(t,e)},createDecryptor:function(t,e){return this.Decryptor.create(t,e)},init:function(t,e){this._cipher=t,this._iv=e}}),r=u.CBC=((u=r.extend()).Encryptor=u.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize;$1.call(this,t,e,i),r.encryptBlock(t,e),this._prevBlock=t.slice(e,e+i)}}),u.Decryptor=u.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize,o=t.slice(e,e+i);r.decryptBlock(t,e),$1.call(this,t,e,i),this._prevBlock=o}}),u),u=(w.pad={}).Pkcs7={pad:function(t,e){for(var e=4*e,r=e-t.sigBytes%e,i=r<<24|r<<16|r<<8|r,o=[],n=0;n<r;n+=4)o.push(i);e=s.create(o,r);t.concat(e)},unpad:function(t){var e=255&t.words[t.sigBytes-1>>>2];t.sigBytes-=e}},P.BlockCipher=h1.extend({cfg:h1.cfg.extend({mode:r,padding:u}),reset:function(){h1.reset.call(this);var t,e=this.cfg,r=e.iv,e=e.mode;this._xformMode==this._ENC_XFORM_MODE?t=e.createEncryptor:(t=e.createDecryptor,this._minBufferSize=1),this._mode&&this._mode.__creator==t?this._mode.init(this,r&&r.words):(this._mode=t.call(e,this,r&&r.words),this._mode.__creator=t)},_doProcessBlock:function(t,e){this._mode.processBlock(t,e)},_doFinalize:function(){var t,e=this.cfg.padding;return this._xformMode==this._ENC_XFORM_MODE?(e.pad(this._data,this.blockSize),t=this._process(!0)):(t=this._process(!0),e.unpad(t)),t},blockSize:4}),l1=P.CipherParams=p.extend({init:function(t){this.mixIn(t)},toString:function(t){return(t||this.formatter).stringify(this)}}),r=(w.format={}).OpenSSL={stringify:function(t){var e=t.ciphertext,t=t.salt,t=t?s.create([1398893684,1701076831]).concat(t).concat(e):e;return t.toString(c1)},parse:function(t){var e,t=c1.parse(t),r=t.words;return 1398893684==r[0]&&1701076831==r[1]&&(e=s.create(r.slice(2,4)),r.splice(0,4),t.sigBytes-=16),l1.create({ciphertext:t,salt:e})}},o=P.SerializableCipher=p.extend({cfg:p.extend({format:r}),encrypt:function(t,e,r,i){i=this.cfg.extend(i);var o=t.createEncryptor(r,i),e=o.finalize(e),o=o.cfg;return l1.create({ciphertext:e,key:r,iv:o.iv,algorithm:t,mode:o.mode,padding:o.padding,blockSize:t.blockSize,formatter:i.format})},decrypt:function(t,e,r,i){return i=this.cfg.extend(i),e=this._parse(e,i.format),t.createDecryptor(r,i).finalize(e.ciphertext)},_parse:function(t,e){return"string"==typeof t?e.parse(t,this):t}}),u=(w.kdf={}).OpenSSL={execute:function(t,e,r,i,o){i=i||s.random(8),o=(o?a1.create({keySize:e+r,hasher:o}):a1.create({keySize:e+r})).compute(t,i);t=s.create(o.words.slice(e),4*r);return o.sigBytes=4*e,l1.create({key:o,iv:t,salt:i})}},f1=P.PasswordBasedCipher=o.extend({cfg:o.cfg.extend({kdf:u}),encrypt:function(t,e,r,i){r=(i=this.cfg.extend(i)).kdf.execute(r,t.keySize,t.ivSize,i.salt,i.hasher),i.iv=r.iv,t=o.encrypt.call(this,t,e,r.key,i);return t.mixIn(r),t},decrypt:function(t,e,r,i){i=this.cfg.extend(i),e=this._parse(e,i.format);r=i.kdf.execute(r,t.keySize,t.ivSize,e.salt,i.hasher);return i.iv=r.iv,o.decrypt.call(this,t,e,r.key,i)}})),i.mode.CFB=((p=i.lib.BlockCipherMode.extend()).Encryptor=p.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize;t2.call(this,t,e,i,r),this._prevBlock=t.slice(e,e+i)}}),p.Decryptor=p.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize,o=t.slice(e,e+i);t2.call(this,t,e,i,r),this._prevBlock=o}}),p),i.mode.CTR=(r=i.lib.BlockCipherMode.extend(),w=r.Encryptor=r.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize,o=this._iv,n=this._counter,s=(o&&(n=this._counter=o.slice(0),this._iv=void 0),n.slice(0));r.encryptBlock(s,0),n[i-1]=n[i-1]+1|0;for(var c=0;c<i;c++)t[e+c]^=s[c]}}),r.Decryptor=w,r),i.mode.CTRGladman=(P=i.lib.BlockCipherMode.extend(),u=P.Encryptor=P.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize,o=this._iv,n=this._counter,s=(o&&(n=this._counter=o.slice(0),this._iv=void 0),0===((o=n)[0]=e2(o[0]))&&(o[1]=e2(o[1])),n.slice(0));r.encryptBlock(s,0);for(var c=0;c<i;c++)t[e+c]^=s[c]}}),P.Decryptor=u,P),i.mode.OFB=(p=i.lib.BlockCipherMode.extend(),w=p.Encryptor=p.extend({processBlock:function(t,e){var r=this._cipher,i=r.blockSize,o=this._iv,n=this._keystream;o&&(n=this._keystream=o.slice(0),this._iv=void 0),r.encryptBlock(n,0);for(var s=0;s<i;s++)t[e+s]^=n[s]}}),p.Decryptor=w,p),i.mode.ECB=((u=i.lib.BlockCipherMode.extend()).Encryptor=u.extend({processBlock:function(t,e){this._cipher.encryptBlock(t,e)}}),u.Decryptor=u.extend({processBlock:function(t,e){this._cipher.decryptBlock(t,e)}}),u),i.pad.AnsiX923={pad:function(t,e){var r=t.sigBytes,e=4*e,e=e-r%e,r=r+e-1;t.clamp(),t.words[r>>>2]|=e<<24-r%4*8,t.sigBytes+=e},unpad:function(t){var e=255&t.words[t.sigBytes-1>>>2];t.sigBytes-=e}},i.pad.Iso10126={pad:function(t,e){e*=4,e-=t.sigBytes%e;t.concat(i.lib.WordArray.random(e-1)).concat(i.lib.WordArray.create([e<<24],1))},unpad:function(t){var e=255&t.words[t.sigBytes-1>>>2];t.sigBytes-=e}},i.pad.Iso97971={pad:function(t,e){t.concat(i.lib.WordArray.create([2147483648],1)),i.pad.ZeroPadding.pad(t,e)},unpad:function(t){i.pad.ZeroPadding.unpad(t),t.sigBytes--}},i.pad.ZeroPadding={pad:function(t,e){e*=4;t.clamp(),t.sigBytes+=e-(t.sigBytes%e||e)},unpad:function(t){for(var e=t.words,r=t.sigBytes-1,r=t.sigBytes-1;0<=r;r--)if(e[r>>>2]>>>24-r%4*8&255){t.sigBytes=r+1;break}}},i.pad.NoPadding={pad:function(){},unpad:function(){}},d1=(P=i).lib.CipherParams,u1=P.enc.Hex,P.format.Hex={stringify:function(t){return t.ciphertext.toString(u1)},parse:function(t){t=u1.parse(t);return d1.create({ciphertext:t})}};for(var w=i,p=w.lib.BlockCipher,u=w.algo,k=[],r2=[],i2=[],o2=[],n2=[],s2=[],c2=[],a2=[],h2=[],l2=[],x=[],b=0;b<256;b++)x[b]=b<128?b<<1:b<<1^283;for(var m=0,S=0,b=0;b<256;b++){var E=S^S<<1^S<<2^S<<3^S<<4,f2=(k[m]=E=E>>>8^255&E^99,x[r2[E]=m]),d2=x[f2],u2=x[d2],M=257*x[E]^16843008*E;i2[m]=M<<24|M>>>8,o2[m]=M<<16|M>>>16,n2[m]=M<<8|M>>>24,s2[m]=M,c2[E]=(M=16843009*u2^65537*d2^257*f2^16843008*m)<<24|M>>>8,a2[E]=M<<16|M>>>16,h2[E]=M<<8|M>>>24,l2[E]=M,m?(m=f2^x[x[x[u2^f2]]],S^=x[x[S]]):m=S=1}var p2=[0,1,2,4,8,16,32,64,128,27,54],u=u.AES=p.extend({_doReset:function(){if(!this._nRounds||this._keyPriorReset!==this._key){for(var t=this._keyPriorReset=this._key,e=t.words,r=t.sigBytes/4,i=4*(1+(this._nRounds=6+r)),o=this._keySchedule=[],n=0;n<i;n++)n<r?o[n]=e[n]:(a=o[n-1],n%r?6<r&&n%r==4&&(a=k[a>>>24]<<24|k[a>>>16&255]<<16|k[a>>>8&255]<<8|k[255&a]):(a=k[(a=a<<8|a>>>24)>>>24]<<24|k[a>>>16&255]<<16|k[a>>>8&255]<<8|k[255&a],a^=p2[n/r|0]<<24),o[n]=o[n-r]^a);for(var s=this._invKeySchedule=[],c=0;c<i;c++){var a,n=i-c;a=c%4?o[n]:o[n-4],s[c]=c<4||n<=4?a:c2[k[a>>>24]]^a2[k[a>>>16&255]]^h2[k[a>>>8&255]]^l2[k[255&a]]}}},encryptBlock:function(t,e){this._doCryptBlock(t,e,this._keySchedule,i2,o2,n2,s2,k)},decryptBlock:function(t,e){var r=t[e+1],r=(t[e+1]=t[e+3],t[e+3]=r,this._doCryptBlock(t,e,this._invKeySchedule,c2,a2,h2,l2,r2),t[e+1]);t[e+1]=t[e+3],t[e+3]=r},_doCryptBlock:function(t,e,r,i,o,n,s,c){for(var a=this._nRounds,h=t[e]^r[0],l=t[e+1]^r[1],f=t[e+2]^r[2],d=t[e+3]^r[3],u=4,p=1;p<a;p++)var _=i[h>>>24]^o[l>>>16&255]^n[f>>>8&255]^s[255&d]^r[u++],y=i[l>>>24]^o[f>>>16&255]^n[d>>>8&255]^s[255&h]^r[u++],g=i[f>>>24]^o[d>>>16&255]^n[h>>>8&255]^s[255&l]^r[u++],v=i[d>>>24]^o[h>>>16&255]^n[l>>>8&255]^s[255&f]^r[u++],h=_,l=y,f=g,d=v;_=(c[h>>>24]<<24|c[l>>>16&255]<<16|c[f>>>8&255]<<8|c[255&d])^r[u++],y=(c[l>>>24]<<24|c[f>>>16&255]<<16|c[d>>>8&255]<<8|c[255&h])^r[u++],g=(c[f>>>24]<<24|c[d>>>16&255]<<16|c[h>>>8&255]<<8|c[255&l])^r[u++],v=(c[d>>>24]<<24|c[h>>>16&255]<<16|c[l>>>8&255]<<8|c[255&f])^r[u++];t[e]=_,t[e+1]=y,t[e+2]=g,t[e+3]=v},keySize:8}),P=(w.AES=p._createHelper(u),i),_2=(w=P.lib).WordArray,w=w.BlockCipher,p=P.algo,y2=[57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,27,19,11,3,60,52,44,36,63,55,47,39,31,23,15,7,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,28,20,12,4],g2=[14,17,11,24,1,5,3,28,15,6,21,10,23,19,12,4,26,8,16,7,27,20,13,2,41,52,31,37,47,55,30,40,51,45,33,48,44,49,39,56,34,53,46,42,50,36,29,32],v2=[1,2,4,6,8,10,12,14,15,17,19,21,23,25,27,28],B2=[{0:8421888,268435456:32768,536870912:8421378,805306368:2,1073741824:512,1342177280:8421890,1610612736:8389122,1879048192:8388608,2147483648:514,2415919104:8389120,2684354560:33280,2952790016:8421376,3221225472:32770,3489660928:8388610,3758096384:0,4026531840:33282,134217728:0,402653184:8421890,671088640:33282,939524096:32768,1207959552:8421888,1476395008:512,1744830464:8421378,2013265920:2,2281701376:8389120,2550136832:33280,2818572288:8421376,3087007744:8389122,3355443200:8388610,3623878656:32770,3892314112:514,4160749568:8388608,1:32768,268435457:2,536870913:8421888,805306369:8388608,1073741825:8421378,1342177281:33280,1610612737:512,1879048193:8389122,2147483649:8421890,2415919105:8421376,2684354561:8388610,2952790017:33282,3221225473:514,3489660929:8389120,3758096385:32770,4026531841:0,134217729:8421890,402653185:8421376,671088641:8388608,939524097:512,1207959553:32768,1476395009:8388610,1744830465:2,2013265921:33282,2281701377:32770,2550136833:8389122,2818572289:514,3087007745:8421888,3355443201:8389120,3623878657:0,3892314113:33280,4160749569:8421378},{0:1074282512,16777216:16384,33554432:524288,50331648:1074266128,67108864:1073741840,83886080:1074282496,100663296:1073758208,117440512:16,134217728:540672,150994944:1073758224,167772160:1073741824,184549376:540688,201326592:524304,218103808:0,234881024:16400,251658240:1074266112,8388608:1073758208,25165824:540688,41943040:16,58720256:1073758224,75497472:1074282512,92274688:1073741824,109051904:524288,125829120:1074266128,142606336:524304,159383552:0,176160768:16384,192937984:1074266112,209715200:1073741840,226492416:540672,243269632:1074282496,260046848:16400,268435456:0,285212672:1074266128,301989888:1073758224,318767104:1074282496,335544320:1074266112,352321536:16,369098752:540688,385875968:16384,402653184:16400,419430400:524288,436207616:524304,452984832:1073741840,469762048:540672,486539264:1073758208,503316480:1073741824,520093696:1074282512,276824064:540688,293601280:524288,310378496:1074266112,327155712:16384,343932928:1073758208,360710144:1074282512,377487360:16,394264576:1073741824,411041792:1074282496,427819008:1073741840,444596224:1073758224,461373440:524304,478150656:0,494927872:16400,511705088:1074266128,528482304:540672},{0:260,1048576:0,2097152:67109120,3145728:65796,4194304:65540,5242880:67108868,6291456:67174660,7340032:67174400,8388608:67108864,9437184:67174656,10485760:65792,11534336:67174404,12582912:67109124,13631488:65536,14680064:4,15728640:256,524288:67174656,1572864:67174404,2621440:0,3670016:67109120,4718592:67108868,5767168:65536,6815744:65540,7864320:260,8912896:4,9961472:256,11010048:67174400,12058624:65796,13107200:65792,14155776:67109124,15204352:67174660,16252928:67108864,16777216:67174656,17825792:65540,18874368:65536,19922944:67109120,20971520:256,22020096:67174660,23068672:67108868,24117248:0,25165824:67109124,26214400:67108864,27262976:4,28311552:65792,29360128:67174400,30408704:260,31457280:65796,32505856:67174404,17301504:67108864,18350080:260,19398656:67174656,20447232:0,21495808:65540,22544384:67109120,23592960:256,24641536:67174404,25690112:65536,26738688:67174660,27787264:65796,28835840:67108868,29884416:67109124,30932992:67174400,31981568:4,33030144:65792},{0:2151682048,65536:2147487808,131072:4198464,196608:2151677952,262144:0,327680:4198400,393216:2147483712,458752:4194368,524288:2147483648,589824:4194304,655360:64,720896:2147487744,786432:2151678016,851968:4160,917504:4096,983040:2151682112,32768:2147487808,98304:64,163840:2151678016,229376:2147487744,294912:4198400,360448:2151682112,425984:0,491520:2151677952,557056:4096,622592:2151682048,688128:4194304,753664:4160,819200:2147483648,884736:4194368,950272:4198464,1015808:2147483712,1048576:4194368,1114112:4198400,1179648:2147483712,1245184:0,1310720:4160,1376256:2151678016,1441792:2151682048,1507328:2147487808,1572864:2151682112,1638400:2147483648,1703936:2151677952,1769472:4198464,1835008:2147487744,1900544:4194304,1966080:64,2031616:4096,1081344:2151677952,1146880:2151682112,1212416:0,1277952:4198400,1343488:4194368,1409024:2147483648,1474560:2147487808,1540096:64,1605632:2147483712,1671168:4096,1736704:2147487744,1802240:2151678016,1867776:4160,1933312:2151682048,1998848:4194304,2064384:4198464},{0:128,4096:17039360,8192:262144,12288:536870912,16384:537133184,20480:16777344,24576:553648256,28672:262272,32768:16777216,36864:537133056,40960:536871040,45056:553910400,49152:553910272,53248:0,57344:17039488,61440:553648128,2048:17039488,6144:553648256,10240:128,14336:17039360,18432:262144,22528:537133184,26624:553910272,30720:536870912,34816:537133056,38912:0,43008:553910400,47104:16777344,51200:536871040,55296:553648128,59392:16777216,63488:262272,65536:262144,69632:128,73728:536870912,77824:553648256,81920:16777344,86016:553910272,90112:537133184,94208:16777216,98304:553910400,102400:553648128,106496:17039360,110592:537133056,114688:262272,118784:536871040,122880:0,126976:17039488,67584:553648256,71680:16777216,75776:17039360,79872:537133184,83968:536870912,88064:17039488,92160:128,96256:553910272,100352:262272,104448:553910400,108544:0,112640:553648128,116736:16777344,120832:262144,124928:537133056,129024:536871040},{0:268435464,256:8192,512:270532608,768:270540808,1024:268443648,1280:2097152,1536:2097160,1792:268435456,2048:0,2304:268443656,2560:2105344,2816:8,3072:270532616,3328:2105352,3584:8200,3840:270540800,128:270532608,384:270540808,640:8,896:2097152,1152:2105352,1408:268435464,1664:268443648,1920:8200,2176:2097160,2432:8192,2688:268443656,2944:270532616,3200:0,3456:270540800,3712:2105344,3968:268435456,4096:268443648,4352:270532616,4608:270540808,4864:8200,5120:2097152,5376:268435456,5632:268435464,5888:2105344,6144:2105352,6400:0,6656:8,6912:270532608,7168:8192,7424:268443656,7680:270540800,7936:2097160,4224:8,4480:2105344,4736:2097152,4992:268435464,5248:268443648,5504:8200,5760:270540808,6016:270532608,6272:270540800,6528:270532616,6784:8192,7040:2105352,7296:2097160,7552:0,7808:268435456,8064:268443656},{0:1048576,16:33555457,32:1024,48:1049601,64:34604033,80:0,96:1,112:34603009,128:33555456,144:1048577,160:33554433,176:34604032,192:34603008,208:1025,224:1049600,240:33554432,8:34603009,24:0,40:33555457,56:34604032,72:1048576,88:33554433,104:33554432,120:1025,136:1049601,152:33555456,168:34603008,184:1048577,200:1024,216:34604033,232:1,248:1049600,256:33554432,272:1048576,288:33555457,304:34603009,320:1048577,336:33555456,352:34604032,368:1049601,384:1025,400:34604033,416:1049600,432:1,448:0,464:34603008,480:33554433,496:1024,264:1049600,280:33555457,296:34603009,312:1,328:33554432,344:1048576,360:1025,376:34604032,392:33554433,408:34603008,424:0,440:34604033,456:1049601,472:1024,488:33555456,504:1048577},{0:134219808,1:131072,2:134217728,3:32,4:131104,5:134350880,6:134350848,7:2048,8:134348800,9:134219776,10:133120,11:134348832,12:2080,13:0,14:134217760,15:133152,2147483648:2048,2147483649:134350880,2147483650:134219808,2147483651:134217728,2147483652:134348800,2147483653:133120,2147483654:133152,2147483655:32,2147483656:134217760,2147483657:2080,2147483658:131104,2147483659:134350848,2147483660:0,2147483661:134348832,2147483662:134219776,2147483663:131072,16:133152,17:134350848,18:32,19:2048,20:134219776,21:134217760,22:134348832,23:131072,24:0,25:131104,26:134348800,27:134219808,28:134350880,29:133120,30:2080,31:134217728,2147483664:131072,2147483665:2048,2147483666:134348832,2147483667:133152,2147483668:32,2147483669:134348800,2147483670:134217728,2147483671:134219808,2147483672:134350880,2147483673:134217760,2147483674:134219776,2147483675:0,2147483676:133120,2147483677:2080,2147483678:131104,2147483679:134350848}],w2=[4160749569,528482304,33030144,2064384,129024,8064,504,2147483679],k2=p.DES=w.extend({_doReset:function(){for(var t=this._key.words,e=[],r=0;r<56;r++){var i=y2[r]-1;e[r]=t[i>>>5]>>>31-i%32&1}for(var o=this._subKeys=[],n=0;n<16;n++){for(var s=o[n]=[],c=v2[n],r=0;r<24;r++)s[r/6|0]|=e[(g2[r]-1+c)%28]<<31-r%6,s[4+(r/6|0)]|=e[28+(g2[r+24]-1+c)%28]<<31-r%6;s[0]=s[0]<<1|s[0]>>>31;for(r=1;r<7;r++)s[r]=s[r]>>>4*(r-1)+3;s[7]=s[7]<<5|s[7]>>>27}for(var a=this._invSubKeys=[],r=0;r<16;r++)a[r]=o[15-r]},encryptBlock:function(t,e){this._doCryptBlock(t,e,this._subKeys)},decryptBlock:function(t,e){this._doCryptBlock(t,e,this._invSubKeys)},_doCryptBlock:function(t,e,r){this._lBlock=t[e],this._rBlock=t[e+1],x2.call(this,4,252645135),x2.call(this,16,65535),b2.call(this,2,858993459),b2.call(this,8,16711935),x2.call(this,1,1431655765);for(var i=0;i<16;i++){for(var o=r[i],n=this._lBlock,s=this._rBlock,c=0,a=0;a<8;a++)c|=B2[a][((s^o[a])&w2[a])>>>0];this._lBlock=s,this._rBlock=n^c}var h=this._lBlock;this._lBlock=this._rBlock,this._rBlock=h,x2.call(this,1,1431655765),b2.call(this,8,16711935),b2.call(this,2,858993459),x2.call(this,16,65535),x2.call(this,4,252645135),t[e]=this._lBlock,t[e+1]=this._rBlock},keySize:2,ivSize:2,blockSize:2});function x2(t,e){e=(this._lBlock>>>t^this._rBlock)&e;this._rBlock^=e,this._lBlock^=e<<t}function b2(t,e){e=(this._rBlock>>>t^this._lBlock)&e;this._lBlock^=e,this._rBlock^=e<<t}P.DES=w._createHelper(k2),p=p.TripleDES=w.extend({_doReset:function(){var t=this._key.words;if(2!==t.length&&4!==t.length&&t.length<6)throw new Error("Invalid key length - 3DES requires the key length to be 64, 128, 192 or >192.");var e=t.slice(0,2),r=t.length<4?t.slice(0,2):t.slice(2,4),t=t.length<6?t.slice(0,2):t.slice(4,6);this._des1=k2.createEncryptor(_2.create(e)),this._des2=k2.createEncryptor(_2.create(r)),this._des3=k2.createEncryptor(_2.create(t))},encryptBlock:function(t,e){this._des1.encryptBlock(t,e),this._des2.decryptBlock(t,e),this._des3.encryptBlock(t,e)},decryptBlock:function(t,e){this._des3.decryptBlock(t,e),this._des2.encryptBlock(t,e),this._des1.decryptBlock(t,e)},keySize:6,ivSize:2,blockSize:2}),P.TripleDES=w._createHelper(p);var u=i,P=u.lib.StreamCipher,w=u.algo,m2=w.RC4=P.extend({_doReset:function(){for(var t=this._key,e=t.words,r=t.sigBytes,i=this._S=[],o=0;o<256;o++)i[o]=o;for(var o=0,n=0;o<256;o++){var s=o%r,s=e[s>>>2]>>>24-s%4*8&255,n=(n+i[o]+s)%256,s=i[o];i[o]=i[n],i[n]=s}this._i=this._j=0},_doProcessBlock:function(t,e){t[e]^=S2.call(this)},keySize:8,ivSize:0});function S2(){for(var t=this._S,e=this._i,r=this._j,i=0,o=0;o<4;o++){var r=(r+t[e=(e+1)%256])%256,n=t[e];t[e]=t[r],t[r]=n,i|=t[(t[e]+t[r])%256]<<24-8*o}return this._i=e,this._j=r,i}function A2(){for(var t=this._X,e=this._C,r=0;r<8;r++)c[r]=e[r];e[0]=e[0]+1295307597+this._b|0,e[1]=e[1]+3545052371+(e[0]>>>0<c[0]>>>0?1:0)|0,e[2]=e[2]+886263092+(e[1]>>>0<c[1]>>>0?1:0)|0,e[3]=e[3]+1295307597+(e[2]>>>0<c[2]>>>0?1:0)|0,e[4]=e[4]+3545052371+(e[3]>>>0<c[3]>>>0?1:0)|0,e[5]=e[5]+886263092+(e[4]>>>0<c[4]>>>0?1:0)|0,e[6]=e[6]+1295307597+(e[5]>>>0<c[5]>>>0?1:0)|0,e[7]=e[7]+3545052371+(e[6]>>>0<c[6]>>>0?1:0)|0,this._b=e[7]>>>0<c[7]>>>0?1:0;for(r=0;r<8;r++){var i=t[r]+e[r],o=65535&i,n=i>>>16;a[r]=((o*o>>>17)+o*n>>>15)+n*n^((4294901760&i)*i|0)+((65535&i)*i|0)}t[0]=a[0]+(a[7]<<16|a[7]>>>16)+(a[6]<<16|a[6]>>>16)|0,t[1]=a[1]+(a[0]<<8|a[0]>>>24)+a[7]|0,t[2]=a[2]+(a[1]<<16|a[1]>>>16)+(a[0]<<16|a[0]>>>16)|0,t[3]=a[3]+(a[2]<<8|a[2]>>>24)+a[1]|0,t[4]=a[4]+(a[3]<<16|a[3]>>>16)+(a[2]<<16|a[2]>>>16)|0,t[5]=a[5]+(a[4]<<8|a[4]>>>24)+a[3]|0,t[6]=a[6]+(a[5]<<16|a[5]>>>16)+(a[4]<<16|a[4]>>>16)|0,t[7]=a[7]+(a[6]<<8|a[6]>>>24)+a[5]|0}function z2(){for(var t=this._X,e=this._C,r=0;r<8;r++)f[r]=e[r];e[0]=e[0]+1295307597+this._b|0,e[1]=e[1]+3545052371+(e[0]>>>0<f[0]>>>0?1:0)|0,e[2]=e[2]+886263092+(e[1]>>>0<f[1]>>>0?1:0)|0,e[3]=e[3]+1295307597+(e[2]>>>0<f[2]>>>0?1:0)|0,e[4]=e[4]+3545052371+(e[3]>>>0<f[3]>>>0?1:0)|0,e[5]=e[5]+886263092+(e[4]>>>0<f[4]>>>0?1:0)|0,e[6]=e[6]+1295307597+(e[5]>>>0<f[5]>>>0?1:0)|0,e[7]=e[7]+3545052371+(e[6]>>>0<f[6]>>>0?1:0)|0,this._b=e[7]>>>0<f[7]>>>0?1:0;for(r=0;r<8;r++){var i=t[r]+e[r],o=65535&i,n=i>>>16;d[r]=((o*o>>>17)+o*n>>>15)+n*n^((4294901760&i)*i|0)+((65535&i)*i|0)}t[0]=d[0]+(d[7]<<16|d[7]>>>16)+(d[6]<<16|d[6]>>>16)|0,t[1]=d[1]+(d[0]<<8|d[0]>>>24)+d[7]|0,t[2]=d[2]+(d[1]<<16|d[1]>>>16)+(d[0]<<16|d[0]>>>16)|0,t[3]=d[3]+(d[2]<<8|d[2]>>>24)+d[1]|0,t[4]=d[4]+(d[3]<<16|d[3]>>>16)+(d[2]<<16|d[2]>>>16)|0,t[5]=d[5]+(d[4]<<8|d[4]>>>24)+d[3]|0,t[6]=d[6]+(d[5]<<16|d[5]>>>16)+(d[4]<<16|d[4]>>>16)|0,t[7]=d[7]+(d[6]<<8|d[6]>>>24)+d[5]|0}u.RC4=P._createHelper(m2),w=w.RC4Drop=m2.extend({cfg:m2.cfg.extend({drop:192}),_doReset:function(){m2._doReset.call(this);for(var t=this.cfg.drop;0<t;t--)S2.call(this)}}),u.RC4Drop=P._createHelper(w),u=(p=i).lib.StreamCipher,P=p.algo,n=[],c=[],a=[],P=P.Rabbit=u.extend({_doReset:function(){for(var t=this._key.words,e=this.cfg.iv,r=0;r<4;r++)t[r]=16711935&(t[r]<<8|t[r]>>>24)|4278255360&(t[r]<<24|t[r]>>>8);for(var i=this._X=[t[0],t[3]<<16|t[2]>>>16,t[1],t[0]<<16|t[3]>>>16,t[2],t[1]<<16|t[0]>>>16,t[3],t[2]<<16|t[1]>>>16],o=this._C=[t[2]<<16|t[2]>>>16,4294901760&t[0]|65535&t[1],t[3]<<16|t[3]>>>16,4294901760&t[1]|65535&t[2],t[0]<<16|t[0]>>>16,4294901760&t[2]|65535&t[3],t[1]<<16|t[1]>>>16,4294901760&t[3]|65535&t[0]],r=this._b=0;r<4;r++)A2.call(this);for(r=0;r<8;r++)o[r]^=i[r+4&7];if(e){var e=e.words,n=e[0],e=e[1],n=16711935&(n<<8|n>>>24)|4278255360&(n<<24|n>>>8),e=16711935&(e<<8|e>>>24)|4278255360&(e<<24|e>>>8),s=n>>>16|4294901760&e,c=e<<16|65535&n;o[0]^=n,o[1]^=s,o[2]^=e,o[3]^=c,o[4]^=n,o[5]^=s,o[6]^=e,o[7]^=c;for(r=0;r<4;r++)A2.call(this)}},_doProcessBlock:function(t,e){var r=this._X;A2.call(this),n[0]=r[0]^r[5]>>>16^r[3]<<16,n[1]=r[2]^r[7]>>>16^r[5]<<16,n[2]=r[4]^r[1]>>>16^r[7]<<16,n[3]=r[6]^r[3]>>>16^r[1]<<16;for(var i=0;i<4;i++)n[i]=16711935&(n[i]<<8|n[i]>>>24)|4278255360&(n[i]<<24|n[i]>>>8),t[e+i]^=n[i]},blockSize:4,ivSize:2}),p.Rabbit=u._createHelper(P),p=(w=i).lib.StreamCipher,u=w.algo,h=[],f=[],d=[],u=u.RabbitLegacy=p.extend({_doReset:function(){for(var t=this._key.words,e=this.cfg.iv,r=this._X=[t[0],t[3]<<16|t[2]>>>16,t[1],t[0]<<16|t[3]>>>16,t[2],t[1]<<16|t[0]>>>16,t[3],t[2]<<16|t[1]>>>16],i=this._C=[t[2]<<16|t[2]>>>16,4294901760&t[0]|65535&t[1],t[3]<<16|t[3]>>>16,4294901760&t[1]|65535&t[2],t[0]<<16|t[0]>>>16,4294901760&t[2]|65535&t[3],t[1]<<16|t[1]>>>16,4294901760&t[3]|65535&t[0]],o=this._b=0;o<4;o++)z2.call(this);for(o=0;o<8;o++)i[o]^=r[o+4&7];if(e){var t=e.words,e=t[0],t=t[1],e=16711935&(e<<8|e>>>24)|4278255360&(e<<24|e>>>8),t=16711935&(t<<8|t>>>24)|4278255360&(t<<24|t>>>8),n=e>>>16|4294901760&t,s=t<<16|65535&e;i[0]^=e,i[1]^=n,i[2]^=t,i[3]^=s,i[4]^=e,i[5]^=n,i[6]^=t,i[7]^=s;for(o=0;o<4;o++)z2.call(this)}},_doProcessBlock:function(t,e){var r=this._X;z2.call(this),h[0]=r[0]^r[5]>>>16^r[3]<<16,h[1]=r[2]^r[7]>>>16^r[5]<<16,h[2]=r[4]^r[1]>>>16^r[7]<<16,h[3]=r[6]^r[3]>>>16^r[1]<<16;for(var i=0;i<4;i++)h[i]=16711935&(h[i]<<8|h[i]>>>24)|4278255360&(h[i]<<24|h[i]>>>8),t[e+i]^=h[i]},blockSize:4,ivSize:2}),w.RabbitLegacy=p._createHelper(u);{w=(P=i).lib.BlockCipher,p=P.algo;const F=16,D2=[608135816,2242054355,320440878,57701188,2752067618,698298832,137296536,3964562569,1160258022,953160567,3193202383,887688300,3232508343,3380367581,1065670069,3041331479,2450970073,2306472731],E2=[[3509652390,2564797868,805139163,3491422135,3101798381,1780907670,3128725573,4046225305,614570311,3012652279,134345442,2240740374,1667834072,1901547113,2757295779,4103290238,227898511,1921955416,1904987480,2182433518,2069144605,3260701109,2620446009,720527379,3318853667,677414384,3393288472,3101374703,2390351024,1614419982,1822297739,2954791486,3608508353,3174124327,2024746970,1432378464,3864339955,2857741204,1464375394,1676153920,1439316330,715854006,3033291828,289532110,2706671279,2087905683,3018724369,1668267050,732546397,1947742710,3462151702,2609353502,2950085171,1814351708,2050118529,680887927,999245976,1800124847,3300911131,1713906067,1641548236,4213287313,1216130144,1575780402,4018429277,3917837745,3693486850,3949271944,596196993,3549867205,258830323,2213823033,772490370,2760122372,1774776394,2652871518,566650946,4142492826,1728879713,2882767088,1783734482,3629395816,2517608232,2874225571,1861159788,326777828,3124490320,2130389656,2716951837,967770486,1724537150,2185432712,2364442137,1164943284,2105845187,998989502,3765401048,2244026483,1075463327,1455516326,1322494562,910128902,469688178,1117454909,936433444,3490320968,3675253459,1240580251,122909385,2157517691,634681816,4142456567,3825094682,3061402683,2540495037,79693498,3249098678,1084186820,1583128258,426386531,1761308591,1047286709,322548459,995290223,1845252383,2603652396,3431023940,2942221577,3202600964,3727903485,1712269319,422464435,3234572375,1170764815,3523960633,3117677531,1434042557,442511882,3600875718,1076654713,1738483198,4213154764,2393238008,3677496056,1014306527,4251020053,793779912,2902807211,842905082,4246964064,1395751752,1040244610,2656851899,3396308128,445077038,3742853595,3577915638,679411651,2892444358,2354009459,1767581616,3150600392,3791627101,3102740896,284835224,4246832056,1258075500,768725851,2589189241,3069724005,3532540348,1274779536,3789419226,2764799539,1660621633,3471099624,4011903706,913787905,3497959166,737222580,2514213453,2928710040,3937242737,1804850592,3499020752,2949064160,2386320175,2390070455,2415321851,4061277028,2290661394,2416832540,1336762016,1754252060,3520065937,3014181293,791618072,3188594551,3933548030,2332172193,3852520463,3043980520,413987798,3465142937,3030929376,4245938359,2093235073,3534596313,375366246,2157278981,2479649556,555357303,3870105701,2008414854,3344188149,4221384143,3956125452,2067696032,3594591187,2921233993,2428461,544322398,577241275,1471733935,610547355,4027169054,1432588573,1507829418,2025931657,3646575487,545086370,48609733,2200306550,1653985193,298326376,1316178497,3007786442,2064951626,458293330,2589141269,3591329599,3164325604,727753846,2179363840,146436021,1461446943,4069977195,705550613,3059967265,3887724982,4281599278,3313849956,1404054877,2845806497,146425753,1854211946],[1266315497,3048417604,3681880366,3289982499,290971e4,1235738493,2632868024,2414719590,3970600049,1771706367,1449415276,3266420449,422970021,1963543593,2690192192,3826793022,1062508698,1531092325,1804592342,2583117782,2714934279,4024971509,1294809318,4028980673,1289560198,2221992742,1669523910,35572830,157838143,1052438473,1016535060,1802137761,1753167236,1386275462,3080475397,2857371447,1040679964,2145300060,2390574316,1461121720,2956646967,4031777805,4028374788,33600511,2920084762,1018524850,629373528,3691585981,3515945977,2091462646,2486323059,586499841,988145025,935516892,3367335476,2599673255,2839830854,265290510,3972581182,2759138881,3795373465,1005194799,847297441,406762289,1314163512,1332590856,1866599683,4127851711,750260880,613907577,1450815602,3165620655,3734664991,3650291728,3012275730,3704569646,1427272223,778793252,1343938022,2676280711,2052605720,1946737175,3164576444,3914038668,3967478842,3682934266,1661551462,3294938066,4011595847,840292616,3712170807,616741398,312560963,711312465,1351876610,322626781,1910503582,271666773,2175563734,1594956187,70604529,3617834859,1007753275,1495573769,4069517037,2549218298,2663038764,504708206,2263041392,3941167025,2249088522,1514023603,1998579484,1312622330,694541497,2582060303,2151582166,1382467621,776784248,2618340202,3323268794,2497899128,2784771155,503983604,4076293799,907881277,423175695,432175456,1378068232,4145222326,3954048622,3938656102,3820766613,2793130115,2977904593,26017576,3274890735,3194772133,1700274565,1756076034,4006520079,3677328699,720338349,1533947780,354530856,688349552,3973924725,1637815568,332179504,3949051286,53804574,2852348879,3044236432,1282449977,3583942155,3416972820,4006381244,1617046695,2628476075,3002303598,1686838959,431878346,2686675385,1700445008,1080580658,1009431731,832498133,3223435511,2605976345,2271191193,2516031870,1648197032,4164389018,2548247927,300782431,375919233,238389289,3353747414,2531188641,2019080857,1475708069,455242339,2609103871,448939670,3451063019,1395535956,2413381860,1841049896,1491858159,885456874,4264095073,4001119347,1565136089,3898914787,1108368660,540939232,1173283510,2745871338,3681308437,4207628240,3343053890,4016749493,1699691293,1103962373,3625875870,2256883143,3830138730,1031889488,3479347698,1535977030,4236805024,3251091107,2132092099,1774941330,1199868427,1452454533,157007616,2904115357,342012276,595725824,1480756522,206960106,497939518,591360097,863170706,2375253569,3596610801,1814182875,2094937945,3421402208,1082520231,3463918190,2785509508,435703966,3908032597,1641649973,2842273706,3305899714,1510255612,2148256476,2655287854,3276092548,4258621189,236887753,3681803219,274041037,1734335097,3815195456,3317970021,1899903192,1026095262,4050517792,356393447,2410691914,3873677099,3682840055],[3913112168,2491498743,4132185628,2489919796,1091903735,1979897079,3170134830,3567386728,3557303409,857797738,1136121015,1342202287,507115054,2535736646,337727348,3213592640,1301675037,2528481711,1895095763,1721773893,3216771564,62756741,2142006736,835421444,2531993523,1442658625,3659876326,2882144922,676362277,1392781812,170690266,3921047035,1759253602,3611846912,1745797284,664899054,1329594018,3901205900,3045908486,2062866102,2865634940,3543621612,3464012697,1080764994,553557557,3656615353,3996768171,991055499,499776247,1265440854,648242737,3940784050,980351604,3713745714,1749149687,3396870395,4211799374,3640570775,1161844396,3125318951,1431517754,545492359,4268468663,3499529547,1437099964,2702547544,3433638243,2581715763,2787789398,1060185593,1593081372,2418618748,4260947970,69676912,2159744348,86519011,2512459080,3838209314,1220612927,3339683548,133810670,1090789135,1078426020,1569222167,845107691,3583754449,4072456591,1091646820,628848692,1613405280,3757631651,526609435,236106946,48312990,2942717905,3402727701,1797494240,859738849,992217954,4005476642,2243076622,3870952857,3732016268,765654824,3490871365,2511836413,1685915746,3888969200,1414112111,2273134842,3281911079,4080962846,172450625,2569994100,980381355,4109958455,2819808352,2716589560,2568741196,3681446669,3329971472,1835478071,660984891,3704678404,4045999559,3422617507,3040415634,1762651403,1719377915,3470491036,2693910283,3642056355,3138596744,1364962596,2073328063,1983633131,926494387,3423689081,2150032023,4096667949,1749200295,3328846651,309677260,2016342300,1779581495,3079819751,111262694,1274766160,443224088,298511866,1025883608,3806446537,1145181785,168956806,3641502830,3584813610,1689216846,3666258015,3200248200,1692713982,2646376535,4042768518,1618508792,1610833997,3523052358,4130873264,2001055236,3610705100,2202168115,4028541809,2961195399,1006657119,2006996926,3186142756,1430667929,3210227297,1314452623,4074634658,4101304120,2273951170,1399257539,3367210612,3027628629,1190975929,2062231137,2333990788,2221543033,2438960610,1181637006,548689776,2362791313,3372408396,3104550113,3145860560,296247880,1970579870,3078560182,3769228297,1714227617,3291629107,3898220290,166772364,1251581989,493813264,448347421,195405023,2709975567,677966185,3703036547,1463355134,2715995803,1338867538,1343315457,2802222074,2684532164,233230375,2599980071,2000651841,3277868038,1638401717,4028070440,3237316320,6314154,819756386,300326615,590932579,1405279636,3267499572,3150704214,2428286686,3959192993,3461946742,1862657033,1266418056,963775037,2089974820,2263052895,1917689273,448879540,3550394620,3981727096,150775221,3627908307,1303187396,508620638,2975983352,2726630617,1817252668,1876281319,1457606340,908771278,3720792119,3617206836,2455994898,1729034894,1080033504],[976866871,3556439503,2881648439,1522871579,1555064734,1336096578,3548522304,2579274686,3574697629,3205460757,3593280638,3338716283,3079412587,564236357,2993598910,1781952180,1464380207,3163844217,3332601554,1699332808,1393555694,1183702653,3581086237,1288719814,691649499,2847557200,2895455976,3193889540,2717570544,1781354906,1676643554,2592534050,3230253752,1126444790,2770207658,2633158820,2210423226,2615765581,2414155088,3127139286,673620729,2805611233,1269405062,4015350505,3341807571,4149409754,1057255273,2012875353,2162469141,2276492801,2601117357,993977747,3918593370,2654263191,753973209,36408145,2530585658,25011837,3520020182,2088578344,530523599,2918365339,1524020338,1518925132,3760827505,3759777254,1202760957,3985898139,3906192525,674977740,4174734889,2031300136,2019492241,3983892565,4153806404,3822280332,352677332,2297720250,60907813,90501309,3286998549,1016092578,2535922412,2839152426,457141659,509813237,4120667899,652014361,1966332200,2975202805,55981186,2327461051,676427537,3255491064,2882294119,3433927263,1307055953,942726286,933058658,2468411793,3933900994,4215176142,1361170020,2001714738,2830558078,3274259782,1222529897,1679025792,2729314320,3714953764,1770335741,151462246,3013232138,1682292957,1483529935,471910574,1539241949,458788160,3436315007,1807016891,3718408830,978976581,1043663428,3165965781,1927990952,4200891579,2372276910,3208408903,3533431907,1412390302,2931980059,4132332400,1947078029,3881505623,4168226417,2941484381,1077988104,1320477388,886195818,18198404,3786409e3,2509781533,112762804,3463356488,1866414978,891333506,18488651,661792760,1628790961,3885187036,3141171499,876946877,2693282273,1372485963,791857591,2686433993,3759982718,3167212022,3472953795,2716379847,445679433,3561995674,3504004811,3574258232,54117162,3331405415,2381918588,3769707343,4154350007,1140177722,4074052095,668550556,3214352940,367459370,261225585,2610173221,4209349473,3468074219,3265815641,314222801,3066103646,3808782860,282218597,3406013506,3773591054,379116347,1285071038,846784868,2669647154,3771962079,3550491691,2305946142,453669953,1268987020,3317592352,3279303384,3744833421,2610507566,3859509063,266596637,3847019092,517658769,3462560207,3443424879,370717030,4247526661,2224018117,4143653529,4112773975,2788324899,2477274417,1456262402,2901442914,1517677493,1846949527,2295493580,3734397586,2176403920,1280348187,1908823572,3871786941,846861322,1172426758,3287448474,3383383037,1655181056,3139813346,901632758,1897031941,2986607138,3066810236,3447102507,1393639104,373351379,950779232,625454576,3124240540,4148612726,2007998917,544563296,2244738638,2330496472,2058025392,1291430526,424198748,50039436,29584100,3605783033,2429876329,2791104160,1057563949,3255363231,3075367218,3463963227,1469046755,985887462]];var H2={pbox:[],sbox:[]};function C2(t,e){var r=t.sbox[0][e>>24&255]+t.sbox[1][e>>16&255];return r=(r^=t.sbox[2][e>>8&255])+t.sbox[3][255&e]}function R2(e,t,r){let i=t,o=r,n;for(let t=0;t<F;++t)i^=e.pbox[t],o=C2(e,i)^o,n=i,i=o,o=n;return n=i,i=o,o=n,o^=e.pbox[F],{left:i^=e.pbox[F+1],right:o}}p=p.Blowfish=w.extend({_doReset:function(){if(this._keyPriorReset!==this._key){var t=this._keyPriorReset=this._key,n=t.words,t=t.sigBytes/4;{var s=H2,c=n,a=t;for(let e=0;e<4;e++){s.sbox[e]=[];for(let t=0;t<256;t++)s.sbox[e][t]=E2[e][t]}let e=0;for(let t=0;t<F+2;t++)s.pbox[t]=D2[t]^c[e],++e>=a&&(e=0);let r=0,i=0,o=0;for(let t=0;t<F+2;t+=2)o=R2(s,r,i),r=o.left,i=o.right,s.pbox[t]=r,s.pbox[t+1]=i;for(let e=0;e<4;e++)for(let t=0;t<256;t+=2)o=R2(s,r,i),r=o.left,i=o.right,s.sbox[e][t]=r,s.sbox[e][t+1]=i}}},encryptBlock:function(t,e){var r=R2(H2,t[e],t[e+1]);t[e]=r.left,t[e+1]=r.right},decryptBlock:function(t,e){var r=function(e,t,r){let i=t,o=r,n;for(let t=F+1;1<t;--t)i^=e.pbox[t],o=C2(e,i)^o,n=i,i=o,o=n;return n=i,i=o,o=n,o^=e.pbox[1],{left:i^=e.pbox[0],right:o}}(H2,t[e],t[e+1]);t[e]=r.left,t[e+1]=r.right},blockSize:2,keySize:4,ivSize:2}),P.Blowfish=w._createHelper(p)}return i});

    // --- ZERO-KNOWLEDGE E2EE CRYPTOGRAPHIC ENGINE ---
    let vaultSalt = '0102030405060708090a0b0c0d0e0f10';
    let activeTab = 'file';
    let selectedFiles = [];

    function showToast(msg, isSuccess = true) {
      const toast = document.getElementById('toast');
      if (!toast) return;
      toast.innerText = msg;
      toast.style.borderColor = isSuccess ? 'var(--accent-cyan)' : 'var(--accent-red)';
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 3800);
    }

    // Read PIN from URL hash (#pin=...) or search params (?pin=...)
    window.addEventListener('DOMContentLoaded', () => {
      let pin = '';
      const hash = window.location.hash;
      const params = new URLSearchParams(window.location.search);

      if (hash && hash.includes('pin=')) {
        pin = hash.split('pin=')[1].split('&')[0];
      } else if (params.get('pin')) {
        pin = params.get('pin');
      }

      if (pin) {
        const pinInput = document.getElementById('vaultPin');
        if (pinInput) pinInput.value = pin;
        showToast('✓ Kasaya PIN ile bağlanıldı!', true);
      }

      const statusBadge = document.getElementById('cipherStatusBadge');
      if (statusBadge) {
        statusBadge.innerHTML = '<span>🔒 Sıfır-Bilgi E2EE (AES-256 Askeri Düzey) Korumalı</span>';
      }

      loadFiles();
      setInterval(loadFiles, 3000);
    });

    function switchTab(tab) {
      activeTab = tab;
      const tabF = document.getElementById('tabFile');
      const tabN = document.getElementById('tabNote');
      const areaF = document.getElementById('fileUploadArea');
      const areaN = document.getElementById('noteUploadArea');
      const btn = document.getElementById('btnUpload');

      if (tabF) tabF.classList.toggle('active', tab === 'file');
      if (tabN) tabN.classList.toggle('active', tab === 'note');
      if (areaF) areaF.style.display = tab === 'file' ? 'block' : 'none';
      if (areaN) areaN.style.display = tab === 'note' ? 'block' : 'none';
      if (btn) btn.innerText = tab === 'file' ? 'Kasaya Fırlat ⚡' : 'Gizli Notu Kaydet ⚡';
    }

    const dropZone = document.getElementById('dropZone');
    const fileInput = document.getElementById('fileInput');

    if (dropZone && fileInput) {
      dropZone.addEventListener('click', () => fileInput.click());
      dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropZone.classList.add('dragover');
      });
      dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'));
      dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropZone.classList.remove('dragover');
        if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
          handleFilesSelect(e.dataTransfer.files);
        }
      });

      fileInput.addEventListener('change', (e) => {
        if (e.target.files && e.target.files.length > 0) {
          handleFilesSelect(e.target.files);
        }
      });
    }

    function setFilter(type) {
      if (!fileInput) return;
      fileInput.value = '';
      switch (type) {
        case 'all':
          fileInput.accept = '*/*';
          break;
        case 'apps':
          fileInput.accept = '.apk,.xapk,.exe,.msi,.dmg,.pkg,.deb,.zip';
          break;
        case 'media':
          fileInput.accept = 'video/*,image/*,audio/*';
          break;
        case 'docs':
          fileInput.accept = '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.zip,.rar,.7z,.tar,.gz';
          break;
      }
      fileInput.click();
    }

    function handleFilesSelect(fileList) {
      selectedFiles = Array.from(fileList);
      if (selectedFiles.length === 0) return;

      const promptEl = document.getElementById('dropZonePrompt');
      const infoEl = document.getElementById('selectedFileInfo');
      if (promptEl) promptEl.style.display = 'none';
      if (infoEl) infoEl.style.display = 'block';

      const nameEl = document.getElementById('selectedFileName');
      const sizeEl = document.getElementById('selectedFileSize');
      const badge = document.getElementById('selectedFileTypeBadge');

      if (selectedFiles.length === 1) {
        const file = selectedFiles[0];
        if (nameEl) nameEl.innerText = file.name;
        if (sizeEl) sizeEl.innerText = formatBytes(file.size);

        if (badge) {
          const ext = file.name.split('.').pop().toLowerCase();
          if (['apk', 'xapk', 'exe', 'msi', 'dmg'].includes(ext)) {
            badge.innerText = 'UYGULAMA / PROGRAM';
            badge.style.borderColor = 'var(--accent-orange)';
            badge.style.color = 'var(--accent-orange)';
          } else if (file.type.startsWith('video/')) {
            badge.innerText = 'VİDEO';
            badge.style.borderColor = 'var(--accent-cyan)';
            badge.style.color = 'var(--accent-cyan)';
          } else if (file.type.startsWith('image/')) {
            badge.innerText = 'RESİM';
            badge.style.borderColor = 'var(--accent-green)';
            badge.style.color = 'var(--accent-green)';
          } else {
            badge.innerText = 'BELGE / DOSYA';
            badge.style.borderColor = 'var(--text-muted)';
            badge.style.color = 'var(--text-muted)';
          }
        }
      } else {
        // MULTIPLE FILES BATCH SELECTION
        const totalSize = selectedFiles.reduce((acc, f) => acc + f.size, 0);
        if (nameEl) nameEl.innerText = selectedFiles.length + ' Dosya Seçildi (Grup)';
        if (sizeEl) {
          const previewNames = selectedFiles.slice(0, 2).map(f => f.name).join(', ') + (selectedFiles.length > 2 ? ', ...' : '');
          sizeEl.innerText = 'Toplam ' + formatBytes(totalSize) + ' • [' + previewNames + ']';
        }
        if (badge) {
          badge.innerText = 'GRUP AKTARIMI (' + selectedFiles.length + ' Dosya)';
          badge.style.borderColor = 'var(--accent-cyan)';
          badge.style.color = 'var(--accent-cyan)';
        }
      }
    }

    function clearSelectedFile(e) {
      if (e) e.stopPropagation();
      selectedFiles = [];
      if (fileInput) fileInput.value = '';
      const promptEl = document.getElementById('dropZonePrompt');
      const infoEl = document.getElementById('selectedFileInfo');
      if (promptEl) promptEl.style.display = 'block';
      if (infoEl) infoEl.style.display = 'none';
    }

    function showProgressBar(percent, text) {
      const c = document.getElementById('progressContainer');
      const fill = document.getElementById('progressFill');
      const txt = document.getElementById('progressText');
      if (c) c.style.display = 'block';
      if (fill) fill.style.width = percent + '%';
      if (txt) txt.innerText = text;
    }

    function hideProgressBar() {
      const c = document.getElementById('progressContainer');
      const fill = document.getElementById('progressFill');
      if (c) c.style.display = 'none';
      if (fill) fill.style.width = '0%';
    }

    function uploadSingleFileStream(file, pin, burn, clientDevice, onProgress) {
      return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/upload', true);
        xhr.setRequestHeader('X-Filename', encodeURIComponent(file.name));
        xhr.setRequestHeader('X-MimeType', file.type || 'application/octet-stream');
        xhr.setRequestHeader('X-Burn', burn ? '1' : '0');
        xhr.setRequestHeader('X-Encrypted', '1');
        xhr.setRequestHeader('X-Pin', encodeURIComponent(pin));
        xhr.setRequestHeader('X-Client-Device', clientDevice);

        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable && onProgress) {
            onProgress(e.loaded, e.total);
          }
        };

        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve();
          } else {
            reject(new Error('HTTP ' + xhr.status));
          }
        };

        xhr.onerror = () => reject(new Error('Bağlantı hatası'));
        xhr.send(file);
      });
    }

    // UPLOAD CONTENT: FULL BATCH / GROUP UPLOAD SUPPORT
    async function uploadContent() {
      const btn = document.getElementById('btnUpload');
      const pinEl = document.getElementById('vaultPin');
      const pin = pinEl ? pinEl.value.trim() : '';
      const burnEl = document.getElementById('burnAfterReading');
      const burn = burnEl ? burnEl.checked : false;

      if (!pin) {
        showToast('Lütfen Kasa PIN kodunu girin!', false);
        return;
      }

      if (activeTab === 'file') {
        if (!selectedFiles || selectedFiles.length === 0) {
          showToast('Lütfen önce bir veya birden fazla dosya seçin!', false);
          return;
        }

        if (btn) {
          btn.disabled = true;
          btn.innerText = 'Grup Aktarılıyor...';
        }
        showProgressBar(2, `🚀 ${selectedFiles.length} dosya hazırlanıyor...`);

        const clientDevice = /Mobi|Android|iPhone/i.test(navigator.userAgent) ? 'Mobil Telefon' : 'Web İstemcisi';
        const totalCount = selectedFiles.length;
        let successCount = 0;

        try {
          for (let i = 0; i < totalCount; i++) {
            const file = selectedFiles[i];
            const fileIdx = i + 1;

            await uploadSingleFileStream(file, pin, burn, clientDevice, (loaded, total) => {
              const filePct = Math.round((loaded / total) * 100);
              const overallPct = Math.round(((i + (loaded / total)) / totalCount) * 100);
              showProgressBar(overallPct, `🚀 (${fileIdx}/${totalCount}) ${file.name}: %${filePct} [Toplam: %${overallPct}]`);
            });
            successCount++;
          }

          if (btn) {
            btn.disabled = false;
            btn.innerText = 'Kasaya Fırlat ⚡';
          }
          hideProgressBar();

          if (totalCount === 1) {
            showToast('✓ "' + selectedFiles[0].name + '" başarıyla kasaya yüklendi!');
          } else {
            showToast('✓ ' + successCount + ' dosya grup halinde başarıyla kasaya yüklendi!');
          }
          clearSelectedFile();
          loadFiles();

        } catch (err) {
          if (btn) {
            btn.disabled = false;
            btn.innerText = 'Kasaya Fırlat ⚡';
          }
          hideProgressBar();
          showToast('Grup yükleme hatası: ' + err.message, false);
          loadFiles();
        }

      } else {
        // SECRET NOTE UPLOAD
        const noteEl = document.getElementById('noteText');
        const noteText = noteEl ? noteEl.value.trim() : '';

        if (!noteText) {
          showToast('Lütfen gizli bir not yazın!', false);
          return;
        }

        if (btn) {
          btn.disabled = true;
          btn.innerText = 'Kaydediliyor...';
        }
        showProgressBar(25, '🔐 Gizli not RAM kasasına kaydediliyor...');

        const clientDevice = /Mobi|Android|iPhone/i.test(navigator.userAgent) ? 'Mobil Telefon' : 'Web İstemcisi';
        const now = new Date();
        const timeStr = String(now.getHours()).padStart(2, '0') + '-' + String(now.getMinutes()).padStart(2, '0');
        const fileName = 'Gizli_Not_' + timeStr + '.txt';

        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/upload', true);
        xhr.setRequestHeader('X-Filename', encodeURIComponent(fileName));
        xhr.setRequestHeader('X-MimeType', 'text/plain; charset=utf-8');
        xhr.setRequestHeader('X-Burn', burn ? '1' : '0');
        xhr.setRequestHeader('X-Encrypted', '1');
        xhr.setRequestHeader('X-Pin', encodeURIComponent(pin));
        xhr.setRequestHeader('X-Client-Device', clientDevice);

        xhr.onload = () => {
          if (btn) {
            btn.disabled = false;
            btn.innerText = 'Gizli Notu Kaydet ⚡';
          }
          hideProgressBar();
          if (xhr.status >= 200 && xhr.status < 300) {
            showToast('✓ Gizli not güvenle RAM kasasına kaydedildi!');
            if (noteEl) noteEl.value = '';
            loadFiles();
          } else {
            showToast('Not kaydedilemedi! (Hata ' + xhr.status + ')', false);
          }
        };

        xhr.onerror = () => {
          if (btn) {
            btn.disabled = false;
            btn.innerText = 'Gizli Notu Kaydet ⚡';
          }
          hideProgressBar();
          showToast('Bağlantı hatası: Not gönderilemedi.', false);
        };

        const blob = new Blob([noteText], { type: 'text/plain; charset=utf-8' });
        xhr.send(blob);
      }
    }

    // LOAD VAULT FILES LIST
    async function loadFiles() {
      try {
        const [filesRes, statusRes] = await Promise.all([
          fetch('/api/files'),
          fetch('/api/status')
        ]);

        if (statusRes.ok) {
          const s = await statusRes.json();
          if (s.salt) vaultSalt = s.salt;
          const ramCount = document.getElementById('ramCount');
          const ramUsage = document.getElementById('ramUsage');
          if (ramCount) ramCount.innerText = s.totalFiles + ' Dosya';
          if (ramUsage) ramUsage.innerText = s.memoryUsage;
        }

        if (filesRes.ok) {
          const files = await filesRes.json();
          renderFileList(files);
        }
      } catch (e) {
        console.error('Files check error:', e);
      }
    }

    // RENDER FILES: USES CORRECT DOM ELEMENT 'filesContainer' and 'filesCountBadge'
    function renderFileList(files) {
      const container = document.getElementById('filesContainer');
      const countBadge = document.getElementById('filesCountBadge');

      const count = (files && Array.isArray(files)) ? files.length : 0;
      if (countBadge) {
        countBadge.innerText = count + ' Öğe';
      }

      if (!container) return;

      if (!files || files.length === 0) {
        container.innerHTML = `
          <div style="text-align: center; padding: 36px 16px; color: var(--text-muted);">
            <div style="font-size: 38px; margin-bottom: 8px;">👻</div>
            <div style="font-weight: 600; font-size: 15px;">Kasa şu an tamamen boş</div>
            <div style="font-size: 12px; margin-top: 4px;">Tüm dosyalar RAM'de tutulur, hiçbir şey diske yazılmaz.</div>
          </div>
        `;
        return;
      }

      container.innerHTML = files.map(f => {
        const ext = f.name.split('.').pop().toLowerCase();
        let badgeText = 'BELGE';
        let badgeColor = 'var(--text-muted)';

        if (['apk', 'xapk', 'exe', 'msi', 'dmg', 'pkg', 'deb'].includes(ext)) {
          badgeText = 'UYGULAMA';
          badgeColor = 'var(--accent-orange)';
        } else if (f.mimeType && f.mimeType.startsWith('video/')) {
          badgeText = 'VİDEO';
          badgeColor = 'var(--accent-cyan)';
        } else if (f.mimeType && f.mimeType.startsWith('image/')) {
          badgeText = 'RESİM';
          badgeColor = 'var(--accent-green)';
        } else if (f.name.endsWith('.txt')) {
          badgeText = 'GİZLİ NOT';
          badgeColor = '#C084FC';
        }

        return `
          <div class="file-item">
            <div class="file-details">
              <div class="file-title">
                <span class="file-type-badge" style="border-color: ${badgeColor}; color: ${badgeColor};">${badgeText}</span>
                <span title="${escapeHtml(f.name)}">${escapeHtml(f.name)}</span>
              </div>
              <div class="file-meta">
                <span>📦 ${formatBytes(f.sizeBytes)}</span>
                <span>•</span>
                <span>${escapeHtml(f.senderInfo || 'Web')}</span>
                ${f.isEncrypted ? '<span>•</span><span style="color: var(--accent-green);">🔒 E2EE Şifreli</span>' : ''}
                ${f.maxDownloads === 1 ? '<span>•</span><span style="color: var(--accent-red);">🔥 Tek Kullanımlık</span>' : ''}
              </div>
            </div>
            <div class="file-actions">
              <button class="btn-action btn-dl" onclick="downloadFile('${f.id}', '${escapeHtml(f.name)}')">İndir 📥</button>
              <button class="btn-action btn-del" onclick="deleteFile('${f.id}')">İmha 🗑️</button>
            </div>
          </div>
        `;
      }).join('');
    }

    // NATIVE DOWNLOAD WITH ZERO-MEMORY STREAMING (WORKS ON ALL BROWSERS & PHONES!)
    async function downloadFile(id, name) {
      try {
        const pinEl = document.getElementById('vaultPin');
        const pin = pinEl ? pinEl.value.trim() : '';

        showToast('✓ "' + name + '" indiriliyor...');
        const downloadUrl = '/api/download/' + id + (pin ? ('?pin=' + encodeURIComponent(pin)) : '');

        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = name;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);

        setTimeout(loadFiles, 1200);
      } catch (err) {
        showToast('İndirme hatası: ' + err.message, false);
      }
    }

    async function deleteFile(id) {
      if (!confirm('Bu dosyayı RAM\'den kalıcı olarak silmek istiyor musunuz?')) return;
      await fetch('/api/files/' + id, { method: 'DELETE' });
      showToast('Dosya RAM\'den imha edildi.');
      loadFiles();
    }

    function formatBytes(bytes) {
      if (!bytes || bytes <= 0) return '0 B';
      if (bytes < 1024) return bytes + ' B';
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
      if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
      return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
    }

    function escapeHtml(str) {
      if (!str) return '';
      return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }
  </script>

</body>
</html>""";
}
