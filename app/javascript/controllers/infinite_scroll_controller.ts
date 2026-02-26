import { Controller } from "@hotwired/stimulus"
import { renderStreamMessage } from "@hotwired/turbo"

export default class extends Controller {
  static targets = ["sentinel"]

  declare sentinelTarget: Element
  declare hasSentinelTarget: boolean

  private observer!: IntersectionObserver

  connect(): void {
    this.observer = new IntersectionObserver(this.load.bind(this), {
      rootMargin: "300px"
    })
  }

  disconnect(): void {
    this.observer.disconnect()
  }

  sentinelTargetConnected(el: Element): void {
    this.observer.observe(el)
  }

  sentinelTargetDisconnected(el: Element): void {
    this.observer.unobserve(el)
  }

  private async load(entries: IntersectionObserverEntry[]): Promise<void> {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue

      const url = (entry.target as HTMLElement).dataset.url
      if (!url) continue

      this.observer.unobserve(entry.target)

      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })

      if (response.ok) {
        renderStreamMessage(await response.text())
      }
    }
  }
}
