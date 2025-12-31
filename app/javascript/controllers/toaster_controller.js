import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 500 } }

  connect() {
    // Show toaster after a short delay
    setTimeout(() => {
      this.element.classList.add("visible")
    }, this.delayValue)
  }

  dismiss() {
    this.element.classList.remove("visible")
    this.element.classList.add("dismissed")

    // Remove from DOM after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
