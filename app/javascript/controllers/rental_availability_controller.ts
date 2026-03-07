import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static values = { events: Array }
  declare eventsValue: object[]

  private calendar: Calendar | null = null
  private observer: IntersectionObserver | null = null

  connect(): void {
    this.calendar = new Calendar(this.element as HTMLElement, {
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      events: this.eventsValue,
      eventDisplay: "block",
      displayEventTime: false,
      height: "auto",
      selectable: true,
      headerToolbar: { left: "prev,next today", center: "title", right: "" },
      select: (info) => {
        const fmt = (d: Date) => d.toISOString().slice(0, 16)
        // info.end is exclusive (next day midnight); subtract 1 min for inclusive feel
        const end = new Date(info.end.getTime() - 60000)
        this.dispatch("dateSelected", {
          detail: { start: fmt(info.start), end: fmt(end) },
          bubbles: true
        })
      }
    })
    this.calendar.render()

    // Re-size when Bootstrap modal becomes visible (starts hidden)
    this.observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) this.calendar?.updateSize()
    })
    this.observer.observe(this.element)
  }

  disconnect(): void {
    this.observer?.disconnect()
    this.observer = null
    this.calendar?.destroy()
    this.calendar = null
  }
}
