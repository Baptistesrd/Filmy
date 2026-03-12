import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["card", "empty", "hint"];

  connect() {
    this._dragging  = false;
    this._startX    = 0;
    this._deltaX    = 0;
    this._topCard   = null;

    this._onPointerDown = this._onPointerDown.bind(this);
    this._onPointerMove = this._onPointerMove.bind(this);
    this._onPointerUp   = this._onPointerUp.bind(this);

    this._refreshTop();
  }

  disconnect() {
    this._unbind();
  }

  // ── Button actions ─────────────────────────────────────────────────────────

  like() { if (this._topCard) this._animateOut("right"); }
  skip() { if (this._topCard) this._animateOut("left"); }

  // ── Stack management ──────────────────────────────────────────────────────

  _refreshTop() {
    this._unbind();

    const cards = this.cardTargets.filter(c => !c.classList.contains("rswipe--gone"));

    // Update stack transforms
    cards.forEach((card, i) => {
      card.style.transition = "transform 0.3s ease";
      if (i === 0) {
        card.style.transform  = "";
        card.style.zIndex     = "10";
        card.style.opacity    = "1";
        card.style.pointerEvents = "auto";
      } else if (i === 1) {
        card.style.transform  = "scale(0.95) translateY(10px)";
        card.style.zIndex     = "9";
        card.style.opacity    = "1";
        card.style.pointerEvents = "none";
      } else if (i === 2) {
        card.style.transform  = "scale(0.90) translateY(20px)";
        card.style.zIndex     = "8";
        card.style.opacity    = "1";
        card.style.pointerEvents = "none";
      } else {
        card.style.opacity    = "0";
        card.style.pointerEvents = "none";
      }
    });

    if (!cards.length) {
      if (this.hasEmptyTarget)  this.emptyTarget.classList.remove("d-none");
      if (this.hasHintTarget)   this.hintTarget.classList.add("d-none");
      return;
    }

    if (this.hasEmptyTarget) this.emptyTarget.classList.add("d-none");
    if (this.hasHintTarget)  this.hintTarget.classList.remove("d-none");

    this._topCard = cards[0];
    this._topCard.addEventListener("pointerdown", this._onPointerDown);
  }

  _unbind() {
    if (this._topCard) {
      this._topCard.removeEventListener("pointerdown", this._onPointerDown);
    }
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup",   this._onPointerUp);
  }

  // ── Pointer events ─────────────────────────────────────────────────────────

  _onPointerDown(e) {
    if (e.button !== 0 && e.pointerType !== "touch") return;
    this._dragging = true;
    this._startX   = e.clientX;
    this._deltaX   = 0;
    this._topCard.setPointerCapture(e.pointerId);
    this._topCard.style.transition = "none";
    document.addEventListener("pointermove", this._onPointerMove);
    document.addEventListener("pointerup",   this._onPointerUp);
  }

  _onPointerMove(e) {
    if (!this._dragging) return;
    this._deltaX = e.clientX - this._startX;
    const rot    = this._deltaX * 0.06;
    this._topCard.style.transform = `translateX(${this._deltaX}px) rotate(${rot}deg)`;

    const like = this._topCard.querySelector(".rswipe-overlay--like");
    const skip = this._topCard.querySelector(".rswipe-overlay--skip");
    if (this._deltaX > 15) {
      like.style.opacity = Math.min((this._deltaX - 15) / 60, 1);
      skip.style.opacity = 0;
    } else if (this._deltaX < -15) {
      skip.style.opacity = Math.min((-this._deltaX - 15) / 60, 1);
      like.style.opacity = 0;
    } else {
      like.style.opacity = 0;
      skip.style.opacity = 0;
    }
  }

  _onPointerUp() {
    if (!this._dragging) return;
    this._dragging = false;
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup",   this._onPointerUp);

    const threshold = 70;
    if (this._deltaX > threshold) {
      this._animateOut("right");
    } else if (this._deltaX < -threshold) {
      this._animateOut("left");
    } else {
      // Snap back
      this._topCard.style.transition = "transform 0.35s cubic-bezier(.18,.89,.32,1.28)";
      this._topCard.style.transform  = "";
      this._topCard.querySelector(".rswipe-overlay--like").style.opacity = 0;
      this._topCard.querySelector(".rswipe-overlay--skip").style.opacity = 0;
    }
  }

  // ── Animation ─────────────────────────────────────────────────────────────

  _animateOut(direction) {
    const card  = this._topCard;
    const liked = direction === "right";
    const xOut  = liked ? window.innerWidth * 1.3 : -window.innerWidth * 1.3;

    card.style.transition = "transform 0.4s ease, opacity 0.4s ease";
    card.style.transform  = `translateX(${xOut}px) rotate(${liked ? 25 : -25}deg)`;
    card.style.opacity    = "0";

    card.querySelector(".rswipe-overlay--like").style.opacity = liked ? 1 : 0;
    card.querySelector(".rswipe-overlay--skip").style.opacity = liked ? 0 : 1;

    if (liked) this._save(card);

    card.addEventListener("transitionend", () => {
      card.classList.add("rswipe--gone");
      this._refreshTop();
    }, { once: true });
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  _save(card) {
    const url  = card.dataset.saveUrl;
    if (!url) return;
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content;
    fetch(url, {
      method:  "POST",
      headers: { "X-CSRF-Token": csrf, "Accept": "text/vnd.turbo-stream.html" }
    }).catch(err => console.warn("Save failed:", err));
  }
}
