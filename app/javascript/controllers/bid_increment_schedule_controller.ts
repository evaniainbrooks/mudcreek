import { Controller } from "@hotwired/stimulus"

export default class BidIncrementScheduleController extends Controller {
  static targets = ["tiersContainer", "tierTemplate"]

  declare tiersContainerTarget: HTMLElement
  declare tierTemplateTarget: HTMLTemplateElement

  addTier(event: Event) {
    event.preventDefault()
    const template = this.tierTemplateTarget
    const content = template.innerHTML.replace(/new_tier/g, `new_${Date.now()}`)
    this.tiersContainerTarget.insertAdjacentHTML("beforeend", content)
  }
}
