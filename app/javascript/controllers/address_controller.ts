import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "subdivision", "subdivisionWrapper"]

  declare countryTarget: HTMLSelectElement
  declare subdivisionTarget: HTMLSelectElement
  declare subdivisionWrapperTarget: HTMLElement

  async countryChanged() {
    const code = this.countryTarget.value

    if (!code) {
      this.subdivisionWrapperTarget.hidden = true
      this.subdivisionTarget.innerHTML = ""
      return
    }

    const res = await fetch(`/subdivisions?country_code=${encodeURIComponent(code)}`)
    const names: string[] = await res.json()

    if (names.length === 0) {
      this.subdivisionWrapperTarget.hidden = true
      this.subdivisionTarget.innerHTML = ""
      return
    }

    this.subdivisionWrapperTarget.hidden = false
    this.subdivisionTarget.innerHTML =
      '<option value="">Select…</option>' +
      names.map(name => `<option value="${name}">${name}</option>`).join("")
  }
}
