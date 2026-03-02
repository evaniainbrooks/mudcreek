import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "actionBar", "count", "form"]

  declare checkboxTargets: HTMLInputElement[]
  declare selectAllTarget: HTMLInputElement
  declare actionBarTarget: HTMLElement
  declare countTarget: HTMLElement
  declare formTarget: HTMLFormElement

  toggle() {
    this.updateState()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => { cb.checked = checked })
    this.updateState()
  }

  submit(event: Event) {
    event.preventDefault()

    const checkedIds = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    if (checkedIds.length === 0) return

    // Remove any previously injected hidden inputs
    this.formTarget.querySelectorAll("input[name='listing_ids[]']").forEach(el => el.remove())

    checkedIds.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "listing_ids[]"
      input.value = id
      this.formTarget.appendChild(input)
    })

    this.formTarget.requestSubmit()
  }

  private updateState() {
    const total = this.checkboxTargets.length
    const checked = this.checkboxTargets.filter(cb => cb.checked).length

    this.countTarget.textContent = `${checked} selected`
    this.actionBarTarget.hidden = checked === 0
    this.selectAllTarget.checked = checked === total && total > 0
    this.selectAllTarget.indeterminate = checked > 0 && checked < total
  }
}
