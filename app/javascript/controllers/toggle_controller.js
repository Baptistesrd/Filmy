import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["hideable", "show"];

  call(event) {
    event.preventDefault();

    if (this.hideableTarget.classList.contains("d-none")) {
      // Show sidebar
      this.hideableTarget.classList.remove("d-none");
      this.showTarget.classList.add("d-none");
    } else {
      // Hide sidebar
      this.hideableTarget.classList.add("d-none");
      this.showTarget.classList.remove("d-none");
    }
  }
}
