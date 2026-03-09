import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { endsAt: String, badge: Boolean, reload: Boolean }
  static targets = ["display"]

  declare endsAtValue: string
  declare badgeValue: boolean
  declare reloadValue: boolean
  declare hasDisplayTarget: boolean
  declare displayTarget: HTMLElement

  private interval: ReturnType<typeof setInterval> | null = null

  connect(): void {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect(): void {
    if (this.interval) clearInterval(this.interval)
  }

  tick(): void {
    const diff = new Date(this.endsAtValue).getTime() - Date.now()

    if (diff <= 0) {
      if (this.interval) {
        clearInterval(this.interval)
        this.interval = null
      }
      if (this.reloadValue) {
        window.location.reload()
      } else if (this.hasDisplayTarget) {
        this.displayTarget.textContent = ""
      }
      return
    }

    if (!this.hasDisplayTarget) return

    if (this.badgeValue) {
      if (diff >= 60000) {
        const mins = Math.floor(diff / 60000)
        this.displayTarget.textContent = `Ending Soon! ${mins}m`
      } else {
        const secs = Math.floor(diff / 1000)
        this.displayTarget.textContent = `Ending Soon! ${secs}s`
      }
      return
    }

    const days = Math.floor(diff / 86400000)
    const hours = Math.floor((diff % 86400000) / 3600000)
    const minutes = Math.floor((diff % 3600000) / 60000)
    const seconds = Math.floor((diff % 60000) / 1000)

    const parts: string[] = []
    if (days > 0) parts.push(`${days}d`)
    parts.push(`${String(hours).padStart(2, "0")}h`)
    parts.push(`${String(minutes).padStart(2, "0")}m`)
    parts.push(`${String(seconds).padStart(2, "0")}s`)

    this.displayTarget.textContent = parts.join(" ")
  }
}
