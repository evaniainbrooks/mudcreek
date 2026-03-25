import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "time"]

  declare dateTarget: HTMLElement
  declare timeTarget: HTMLElement

  private interval: ReturnType<typeof setInterval> | null = null

  connect(): void {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect(): void {
    if (this.interval) clearInterval(this.interval)
  }

  tick(): void {
    const now = new Date()
    this.dateTarget.textContent = now.toLocaleDateString(undefined, {
      weekday: "long",
      month: "long",
      day: "numeric",
    })
    this.timeTarget.textContent = now.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    })
  }
}
