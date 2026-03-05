import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["messages"];

  connect() {
    this.scrollToBottom();
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return;
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }
}
