import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "nav", "content", "template"]

  connect() {
    this.activeTeamId = this.element.querySelector('.team-nav-item.active')?.dataset.teamId
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase().trim()
    const groups = this.navTarget.querySelectorAll('.teams-group')

    groups.forEach(group => {
      const items = group.querySelectorAll('.team-nav-item')
      let visibleCount = 0

      items.forEach(item => {
        const teamName = item.dataset.teamName.toLowerCase()
        const matches = teamName.includes(query)
        item.classList.toggle('hidden', !matches)
        if (matches) visibleCount++
      })

      // Hide entire group if no visible teams
      group.classList.toggle('hidden', visibleCount === 0)
    })
  }

  async selectTeam(event) {
    const button = event.currentTarget
    const teamId = button.dataset.teamId

    // Don't reload if already selected
    if (teamId === this.activeTeamId) return

    // Update active state in sidebar
    this.navTarget.querySelectorAll('.team-nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.teamId === teamId)
    })
    this.activeTeamId = teamId

    // Show loading state
    this.contentTarget.innerHTML = `
      <div class="team-detail-loading">
        <div class="loading-spinner"></div>
      </div>
    `

    try {
      // Fetch team details via Turbo Frame or fetch API
      const response = await fetch(`/teams/${teamId}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.contentTarget.innerHTML = html
      } else {
        throw new Error('Failed to load team')
      }
    } catch (error) {
      console.error('Error loading team:', error)
      this.contentTarget.innerHTML = `
        <div class="teams-empty">
          <p>Failed to load team details. Please try again.</p>
        </div>
      `
    }

    // Close mobile sidebar if open
    this.closeMobileSidebar()
  }

  // Mobile sidebar toggle
  toggleMobileSidebar() {
    const sidebar = this.element.querySelector('.teams-sidebar')
    const overlay = this.element.querySelector('.teams-sidebar-overlay')
    sidebar?.classList.toggle('open')
    overlay?.classList.toggle('open')
  }

  closeMobileSidebar() {
    const sidebar = this.element.querySelector('.teams-sidebar')
    const overlay = this.element.querySelector('.teams-sidebar-overlay')
    sidebar?.classList.remove('open')
    overlay?.classList.remove('open')
  }
}
