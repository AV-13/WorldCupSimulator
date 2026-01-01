import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.particles = []
    this.colors = ['#c4a77d', '#d4bc96', '#8b7355', '#3d6b4f', '#2e4a3a', '#ffffff', '#f0e6d3']
    this.running = true

    this.setupCanvas()
    this.createParticles()
    this.animate()

    // Stop after 8 seconds
    setTimeout(() => {
      this.running = false
    }, 8000)
  }

  disconnect() {
    this.running = false
  }

  setupCanvas() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext('2d')
    this.resizeCanvas()

    window.addEventListener('resize', () => this.resizeCanvas())
  }

  resizeCanvas() {
    this.canvas.width = window.innerWidth
    this.canvas.height = window.innerHeight
  }

  createParticles() {
    const particleCount = 150

    for (let i = 0; i < particleCount; i++) {
      this.particles.push({
        x: Math.random() * this.canvas.width,
        y: Math.random() * this.canvas.height - this.canvas.height,
        size: Math.random() * 8 + 4,
        color: this.colors[Math.floor(Math.random() * this.colors.length)],
        speedY: Math.random() * 3 + 2,
        speedX: Math.random() * 2 - 1,
        rotation: Math.random() * 360,
        rotationSpeed: Math.random() * 10 - 5,
        opacity: Math.random() * 0.5 + 0.5,
        shape: Math.random() > 0.5 ? 'rect' : 'circle'
      })
    }
  }

  animate() {
    if (!this.running) {
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
      return
    }

    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

    this.particles.forEach((p, index) => {
      // Update position
      p.y += p.speedY
      p.x += p.speedX
      p.rotation += p.rotationSpeed

      // Add some wave motion
      p.x += Math.sin(p.y * 0.01) * 0.5

      // Reset if off screen
      if (p.y > this.canvas.height) {
        p.y = -p.size
        p.x = Math.random() * this.canvas.width
      }

      // Draw particle
      this.ctx.save()
      this.ctx.translate(p.x, p.y)
      this.ctx.rotate(p.rotation * Math.PI / 180)
      this.ctx.globalAlpha = p.opacity
      this.ctx.fillStyle = p.color

      if (p.shape === 'rect') {
        this.ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 0.6)
      } else {
        this.ctx.beginPath()
        this.ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2)
        this.ctx.fill()
      }

      this.ctx.restore()
    })

    requestAnimationFrame(() => this.animate())
  }
}
