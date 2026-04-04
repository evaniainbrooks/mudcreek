import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]
  static values = { timeout: { type: Number, default: 8000 } }

  declare slideTargets: HTMLElement[]
  declare timeoutValue: number

  private currentIndex = 0
  private timer: ReturnType<typeof setInterval> | undefined

  connect() {
    if (this.slideTargets.length > 1) {
      this.timer = setInterval(() => this.advance(), this.timeoutValue)
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }

  private advance() {
    const slides = this.slideTargets
    const leaving = slides[this.currentIndex]
    this.currentIndex = (this.currentIndex + 1) % slides.length
    const entering = slides[this.currentIndex]

    leaving.style.opacity = "0"
    if (leaving instanceof HTMLVideoElement) leaving.pause()

    entering.style.opacity = "1"
    if (entering instanceof HTMLVideoElement) entering.play()
  }
}
