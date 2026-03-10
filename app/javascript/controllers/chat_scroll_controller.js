import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["messages"];

  connect() {
    this._scroll = this._scroll.bind(this);
    this._scroll();

    document.addEventListener("turbo:before-stream-render", this._scroll);
    document.addEventListener("turbo:render", this._scroll);
    document.addEventListener("turbo:load", this._scroll);
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this._scroll);
    document.removeEventListener("turbo:render", this._scroll);
    document.removeEventListener("turbo:load", this._scroll);
  }

  _scroll() {
    if (!this.hasMessagesTarget) return;
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
    });
  }
}
