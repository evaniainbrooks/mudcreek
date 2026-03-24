import { Controller } from "@hotwired/stimulus"

export default class ListingOptionController extends Controller {
  static targets = ["valuesContainer", "valueTemplate"]

  declare valuesContainerTarget: HTMLElement
  declare valueTemplateTarget: HTMLTemplateElement

  addValue(event: Event) {
    event.preventDefault()
    const content = this.valueTemplateTarget.innerHTML.replace(/new_value/g, Date.now().toString())
    this.valuesContainerTarget.insertAdjacentHTML("beforeend", content)
  }
}
