import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deliverySelect", "placeOrderButton"]

  declare readonly deliverySelectTarget: HTMLSelectElement
  declare readonly placeOrderButtonTarget: HTMLButtonElement
  declare readonly hasDeliverySelectTarget: boolean

  connect(): void {
    this.updateButton()
  }

  updateButton(): void {
    if (!this.hasDeliverySelectTarget) return
    this.placeOrderButtonTarget.disabled = this.deliverySelectTarget.value === ""
  }
}
