import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "subdivision", "subdivisionWrapper"]

  declare countryTarget: HTMLSelectElement
  declare subdivisionTarget: HTMLSelectElement
  declare subdivisionWrapperTarget: HTMLElement

  async countryChanged() {
    const code = this.countryTarget.value

    if (!code) {
      this.hideSubdivision()
      return
    }

    const res = await fetch(`/subdivisions?country_code=${encodeURIComponent(code)}`)
    const names: string[] = await res.json()

    if (names.length === 0) {
      this.hideSubdivision()
      return
    }

    this.subdivisionWrapperTarget.hidden = false
    this.subdivisionTarget.required = true
    this.subdivisionTarget.innerHTML =
      '<option value="">Select…</option>' +
      names.map(name => `<option value="${name}">${name}</option>`).join("")
  }

  private hideSubdivision() {
    this.subdivisionWrapperTarget.hidden = true
    this.subdivisionTarget.required = false
    this.subdivisionTarget.innerHTML = ""
  }
}
