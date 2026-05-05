import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["optionSelect"]
  static values  = { galleryUrl: String }

  declare optionSelectTargets: HTMLSelectElement[]
  declare galleryUrlValue: string

  connect() {
    if (this.optionSelectTargets.length > 0) this.updateGallery()
  }

  updateGallery() {
    const frame = document.getElementById("variant-gallery")
    if (!frame) return

    const url = new URL(this.galleryUrlValue, window.location.origin)
    this.optionSelectTargets.forEach(select => {
      const match = select.name.match(/option_values\[(\d+)\]/)
      if (match && select.value) url.searchParams.append(`option_values[${match[1]}]`, select.value)
    })
    frame.setAttribute("src", url.toString())
  }
}
