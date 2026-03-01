import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["priceField", "pricingTypeField", "acquisitionPriceField", "quantityField", "ratePlansSection"]

  declare priceFieldTarget:            HTMLElement
  declare pricingTypeFieldTarget:      HTMLElement
  declare acquisitionPriceFieldTarget: HTMLElement
  declare quantityFieldTarget:         HTMLElement
  declare ratePlansSectionTarget:      HTMLElement

  toggle(event: Event): void {
    const isRental = (event.target as HTMLSelectElement).value === "rental"
    this.setHidden(this.priceFieldTarget,            isRental)
    this.setHidden(this.pricingTypeFieldTarget,      isRental)
    this.setHidden(this.acquisitionPriceFieldTarget, isRental)
    this.setHidden(this.quantityFieldTarget,         isRental)
    this.ratePlansSectionTarget.hidden = !isRental
  }

  private setHidden(el: HTMLElement, hidden: boolean): void {
    el.hidden = hidden
    el.querySelectorAll<HTMLInputElement | HTMLSelectElement>("input, select").forEach(input => {
      input.disabled = hidden
      input.required = !hidden && input.dataset.required === "true"
    })
  }
}
