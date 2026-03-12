import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["stack", "card", "empty"];
  static values  = { saveUrl: String, moreUrl: String, csrf: String };

  connect() {
    this._page       = 1;
    this._loading    = false;
    this._queue      = [];
    this._startX     = 0;
    this._startY     = 0;
    this._deltaX     = 0;
    this._dragging   = false;
    this._topCard    = null;
    this._likedCount = 0;
    this._seenCount  = 0;
    this._bgLayer    = "a"; // active background layer

    this._onPointerDown  = this._onPointerDown.bind(this);
    this._onPointerMove  = this._onPointerMove.bind(this);
    this._onPointerUp    = this._onPointerUp.bind(this);
    this._onKeyDown      = this._onKeyDown.bind(this);

    document.addEventListener("keydown", this._onKeyDown);
    this._refreshTop();
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeyDown);
    this._unbindDrag();
  }

  // ── Public button actions ──────────────────────────────────────────────────

  likeCurrent() {
    this._decide(true);
  }

  skipCurrent() {
    this._decide(false);
  }

  // ── Keyboard ──────────────────────────────────────────────────────────────

  _onKeyDown(e) {
    if (e.key === "ArrowRight") this._decide(true);
    if (e.key === "ArrowLeft")  this._decide(false);
  }

  // ── Drag handling ─────────────────────────────────────────────────────────

  _refreshTop() {
    this._unbindDrag();
    const cards = this.cardTargets.filter(c => c.isConnected && !c.classList.contains("swipe-card--gone"));
    if (!cards.length) {
      this._loadMore();
      return;
    }
    this._topCard = cards[0];
    this._topCard.classList.add("swipe-card--top");
    this._topCard.addEventListener("pointerdown", this._onPointerDown);
    this._updateBackground(this._topCard.dataset.poster);
  }

  // ── Background cross-fade ──────────────────────────────────────────────────

  _updateBackground(posterUrl) {
    if (!posterUrl) return;
    const nextLayer = this._bgLayer === "a" ? "b" : "a";
    const nextEl    = document.getElementById(`discover-bg-${nextLayer}`);
    const prevEl    = document.getElementById(`discover-bg-${this._bgLayer}`);
    if (!nextEl || !prevEl) return;

    nextEl.style.backgroundImage = `url('${posterUrl}')`;
    nextEl.style.opacity = "1";
    prevEl.style.opacity = "0";
    this._bgLayer = nextLayer;
  }

  // ── Stats counters ─────────────────────────────────────────────────────────

  _incrementSeen() {
    this._seenCount++;
    const el = document.getElementById("seen-count");
    if (el) el.textContent = this._seenCount;
  }

  _incrementLiked() {
    this._likedCount++;
    const el = document.getElementById("liked-count");
    if (el) el.textContent = this._likedCount;
  }

  _unbindDrag() {
    if (this._topCard) {
      this._topCard.removeEventListener("pointerdown", this._onPointerDown);
    }
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
    document.addEventListener("pointermove", this._onPointerMove);
    document.addEventListener("pointerup",   this._onPointerUp);
    this._topCard.style.transition = "none";
  }

  _onPointerMove(e) {
    if (!this._dragging) return;
    this._deltaX = e.clientX - this._startX;
    const deltaY = e.clientY - this._startY;
    const rot    = this._deltaX * 0.07;
    this._topCard.style.transform = `translate(${this._deltaX}px, ${deltaY * 0.3}px) rotate(${rot}deg)`;

    // Show overlay hints
    const likeOverlay = this._topCard.querySelector(".swipe-overlay--like");
    const skipOverlay = this._topCard.querySelector(".swipe-overlay--skip");
    if (this._deltaX > 20) {
      likeOverlay.style.opacity = Math.min((this._deltaX - 20) / 80, 1);
      skipOverlay.style.opacity = 0;
    } else if (this._deltaX < -20) {
      skipOverlay.style.opacity = Math.min((-this._deltaX - 20) / 80, 1);
      likeOverlay.style.opacity = 0;
    } else {
      likeOverlay.style.opacity = 0;
      skipOverlay.style.opacity = 0;
    }
  }

  _onPointerUp() {
    if (!this._dragging) return;
    this._dragging = false;
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup",   this._onPointerUp);

    const threshold = window.innerWidth * 0.28;
    if (this._deltaX > threshold) {
      this._animateOut("right");
    } else if (this._deltaX < -threshold) {
      this._animateOut("left");
    } else {
      // Snap back
      this._topCard.style.transition = "transform 0.35s cubic-bezier(.18,.89,.32,1.28)";
      this._topCard.style.transform  = "";
      const likeOverlay = this._topCard.querySelector(".swipe-overlay--like");
      const skipOverlay = this._topCard.querySelector(".swipe-overlay--skip");
      likeOverlay.style.opacity = 0;
      skipOverlay.style.opacity = 0;
    }
  }

  // ── Decision logic ────────────────────────────────────────────────────────

  _decide(liked) {
    if (!this._topCard) return;
    liked ? this._animateOut("right") : this._animateOut("left");
  }

  _animateOut(direction) {
    const card    = this._topCard;
    const liked   = direction === "right";
    const xTarget = liked ? window.innerWidth * 1.4 : -window.innerWidth * 1.4;
    const rot     = liked ? 30 : -30;

    card.style.transition = "transform 0.45s cubic-bezier(.55,.06,.68,.19), opacity 0.45s ease";
    card.style.transform  = `translate(${xTarget}px, 40px) rotate(${rot}deg)`;
    card.style.opacity    = "0";

    const likeOverlay = card.querySelector(".swipe-overlay--like");
    const skipOverlay = card.querySelector(".swipe-overlay--skip");
    if (liked) {
      likeOverlay.style.opacity = 1;
    } else {
      skipOverlay.style.opacity = 1;
    }

    this._savePreference(card, liked);
    this._incrementSeen();
    if (liked) this._incrementLiked();

    card.addEventListener("transitionend", () => {
      card.classList.add("swipe-card--gone");
      this._refreshTop();
    }, { once: true });
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  _savePreference(card, liked) {
    const body = {
      swipe_preference: {
        tmdb_id:     card.dataset.tmdbId,
        title:       card.dataset.title,
        year:        card.dataset.year,
        poster_url:  card.dataset.poster,
        synopsis:    card.dataset.synopsis,
        tmdb_rating: card.dataset.rating,
        liked:       liked
      }
    };

    fetch(this.saveUrlValue, {
      method:  "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfValue
      },
      body: JSON.stringify(body)
    }).catch(err => console.warn("Swipe save failed:", err));
  }

  // ── Infinite load ─────────────────────────────────────────────────────────

  _loadMore() {
    if (this._loading) return;
    this._loading = true;

    if (this.hasEmptyTarget) {
      this.emptyTarget.style.display = "flex";
    }

    this._page++;
    const url = new URL(this.moreUrlValue, window.location.origin);
    url.searchParams.set("page", this._page);

    fetch(url.toString(), {
      headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfValue }
    })
      .then(r => r.json())
      .then(films => {
        this._loading = false;
        if (this.hasEmptyTarget) this.emptyTarget.style.display = "none";

        if (!films.length) {
          // Wrap back around
          this._page = 0;
          this._loadMore();
          return;
        }

        const seenIds = new Set(
          this.cardTargets.map(c => c.dataset.tmdbId)
        );

        films.forEach(film => {
          if (seenIds.has(String(film.tmdb_id))) return;
          seenIds.add(String(film.tmdb_id));
          this.stackTarget.insertBefore(this._buildCard(film), this.emptyTarget);
        });

        this._refreshTop();
      })
      .catch(err => {
        this._loading = false;
        console.warn("Load more failed:", err);
      });
  }

  _buildCard(film) {
    const div = document.createElement("div");
    div.className = "swipe-card";
    div.dataset.swipeTarget  = "card";
    div.dataset.tmdbId       = film.tmdb_id;
    div.dataset.title        = film.title        || "";
    div.dataset.year         = film.year         || "";
    div.dataset.poster       = film.poster_url   || "";
    div.dataset.synopsis     = film.synopsis     || "";
    div.dataset.rating       = film.tmdb_rating  || "";

    const posterHtml = film.poster_url
      ? `<img src="${film.poster_url}" alt="${this._esc(film.title)}" class="swipe-poster" loading="lazy">`
      : `<div class="swipe-poster swipe-poster--placeholder"><i class="fa-solid fa-film"></i></div>`;

    const year   = film.year   ? `<span class="swipe-year">${film.year}</span>` : "";
    const rating = film.tmdb_rating ? `<span class="swipe-rating"><i class="fa-solid fa-star"></i> ${film.tmdb_rating}</span>` : "";
    const syn    = film.synopsis
      ? `<p class="swipe-synopsis">${this._esc(film.synopsis.slice(0, 120))}${film.synopsis.length > 120 ? "…" : ""}</p>`
      : "";

    div.innerHTML = `
      ${posterHtml}
      <div class="swipe-overlay swipe-overlay--like">LIKE</div>
      <div class="swipe-overlay swipe-overlay--skip">SKIP</div>
      <div class="swipe-info">
        <h3 class="swipe-film-title">${this._esc(film.title)}</h3>
        <div class="swipe-meta">${year}${rating}</div>
        ${syn}
      </div>
    `;
    return div;
  }

  _esc(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
}
