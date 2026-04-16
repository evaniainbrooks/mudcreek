import { Controller } from "@hotwired/stimulus"

export default class PageWidgetsController extends Controller {
  static targets = ["container", "rowTemplate"]

  declare containerTarget: HTMLElement
  declare rowTemplateTarget: HTMLTemplateElement

  addWidget(event: Event) {
    event.preventDefault()
    const content = this.rowTemplateTarget.innerHTML.replace(/new_widget/g, Date.now().toString())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    // Show the correct FK selector for the default type in the new row
    const lastRow = this.containerTarget.lastElementChild as HTMLElement
    const typeSelect = lastRow?.querySelector<HTMLSelectElement>("[data-widget-type-select]")
    if (typeSelect) this.syncTypeFields(lastRow, typeSelect.value)
  }

  removeWidget(event: Event) {
    event.preventDefault()
    const row = (event.target as HTMLElement).closest<HTMLElement>("[data-widget-row]")
    if (!row) return
    const destroyInput = row.querySelector<HTMLInputElement>("input[name*='[_destroy]']")
    if (destroyInput) {
      destroyInput.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }

  onTypeChange(event: Event) {
    const select = event.target as HTMLSelectElement
    const row = select.closest<HTMLElement>("[data-widget-row]")
    if (!row) return
    this.syncTypeFields(row, select.value)
  }

  private syncTypeFields(row: HTMLElement, selectedType: string) {
    row.querySelectorAll<HTMLElement>("[data-widget-type-fields]").forEach(el => {
      const types = el.dataset.widgetTypeFields?.split(" ") ?? []
      el.hidden = !types.includes(selectedType)
    })
  }
}
