import { Controller } from "@hotwired/stimulus"

const INTERVAL_UNITS: Record<string, string> = {
  DAILY: "days",
  WEEKLY: "weeks",
  MONTHLY: "months",
  YEARLY: "years",
}

export default class extends Controller {
  static targets = ["freq", "intervalRow", "interval", "intervalUnit", "bydayRow", "advancedToggle", "rawRow"]

  declare freqTarget: HTMLSelectElement
  declare intervalRowTarget: HTMLElement
  declare intervalTarget: HTMLInputElement
  declare intervalUnitTarget: HTMLElement
  declare bydayRowTarget: HTMLElement
  declare advancedToggleTarget: HTMLInputElement
  declare rawRowTarget: HTMLElement

  connect(): void {
    this.update()
  }

  update(): void {
    const freq     = this.freqTarget.value
    const advanced = this.advancedToggleTarget.checked
    const hasFreq  = freq !== ""

    this.toggle(this.intervalRowTarget, hasFreq && !advanced)
    this.toggle(this.bydayRowTarget, freq === "WEEKLY" && !advanced)
    this.toggle(this.rawRowTarget, advanced)

    this.intervalUnitTarget.textContent = INTERVAL_UNITS[freq] ?? "days"
  }

  private toggle(el: HTMLElement, show: boolean): void {
    el.style.display = show ? "" : "none"
  }
}
