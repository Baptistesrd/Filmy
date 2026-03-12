import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["stack", "card", "empty"];
  static values  = {
    saveUrl:      String,
    moreUrl:      String,
    recommendUrl: String,
    csrf:         String,
    category:     { type: String, default: "popular" }
  };

  connect() {
    this._page       = 1;
    this._loading    = false;
    this._topCard    = null;
    this._likedCount = 0;
    this._seenCount  = 0;
    this._dragging   = false;
    this._startX     = 0;
    this._startY     = 0;
    this._deltaX     = 0;

    this._onPointerDown = this._onPointerDown.bind(this);
    this._onPointerMove = this._onPointerMove.bind(this);
    this._onPointerUp   = this._onPointerUp.bind(this);
    this._onKeyDown     = this._onKeyDown.bind(this);

    document.addEventListener("keydown", this._onKeyDown);
    this._refreshTop();
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeyDown);
    this._unbindDrag();
  }

  // ── Swipe actions ──────────────────────────────────────────────────────────────
  likeCurrent() { this._decide(true);  }
  skipCurrent() { this._decide(false); }

  // ── Category switching ─────────────────────────────────────────────────────────
  switchCategory(e) {
    const cat = e.currentTarget.dataset.cat;
    if (cat === this.categoryValue) return;

    document.querySelectorAll("[data-cat]").forEach(btn => {
      btn.classList.toggle("discover-cat--active", btn.dataset.cat === cat);
    });

    this.categoryValue = cat;
    this._page = 0;
    this._clearAllCards();
    this._loadMore();
  }

  _clearAllCards() {
    this.cardTargets.forEach(c => c.remove());
  }

  // ── Recommendation ─────────────────────────────────────────────────────────────
  recommend() {
    const btn = document.getElementById("rec-trigger-btn");
    if (btn) {
      btn.disabled = true;
      btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i><span>Finding…</span>';
    }

    fetch(this.recommendUrlValue, {
      method:  "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfValue },
      body:    JSON.stringify({})
    })
      .then(r => r.json())
      .then(data => {
        if (data.error) {
          this._resetPickBtn();
          if (data.error === "no_likes") {
            this._flashPickBtn('<i class="fa-solid fa-heart"></i><span>Like a film first!</span>');
          } else {
            this._flashPickBtn('<i class="fa-solid fa-triangle-exclamation"></i><span>Try again</span>');
          }
          return;
        }
        this._showRecommendation(data);
      })
      .catch(() => {
        this._resetPickBtn();
        this._flashPickBtn('<i class="fa-solid fa-triangle-exclamation"></i><span>Try again</span>');
      });
  }

  keepSwiping() {
    const overlay = document.getElementById("rec-overlay");
    if (overlay) overlay.classList.remove("rec-overlay--visible");
    this._resetPickBtn();
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────────
  _onKeyDown(e) {
    const overlay = document.getElementById("rec-overlay");
    const overlayOpen = overlay && overlay.classList.contains("rec-overlay--visible");

    if (overlayOpen) {
      if (e.key === "Escape") this.keepSwiping();
      return; // block swipe keys while overlay is open
    }

    if (e.key === "ArrowRight") this._decide(true);
    if (e.key === "ArrowLeft")  this._decide(false);
  }

  // ── Drag ───────────────────────────────────────────────────────────────────────
  _refreshTop() {
    this._unbindDrag();

    const visible = this.cardTargets.filter(c => !c.classList.contains("swipe-card--gone"));
    if (!visible.length) { this._loadMore(); return; }

    // JS-managed stacking — no CSS nth-child conflicts
    this._updateCardStack(visible);

    this._topCard = visible[0];
    this._topCard.classList.add("swipe-card--top");
    this._topCard.addEventListener("pointerdown", this._onPointerDown);
    this._updateBackground(this._topCard.dataset.poster);
  }

  _updateCardStack(cards) {
    cards.forEach((card, i) => {
      card.style.transition = "";
      if (i === 0) {
        card.style.transform    = "none";
        card.style.zIndex       = "10";
        card.style.opacity      = "1";
        card.style.pointerEvents = "auto";
      } else if (i === 1) {
        card.style.transform    = "scale(0.96) translateY(6px)";
        card.style.zIndex       = "9";
        card.style.opacity      = "1";
        card.style.pointerEvents = "none";
      } else if (i === 2) {
        card.style.transform    = "scale(0.92) translateY(12px)";
        card.style.zIndex       = "8";
        card.style.opacity      = "0.6";
        card.style.pointerEvents = "none";
      } else {
        card.style.zIndex       = String(7 - i);
        card.style.opacity      = "0";
        card.style.pointerEvents = "none";
      }
    });
  }

  _unbindDrag() {
    if (this._topCard) this._topCard.removeEventListener("pointerdown", this._onPointerDown);
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup",   this._onPointerUp);
  }

  _onPointerDown(e) {
    if (e.button !== 0 && e.pointerType !== "touch") return;
    this._dragging = true;
    this._startX   = e.clientX;
    this._startY   = e.clientY;
    this._deltaX   = 0;
    this._topCard.setPointerCapture(e.pointerId);
    this._topCard.style.transition = "none";
    document.addEventListener("pointermove", this._onPointerMove);
    document.addEventListener("pointerup",   this._onPointerUp);
  }

  _onPointerMove(e) {
    if (!this._dragging) return;
    this._deltaX        = e.clientX - this._startX;
    const dy            = e.clientY - this._startY;
    const rot           = this._deltaX * 0.06;
    this._topCard.style.transform = `translate(${this._deltaX}px, ${dy * 0.3}px) rotate(${rot}deg)`;

    const likeEl = this._topCard.querySelector(".swipe-overlay--like");
    const nopeEl = this._topCard.querySelector(".swipe-overlay--nope");
    const abs    = Math.abs(this._deltaX);
    const pct    = Math.max(0, (abs - 20) / 80);

    if (this._deltaX > 20)       { likeEl.style.opacity = Math.min(pct, 1); nopeEl.style.opacity = 0; }
    else if (this._deltaX < -20) { nopeEl.style.opacity = Math.min(pct, 1); likeEl.style.opacity = 0; }
    else                         { likeEl.style.opacity = nopeEl.style.opacity = 0; }
  }

  _onPointerUp() {
    if (!this._dragging) return;
    this._dragging = false;
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup",   this._onPointerUp);

    const threshold = window.innerWidth * 0.26;
    if      (this._deltaX >  threshold) this._animateOut("right");
    else if (this._deltaX < -threshold) this._animateOut("left");
    else    this._snapBack();
  }

  _snapBack() {
    this._topCard.style.transition = "transform 0.4s cubic-bezier(.18,.89,.32,1.28)";
    this._topCard.style.transform  = "none";
    this._topCard.querySelector(".swipe-overlay--like").style.opacity = 0;
    this._topCard.querySelector(".swipe-overlay--nope").style.opacity = 0;
  }

  _decide(liked) {
    if (!this._topCard) return;
    this._animateOut(liked ? "right" : "left");
  }

  _animateOut(dir) {
    const liked   = dir === "right";
    const card    = this._topCard;
    const xTarget = liked ? window.innerWidth * 1.5 : -window.innerWidth * 1.5;

    card.style.transition = "transform 0.42s cubic-bezier(.55,.06,.68,.19), opacity 0.38s ease";
    card.style.transform  = `translate(${xTarget}px, 20px) rotate(${liked ? 22 : -22}deg)`;
    card.style.opacity    = "0";

    const likeEl = card.querySelector(".swipe-overlay--like");
    const nopeEl = card.querySelector(".swipe-overlay--nope");
    liked ? (likeEl.style.opacity = 1) : (nopeEl.style.opacity = 1);

    this._savePreference(card, liked);

    this._seenCount++;
    const seenEl = document.getElementById("seen-count");
    if (seenEl) seenEl.textContent = this._seenCount;

    if (liked) {
      this._likedCount++;
      const likedCountEl = document.getElementById("liked-count");
      if (likedCountEl) likedCountEl.textContent = this._likedCount;
    }

    card.addEventListener("transitionend", () => {
      card.classList.add("swipe-card--gone");
      this._refreshTop();
    }, { once: true });
  }

  // ── Background (no-op — background layers removed) ────────────────────────────
  _updateBackground(_url) {}

  // ── Persistence ────────────────────────────────────────────────────────────────
  _savePreference(card, liked) {
    fetch(this.saveUrlValue, {
      method:  "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfValue },
      body: JSON.stringify({
        swipe_preference: {
          tmdb_id:     card.dataset.tmdbId,
          title:       card.dataset.title,
          year:        card.dataset.year,
          poster_url:  card.dataset.poster,
          synopsis:    card.dataset.synopsis,
          tmdb_rating: card.dataset.rating,
          liked
        }
      })
    }).catch(err => console.warn("Swipe save:", err));
  }

  // ── Infinite load ──────────────────────────────────────────────────────────────
  _loadMore() {
    if (this._loading) return;
    this._loading = true;

    if (this.hasEmptyTarget) this.emptyTarget.style.display = "flex";

    this._page++;
    const url = new URL(this.moreUrlValue, window.location.origin);
    url.searchParams.set("page",     this._page);
    url.searchParams.set("category", this.categoryValue);

    fetch(url.toString(), {
      headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfValue }
    })
      .then(r => r.json())
      .then(films => {
        this._loading = false;
        if (this.hasEmptyTarget) this.emptyTarget.style.display = "none";

        if (!films.length) { this._page = 0; this._loadMore(); return; }

        const seen = new Set(this.cardTargets.map(c => c.dataset.tmdbId));
        films.forEach(f => {
          if (seen.has(String(f.tmdb_id))) return;
          seen.add(String(f.tmdb_id));
          this.stackTarget.insertBefore(this._buildCard(f), this.emptyTarget);
        });
        this._refreshTop();
      })
      .catch(() => { this._loading = false; });
  }

  _buildCard(f) {
    const div = document.createElement("div");
    div.className           = "swipe-card";
    div.dataset.swipeTarget = "card";
    div.dataset.tmdbId      = f.tmdb_id     || "";
    div.dataset.title       = f.title       || "";
    div.dataset.year        = f.year        || "";
    div.dataset.poster      = f.poster_url  || "";
    div.dataset.synopsis    = (f.synopsis   || "").slice(0, 160);
    div.dataset.rating      = f.tmdb_rating || "";

    const poster = f.poster_url
      ? `<img src="${f.poster_url}" alt="${this._esc(f.title)}" class="swipe-poster" loading="lazy">`
      : `<div class="swipe-poster swipe-poster--placeholder"><i class="fa-solid fa-film"></i></div>`;

    const year   = f.year        ? `<span class="swipe-card-year">${f.year}</span>` : "";
    const rating = f.tmdb_rating ? `<span class="swipe-card-rating"><i class="fa-solid fa-star"></i> ${f.tmdb_rating}</span>` : "";
    const syn    = f.synopsis    ? `<p class="swipe-card-synopsis">${this._esc(f.synopsis.slice(0,110))}${f.synopsis.length>110?"…":""}</p>` : "";

    div.innerHTML = `
      ${poster}
      <div class="swipe-overlay swipe-overlay--like"><i class="fa-solid fa-heart"></i> LIKE</div>
      <div class="swipe-overlay swipe-overlay--nope">NOPE <i class="fa-solid fa-xmark"></i></div>
      <div class="swipe-card-info">
        <h2 class="swipe-card-title">${this._esc(f.title)}</h2>
        <div class="swipe-card-meta">${year}${rating}</div>
        ${syn}
      </div>`;
    return div;
  }

  // ── Recommendation display ─────────────────────────────────────────────────────
  _showRecommendation(data) {
    // Backdrop blur
    const backdropBlur = document.getElementById("rec-backdrop-blur");
    if (backdropBlur && data.poster_url) {
      backdropBlur.style.backgroundImage = `url('${data.poster_url}')`;
    }

    // Poster
    const posterWrap = document.getElementById("rec-poster-wrap");
    if (posterWrap) {
      posterWrap.innerHTML = data.poster_url
        ? `<img src="${data.poster_url}" alt="${this._esc(data.title)}" class="rec-poster">`
        : `<div class="rec-poster rec-poster--placeholder"><i class="fa-solid fa-film"></i></div>`;
    }

    // Message
    const msgEl = document.getElementById("rec-message");
    if (msgEl) msgEl.textContent = data.message || "";

    // Title
    const titleEl = document.getElementById("rec-title");
    if (titleEl) titleEl.textContent = data.title || "";

    // Meta chips
    const metaEl = document.getElementById("rec-meta");
    if (metaEl) {
      const parts = [];
      if (data.year)     parts.push(`<span class="rec-meta-chip">${data.year}</span>`);
      if (data.rating)   parts.push(`<span class="rec-meta-chip rec-meta-chip--amber"><i class="fa-solid fa-star"></i> ${data.rating}</span>`);
      if (data.director) parts.push(`<span class="rec-meta-chip">dir. ${this._esc(data.director)}</span>`);
      metaEl.innerHTML = parts.join("");
    }

    // Trailer button
    const trailerBtn = document.getElementById("rec-trailer");
    if (trailerBtn) {
      trailerBtn.style.display = data.trailer_url ? "inline-flex" : "none";
      if (data.trailer_url) trailerBtn.href = data.trailer_url;
    }

    // Show overlay
    const overlay = document.getElementById("rec-overlay");
    if (overlay) overlay.classList.add("rec-overlay--visible");
  }

  _resetPickBtn() {
    const btn = document.getElementById("rec-trigger-btn");
    if (!btn) return;
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles"></i><span>My pick</span>';
  }

  _flashPickBtn(html) {
    const btn = document.getElementById("rec-trigger-btn");
    if (!btn) return;
    btn.innerHTML = html;
    setTimeout(() => this._resetPickBtn(), 2800);
  }

  _esc(str) {
    return String(str || "")
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
}
