import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 5000 } }
  static targets = ["countdown"]

  declare urlValue: string
  declare delayValue: number
  declare hasCountdownTarget: boolean
  declare countdownTarget: HTMLElement

  private interval: ReturnType<typeof setInterval> | null = null
  private remaining: number = 0

  connect(): void {
    this.remaining = Math.round(this.delayValue / 1000)
    this.updateDisplay()
    this.interval = setInterval(() => {
      this.remaining -= 1
      this.updateDisplay()
      if (this.remaining <= 0) {
        this.stop()
        window.location.href = this.urlValue
      }
    }, 1000)
  }

  disconnect(): void {
    this.stop()
  }

  private stop(): void {
    if (this.interval) {
      clearInterval(this.interval)
      this.interval = null
    }
  }

  private updateDisplay(): void {
    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = String(this.remaining)
    }
  }
}
