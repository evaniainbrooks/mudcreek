import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "label", "dropdown", "search", "grid"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly previewTarget: HTMLElement
  declare readonly labelTarget: HTMLElement
  declare readonly dropdownTarget: HTMLElement
  declare readonly searchTarget: HTMLInputElement
  declare readonly gridTarget: HTMLElement

  private _outsideHandler!: (e: MouseEvent) => void

  connect() {
    this._outsideHandler = (e: MouseEvent) => {
      if (!this.element.contains(e.target as Node)) this.close()
    }
    document.addEventListener("click", this._outsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideHandler)
  }

  open() {
    this.dropdownTarget.classList.remove("d-none")
    this.searchTarget.value = ""
    this.filter()
    this.searchTarget.focus()
  }

  close() {
    this.dropdownTarget.classList.add("d-none")
  }

  select(event: Event) {
    const btn = event.currentTarget as HTMLElement
    const name = btn.dataset.name!
    const value = `bi-${name}`
    this.inputTarget.value = value
    this.previewTarget.className = `bi bi-${name}`
    this.labelTarget.textContent = value
    this.close()
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase()
    this.gridTarget.querySelectorAll<HTMLElement>(".icon-picker-item").forEach(btn => {
      const name = btn.dataset.name ?? ""
      btn.hidden = query.length > 0 && !name.includes(query)
    })
  }

  syncFromInput() {
    const value = this.inputTarget.value
    const name = value.replace(/^bi-/, "")
    this.previewTarget.className = value ? `bi bi-${name}` : "bi bi-image"
    this.labelTarget.textContent = value || "Choose icon…"
  }
}
