import { Controller } from "@hotwired/stimulus"
import type {
  Payments,
  Card,
  TokenResult,
  TokenError
} from "@square/web-payments-sdk"

declare global {
  interface Window {
    Square?: {
      payments(applicationId: string, locationId: string): Payments
    }
  }
}

export default class extends Controller {
  static targets = ["container", "errorMessage"]
  static values = {
    applicationId: String,
    locationId: String,
    saveUrl: String,
    csrfToken: String
  }

  declare readonly containerTarget: HTMLElement
  declare readonly errorMessageTarget: HTMLElement
  declare applicationIdValue: string
  declare locationIdValue: string
  declare saveUrlValue: string
  declare csrfTokenValue: string

  private card: Card | null = null

  async connect(): Promise<void> {
    const Square = await this.loadSquare()

    if (!Square) {
      this.showError("Square payments are unavailable. Please refresh the page.")
      return
    }

    const payments = Square.payments(
      this.applicationIdValue,
      this.locationIdValue
    )

    this.card = await payments.card()
    await this.card.attach(this.containerTarget)
  }

  private loadSquare(): Promise<typeof window.Square> {
    if (window.Square) return Promise.resolve(window.Square)

    return new Promise((resolve) => {
      const script = document.querySelector<HTMLScriptElement>('script[src*="squarecdn.com"]')
      if (!script) {
        resolve(undefined)
        return
      }
      script.addEventListener("load", () => resolve(window.Square))
      script.addEventListener("error", () => resolve(undefined))
    })
  }

  async submit(event: Event): Promise<void> {
    event.preventDefault()

    if (!this.card) {
      this.showError("Card form not ready.")
      return
    }

    this.clearError()

    const result: TokenResult = await this.card.tokenize()

    if (result.status === "OK") {
      const form = document.createElement("form")
      form.method = "POST"
      form.action = this.saveUrlValue

      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = this.csrfTokenValue
      form.appendChild(csrfInput)

      const sourceInput = document.createElement("input")
      sourceInput.type = "hidden"
      sourceInput.name = "source_id"
      sourceInput.value = result.token!
      form.appendChild(sourceInput)

      document.body.appendChild(form)
      form.submit()
    } else {
      const msg =
        result.errors
          ?.map((e: TokenError) => e.message)
          .join(", ") ?? "Tokenization failed."

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
