import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  // Submit on Enter (Shift+Enter = newline)
  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();

      const content = this.inputTarget.value.trim();
      if (!content) {
        this.shake();
        return;
      }

      this.element.requestSubmit();
      this.inputTarget.value = "";
    }
  }

  // Show image preview before upload
  previewImage(event) {
    const file = event.target.files[0];
    if (!file) return;

    const container = document.getElementById("image-preview-container");
    if (!container) return;

    container.innerHTML = "";
    const img = document.createElement("img");
    img.src = URL.createObjectURL(file);
    img.style.cssText = "max-height:80px;border-radius:6px;border:1px solid var(--border);";
    container.appendChild(img);
  }

  shake() {
    this.inputTarget.classList.add("is-invalid");
    this.inputTarget.addEventListener(
      "animationend",
      () => this.inputTarget.classList.remove("is-invalid"),
      { once: true }
    );
  }
}
