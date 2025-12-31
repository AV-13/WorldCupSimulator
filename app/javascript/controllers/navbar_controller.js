import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.isOpen = false
  }

  toggle() {
    this.isOpen = !this.isOpen
    const navbar = document.querySelector('.main-navbar')

    if (this.isOpen) {
      navbar.classList.add('mobile-open')
    } else {
      navbar.classList.remove('mobile-open')
    }
  }
}
