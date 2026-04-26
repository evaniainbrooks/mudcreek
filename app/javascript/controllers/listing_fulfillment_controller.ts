import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["creditsRow", "subscriptionRow"]

  declare creditsRowTarget: HTMLElement
  declare subscriptionRowTarget: HTMLElement

  update(event: Event) {
    const value = (event.target as HTMLInputElement).value
    this.creditsRowTarget.style.display      = value === "credits"      ? "" : "none"
    this.subscriptionRowTarget.style.display = value === "subscription" ? "" : "none"
  }
}
