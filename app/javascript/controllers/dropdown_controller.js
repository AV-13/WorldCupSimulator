import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    this.isOpen = false
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    this.boundHandleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleClickOutside)
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.isOpen = true
    this.menuTarget.classList.add("open")
    this.triggerTarget.classList.add("open")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.boundHandleClickOutside)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  close() {
    this.isOpen = false
    this.menuTarget.classList.remove("open")
    this.triggerTarget.classList.remove("open")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.boundHandleClickOutside)
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.triggerTarget.focus()
    }
  }
}
