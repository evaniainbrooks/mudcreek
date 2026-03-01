import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"

export default class extends Controller {
  static values = { events: Array }

  declare eventsValue: object[]

  private calendar: Calendar | null = null
  private observer: IntersectionObserver | null = null

  connect(): void {
    this.calendar = new Calendar(this.element as HTMLElement, {
      plugins: [dayGridPlugin],
      initialView: "dayGridMonth",
      events: this.eventsValue,
      eventDisplay: "block",
      displayEventTime: false,
      height: "auto",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: ""
      }
    })
    this.calendar.render()

    this.observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        this.calendar?.updateSize()
      }
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
