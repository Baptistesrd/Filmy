import { Controller } from "@hotwired/stimulus";

// Fades out a card that has a success indicator (e.g., after saving)
export default class extends Controller {
  connect() {
    const saved = this.element.querySelector(".rec-film-saved");
    if (!saved) return;

    // Brief confirmation flash, then stabilise
    saved.style.opacity = "0";
    requestAnimationFrame(() => {
      saved.style.transition = "opacity 0.3s ease";
      saved.style.opacity = "1";
    });
  }
}
