import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  connect() {
    this.isOpen = false
  }

  toggle(event) {
    event.preventDefault()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.isOpen = true
    this.element.classList.add("open")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
  }

  close() {
    this.isOpen = false
    this.element.classList.remove("open")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.contentTarget.style.maxHeight = "0"
  }
}
