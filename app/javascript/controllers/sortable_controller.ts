import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { url: String }
  declare urlValue: string

  connect() {
    Sortable.create(this.element as HTMLElement, {
      handle: ".sortable-handle",
      animation: 150,
      onEnd: this.onEnd
    })
  }

  private onEnd = (event: Sortable.SortableEvent) => {
    const id = (event.item as HTMLElement).dataset.id
    const position = event.newIndex! + 1

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector<HTMLMetaElement>("meta[name=csrf-token]")?.content ?? ""
      },
      body: JSON.stringify({ id, position })
    })
  }
}
