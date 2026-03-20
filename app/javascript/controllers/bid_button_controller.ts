import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["signIn", "register", "pending", "approved", "highestBidder", "outbid"]
  static values = { bidderToken: String }

  declare signInTarget: HTMLElement
  declare registerTarget: HTMLElement
  declare pendingTarget: HTMLElement
  declare approvedTarget: HTMLElement
  declare highestBidderTarget: HTMLElement
  declare outbidTarget: HTMLElement
  declare bidderTokenValue: string

  connect(): void {
    const ancestor = this.element.closest<HTMLElement>("[data-registration-status]")
    const status = ancestor?.dataset.registrationStatus ?? "unauthenticated"
    const currentUserToken = ancestor?.dataset.currentUserToken ?? ""
    const wasHighestBidder = ancestor?.dataset.wasHighestBidder === "true"

    this.signInTarget.hidden = status !== "unauthenticated"
    this.registerTarget.hidden = status !== "none"
    this.pendingTarget.hidden = status !== "pending"
    this.approvedTarget.hidden = status !== "approved"

    const isHighestBidder =
      !!this.bidderTokenValue &&
      !!currentUserToken &&
      this.bidderTokenValue === currentUserToken

    this.highestBidderTarget.hidden = !isHighestBidder
    this.outbidTarget.hidden = isHighestBidder || !wasHighestBidder

    // Persist highest-bidder status on the ancestor so it survives DOM replacement.
    // Once true, keep true until the user is highest bidder again (no-op) or they're
    // outbid — in that case we leave it true so the outbid message keeps showing.
    if (ancestor) {
      ancestor.dataset.wasHighestBidder = (isHighestBidder || wasHighestBidder).toString()
    }

    if (isHighestBidder) {
      const btn = this.approvedTarget.querySelector<HTMLButtonElement>("button[type='submit'], button:not([type])")
      if (btn) btn.disabled = true
    }
  }
}
