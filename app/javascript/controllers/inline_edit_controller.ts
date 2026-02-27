import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]

  declare displayTarget: HTMLElement
  declare formTarget: HTMLElement
  declare inputTarget: HTMLInputElement

  edit() {
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    this.inputTarget.value = this.displayTarget.dataset.value ?? ""
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }

  keydown(event: KeyboardEvent) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.inputTarget.closest("form")?.requestSubmit()
    } else if (event.key === "Escape") {
      this.cancel()
    }
  }

}
