import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["register", "pending", "approved", "highestBidder"]
  static values = { bidderToken: String }

  declare registerTarget: HTMLElement
  declare pendingTarget: HTMLElement
  declare approvedTarget: HTMLElement
  declare highestBidderTarget: HTMLElement
  declare bidderTokenValue: string

  connect(): void {
    const ancestor = this.element.closest<HTMLElement>("[data-registration-status]")
    const status = ancestor?.dataset.registrationStatus ?? "none"
    const currentUserToken = ancestor?.dataset.currentUserToken ?? ""

    this.registerTarget.hidden = status !== "none"
    this.pendingTarget.hidden = status !== "pending"
    this.approvedTarget.hidden = status !== "approved"

    const isHighestBidder =
      !!this.bidderTokenValue &&
      !!currentUserToken &&
      this.bidderTokenValue === currentUserToken

    this.highestBidderTarget.hidden = !isHighestBidder

    if (isHighestBidder) {
      const btn = this.approvedTarget.querySelector<HTMLButtonElement>("button[type='submit'], button:not([type])")
      if (btn) btn.disabled = true
    }
  }
}
