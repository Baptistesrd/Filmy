import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["messages"];

  connect() {
    this.scrollToBottom = this.scrollToBottom.bind(this);

    this.scrollToBottom();

    document.addEventListener(
      "turbo:before-stream-render",
      this.scrollToBottom,
    );
    document.addEventListener("turbo:render", this.scrollToBottom);
    document.addEventListener("turbo:load", this.scrollToBottom);
  }

  disconnect() {
    document.removeEventListener(
      "turbo:before-stream-render",
      this.scrollToBottom,
    );
    document.removeEventListener("turbo:render", this.scrollToBottom);
    document.removeEventListener("turbo:load", this.scrollToBottom);
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return;

    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
    });
  }
}
