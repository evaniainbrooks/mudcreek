import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["event", "now"]

  declare eventTargets: HTMLElement[]
  declare nowTarget: HTMLElement

  private interval: ReturnType<typeof setInterval> | null = null

  connect(): void {
    this.update()
    this.interval = setInterval(() => this.update(), 60_000)
  }

  disconnect(): void {
    if (this.interval) clearInterval(this.interval)
  }

  update(): void {
    const now = new Date()
    const currentMinutes = now.getHours() * 60 + now.getMinutes()

    // Find the last event whose start time is at or before now
    let insertAfter: HTMLElement | null = null
    for (const el of this.eventTargets) {
      const mins = parseInt(el.dataset.eventMinutes ?? "0", 10)
      if (mins <= currentMinutes) insertAfter = el
    }

    const indicator = this.nowTarget
    const first = this.eventTargets[0]
    const last  = this.eventTargets[this.eventTargets.length - 1]

    if (!first) {
      // No events
      indicator.style.display = "none"
    } else if (!insertAfter) {
      // All events are still in the future — show before the first
      first.before(indicator)
      indicator.style.display = "flex"
    } else if (insertAfter === last) {
      // All events have already started — nothing "next" to point to
      indicator.style.display = "none"
    } else {
      // Insert between the last past event and the next upcoming one
      insertAfter.after(indicator)
      indicator.style.display = "flex"
    }
  }
}
