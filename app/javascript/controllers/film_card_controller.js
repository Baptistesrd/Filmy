import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const tick = this.element.querySelector(".text-success");

    if (tick) {
      setTimeout(() => {
        this.element.style.transition = "opacity 0.4s";
        this.element.style.opacity = "0";

        setTimeout(() => {
          this.element.remove();
        }, 400);
      }, 700);
    }
  }
}
