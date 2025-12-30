import { Controller } from "@hotwired/stimulus"

// Sortable drag and drop controller for team ranking
// With smooth animations during drag
export default class extends Controller {
  static targets = ["list", "item"]

  connect() {
    this.draggedItem = null
    this.placeholder = null
    this.setupDragAndDrop()
    this.updateRanks() // Initial position styling
  }

  setupDragAndDrop() {
    this.itemTargets.forEach(item => {
      item.setAttribute("draggable", "true")

      item.addEventListener("dragstart", (e) => this.handleDragStart(e))
      item.addEventListener("dragend", (e) => this.handleDragEnd(e))
      item.addEventListener("dragover", (e) => this.handleDragOver(e))
      item.addEventListener("dragenter", (e) => this.handleDragEnter(e))
      item.addEventListener("dragleave", (e) => this.handleDragLeave(e))
      item.addEventListener("drop", (e) => this.handleDrop(e))

      // Touch support
      item.addEventListener("touchstart", (e) => this.handleTouchStart(e), { passive: false })
      item.addEventListener("touchmove", (e) => this.handleTouchMove(e), { passive: false })
      item.addEventListener("touchend", (e) => this.handleTouchEnd(e))
    })
  }

  createPlaceholder() {
    const placeholder = document.createElement("div")
    placeholder.className = "ranking-item ranking-placeholder"
    placeholder.style.height = `${this.draggedItem.offsetHeight}px`
    return placeholder
  }

  handleDragStart(e) {
    this.draggedItem = e.target.closest("[data-sortable-target='item']")
    if (!this.draggedItem) return

    // Store original dimensions
    const rect = this.draggedItem.getBoundingClientRect()
    this.draggedItem.style.width = `${rect.width}px`

    // Create placeholder
    this.placeholder = this.createPlaceholder()

    // Setup drag visual
    e.dataTransfer.effectAllowed = "move"
    e.dataTransfer.setData("text/plain", "")

    // Delay to allow drag image to be captured
    requestAnimationFrame(() => {
      this.draggedItem.classList.add("dragging")
      this.draggedItem.parentNode.insertBefore(this.placeholder, this.draggedItem)
    })
  }

  handleDragEnd(e) {
    if (!this.draggedItem) return

    // Remove placeholder and insert dragged item in its place
    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.insertBefore(this.draggedItem, this.placeholder)
      this.placeholder.remove()
    }

    // Cleanup
    this.draggedItem.classList.remove("dragging")
    this.draggedItem.style.width = ""
    this.draggedItem = null
    this.placeholder = null

    // Update all items
    this.animateReorder()
    this.updateRanks()
    this.updateHiddenInputs()
  }

  handleDragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"

    if (!this.draggedItem || !this.placeholder) return

    const target = e.target.closest("[data-sortable-target='item']")
    if (!target || target === this.draggedItem || target === this.placeholder) return

    const rect = target.getBoundingClientRect()
    const midpoint = rect.top + rect.height / 2

    // Move placeholder with smooth transition
    if (e.clientY < midpoint) {
      if (target.previousElementSibling !== this.placeholder) {
        this.animatePlaceholderMove(target, 'before')
      }
    } else {
      if (target.nextElementSibling !== this.placeholder) {
        this.animatePlaceholderMove(target, 'after')
      }
    }
  }

  handleDragEnter(e) {
    e.preventDefault()
  }

  handleDragLeave(e) {
    // Optional: visual feedback when leaving an item
  }

  handleDrop(e) {
    e.preventDefault()
  }

  animatePlaceholderMove(target, position) {
    if (!this.placeholder) return

    // Get all items that will move
    const items = Array.from(this.listTarget.querySelectorAll('.ranking-item:not(.dragging):not(.ranking-placeholder)'))

    // Store old positions
    const oldPositions = new Map()
    items.forEach(item => {
      oldPositions.set(item, item.getBoundingClientRect())
    })

    // Move placeholder
    if (position === 'before') {
      target.parentNode.insertBefore(this.placeholder, target)
    } else {
      target.parentNode.insertBefore(this.placeholder, target.nextSibling)
    }

    // Animate items to new positions (FLIP technique)
    items.forEach(item => {
      const oldPos = oldPositions.get(item)
      const newPos = item.getBoundingClientRect()
      const deltaY = oldPos.top - newPos.top

      if (Math.abs(deltaY) > 1) {
        item.style.transform = `translateY(${deltaY}px)`
        item.style.transition = 'none'

        requestAnimationFrame(() => {
          item.style.transition = 'transform 150ms ease-out'
          item.style.transform = ''
        })
      }
    })
  }

  animateReorder() {
    // Brief animation to settle items
    this.itemTargets.forEach(item => {
      item.style.transition = 'all 150ms ease-out'
      setTimeout(() => {
        item.style.transition = ''
      }, 150)
    })
  }

  // Touch support for mobile devices
  handleTouchStart(e) {
    const item = e.target.closest("[data-sortable-target='item']")
    if (!item) return

    this.draggedItem = item
    this.touchStartY = e.touches[0].clientY
    this.touchStartX = e.touches[0].clientX

    // Store original position
    const rect = item.getBoundingClientRect()
    this.dragStartRect = rect

    // Create placeholder
    this.placeholder = this.createPlaceholder()

    // Setup dragging state after a brief delay (to distinguish from scroll)
    this.touchTimeout = setTimeout(() => {
      if (this.draggedItem) {
        this.draggedItem.classList.add("dragging", "touch-dragging")
        this.draggedItem.parentNode.insertBefore(this.placeholder, this.draggedItem)

        // Position element under finger
        this.draggedItem.style.position = 'fixed'
        this.draggedItem.style.zIndex = '1000'
        this.draggedItem.style.width = `${rect.width}px`
        this.draggedItem.style.left = `${rect.left}px`
        this.draggedItem.style.top = `${rect.top}px`
        this.draggedItem.style.pointerEvents = 'none'
      }
    }, 150)
  }

  handleTouchMove(e) {
    if (!this.draggedItem) return

    const touch = e.touches[0]
    const deltaY = touch.clientY - this.touchStartY

    // Only start drag mode if moved enough
    if (!this.draggedItem.classList.contains("touch-dragging")) {
      if (Math.abs(deltaY) > 10) {
        clearTimeout(this.touchTimeout)
        this.handleTouchStart(e)
      }
      return
    }

    e.preventDefault()

    // Move the dragged element
    if (this.dragStartRect) {
      this.draggedItem.style.top = `${this.dragStartRect.top + deltaY}px`
    }

    // Find target at touch point (excluding the dragged element)
    this.draggedItem.style.pointerEvents = 'none'
    const elementBelow = document.elementFromPoint(touch.clientX, touch.clientY)
    this.draggedItem.style.pointerEvents = ''

    const targetItem = elementBelow?.closest("[data-sortable-target='item']")

    if (targetItem && targetItem !== this.draggedItem && targetItem !== this.placeholder) {
      const rect = targetItem.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2

      if (touch.clientY < midpoint) {
        if (targetItem.previousElementSibling !== this.placeholder) {
          this.animatePlaceholderMove(targetItem, 'before')
        }
      } else {
        if (targetItem.nextElementSibling !== this.placeholder) {
          this.animatePlaceholderMove(targetItem, 'after')
        }
      }
    }
  }

  handleTouchEnd(e) {
    clearTimeout(this.touchTimeout)

    if (!this.draggedItem) return

    // Reset styles
    this.draggedItem.style.position = ''
    this.draggedItem.style.zIndex = ''
    this.draggedItem.style.width = ''
    this.draggedItem.style.left = ''
    this.draggedItem.style.top = ''
    this.draggedItem.style.pointerEvents = ''
    this.draggedItem.classList.remove("dragging", "touch-dragging")

    // Replace placeholder with dragged item
    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.insertBefore(this.draggedItem, this.placeholder)
      this.placeholder.remove()
    }

    this.draggedItem = null
    this.placeholder = null
    this.dragStartRect = null

    this.animateReorder()
    this.updateRanks()
    this.updateHiddenInputs()
  }

  updateRanks() {
    this.itemTargets.forEach((item, index) => {
      const rankEl = item.querySelector("[data-rank]")
      if (rankEl) {
        rankEl.textContent = `${index + 1}`
      }

      // Update visual styling based on position
      item.classList.remove("position-1", "position-2", "position-3", "position-4", "qualified", "third", "eliminated")
      item.classList.add(`position-${index + 1}`)

      if (index < 2) {
        item.classList.add("qualified")
      } else if (index === 2) {
        item.classList.add("third")
      } else {
        item.classList.add("eliminated")
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

  get listTarget() {
    return this.element.querySelector("[data-sortable-target='list']") || this.element
  }
}
