import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitBtn", "receiptBtn", "receiptLabel"]

  declare submitBtnTarget:   HTMLElement
  declare receiptBtnTarget:  HTMLElement
  declare receiptLabelTarget: HTMLElement

  syncSubmit(event: Event): void {
    const radio = event.target as HTMLInputElement
    if (radio.value === "credit") {
      this.submitBtnTarget.classList.remove("submit-debit")
      this.submitBtnTarget.classList.add("submit-credit")
    } else {
      this.submitBtnTarget.classList.remove("submit-credit")
      this.submitBtnTarget.classList.add("submit-debit")
    }
  }

  receiptChanged(event: Event): void {
    const input = event.target as HTMLInputElement
    if (input.files && input.files.length > 0) {
      this.receiptLabelTarget.textContent = input.files[0].name
      this.receiptBtnTarget.classList.add("receipt-btn--selected")
    } else {
      this.receiptLabelTarget.textContent = "Add Receipt Photo"
      this.receiptBtnTarget.classList.remove("receipt-btn--selected")
    }
  }
}
