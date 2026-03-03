import { Controller } from "@hotwired/stimulus"

declare const Square: any

export default class extends Controller {
  static targets = ["container", "errorMessage"]
  static values  = { applicationId: String, locationId: String, paymentUrl: String, csrfToken: String }

  declare readonly containerTarget:    HTMLElement
  declare readonly errorMessageTarget: HTMLElement
  declare applicationIdValue:          string
  declare locationIdValue:             string
  declare paymentUrlValue:             string
  declare csrfTokenValue:              string

  private card: any = null

  async connect(): Promise<void> {
    if (typeof Square === "undefined") {
      this.showError("Square payments are unavailable. Please refresh the page.")
      return
    }
    const payments = Square.payments(this.applicationIdValue, this.locationIdValue)
    this.card = await payments.card()
    await this.card.attach(this.containerTarget)
  }

  async submit(event: Event): Promise<void> {
    event.preventDefault()
    if (!this.card) { this.showError("Payment form not ready."); return }
    this.clearError()

    const result = await this.card.tokenize()

    if (result.status === "OK") {
      const form        = document.createElement("form")
      form.method       = "POST"
      form.action       = this.paymentUrlValue
      form.innerHTML    = `
        <input type="hidden" name="authenticity_token" value="${this.csrfTokenValue}">
        <input type="hidden" name="source_id" value="${result.token}">
      `
      document.body.appendChild(form)
      form.submit()
    } else {
      const msg = result.errors?.map((e: any) => e.message).join(", ") ?? "Tokenization failed."
      this.showError(msg)
    }
  }

  private showError(msg: string): void {
    this.errorMessageTarget.textContent = msg
    this.errorMessageTarget.hidden = false
  }

  private clearError(): void {
    this.errorMessageTarget.textContent = ""
    this.errorMessageTarget.hidden = true
  }
}
