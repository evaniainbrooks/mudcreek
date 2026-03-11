import { Controller } from "@hotwired/stimulus"

export default class ListingPropertyController extends Controller {
  static targets = ["propertiesContainer", "rowTemplate"]

  declare propertiesContainerTarget: HTMLElement
  declare rowTemplateTarget: HTMLTemplateElement

  addRow(event: Event) {
    event.preventDefault()
    const content = this.rowTemplateTarget.innerHTML.replace(/new_property/g, Date.now().toString())
    this.propertiesContainerTarget.insertAdjacentHTML("beforeend", content)
  }
}
