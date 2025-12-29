import { Controller } from "@hotwired/stimulus"

// Sortable drag and drop controller for team ranking
export default class extends Controller {
  static targets = ["list", "item"]

  connect() {
    this.draggedItem = null
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    this.itemTargets.forEach(item => {
      item.setAttribute("draggable", "true")

      item.addEventListener("dragstart", (e) => this.handleDragStart(e))
      item.addEventListener("dragend", (e) => this.handleDragEnd(e))
      item.addEventListener("dragover", (e) => this.handleDragOver(e))
      item.addEventListener("drop", (e) => this.handleDrop(e))

      // Touch support
      item.addEventListener("touchstart", (e) => this.handleTouchStart(e), { passive: false })
      item.addEventListener("touchmove", (e) => this.handleTouchMove(e), { passive: false })
      item.addEventListener("touchend", (e) => this.handleTouchEnd(e))
    })
  }

  handleDragStart(e) {
    this.draggedItem = e.target.closest("[data-sortable-target='item']")
    if (this.draggedItem) {
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", "")
      this.draggedItem.classList.add("dragging")
      setTimeout(() => {
        this.draggedItem.style.opacity = "0.5"
      }, 0)
    }
  }

  handleDragEnd(e) {
    if (this.draggedItem) {
      this.draggedItem.style.opacity = "1"
      this.draggedItem.classList.remove("dragging")
      this.draggedItem = null
      this.updateRanks()
      this.updateHiddenInputs()
    }
  }

  handleDragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"

    const target = e.target.closest("[data-sortable-target='item']")
    if (target && target !== this.draggedItem) {
      const rect = target.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2

      if (e.clientY < midpoint) {
        target.parentNode.insertBefore(this.draggedItem, target)
      } else {
        target.parentNode.insertBefore(this.draggedItem, target.nextSibling)
      }
    }
  }

  handleDrop(e) {
    e.preventDefault()
  }

  // Touch support for mobile devices
  handleTouchStart(e) {
    this.draggedItem = e.target.closest("[data-sortable-target='item']")
    if (this.draggedItem) {
      this.touchStartY = e.touches[0].clientY
      this.draggedItem.classList.add("dragging")
    }
  }

  handleTouchMove(e) {
    if (!this.draggedItem) return
    e.preventDefault()

    const touch = e.touches[0]
    const target = document.elementFromPoint(touch.clientX, touch.clientY)
    const targetItem = target?.closest("[data-sortable-target='item']")

    if (targetItem && targetItem !== this.draggedItem) {
      const rect = targetItem.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2

      if (touch.clientY < midpoint) {
        targetItem.parentNode.insertBefore(this.draggedItem, targetItem)
      } else {
        targetItem.parentNode.insertBefore(this.draggedItem, targetItem.nextSibling)
      }
    }
  }

  handleTouchEnd(e) {
    if (this.draggedItem) {
      this.draggedItem.classList.remove("dragging")
      this.draggedItem = null
      this.updateRanks()
      this.updateHiddenInputs()
    }
  }

  updateRanks() {
    this.itemTargets.forEach((item, index) => {
      const rankEl = item.querySelector("[data-rank]")
      if (rankEl) {
        rankEl.textContent = `${index + 1}.`
      }

      // Update visual styling based on position
      item.classList.remove("qualified", "third", "eliminated")
      if (index < 2) {
        item.classList.add("qualified")
        item.style.borderColor = "#28a745"
      } else if (index === 2) {
        item.classList.add("third")
        item.style.borderColor = "#fd7e14"
      } else {
        item.classList.add("eliminated")
        item.style.borderColor = "#dc3545"
      }
    })
  }

  updateHiddenInputs() {
    this.itemTargets.forEach((item, index) => {
      const input = item.querySelector("input[name='team_ids[]']")
      if (input) {
        // Force the form to pick up items in DOM order
        input.value = item.dataset.teamId
      }
    })
  }
}
