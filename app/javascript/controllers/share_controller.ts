import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

export default class extends Controller {
  static values  = { url: String }
  static targets = ["toast"]

  declare urlValue:   string
  declare toastTarget: HTMLElement

  async copy() {
    if (navigator.clipboard) {
      await navigator.clipboard.writeText(this.urlValue)
    } else {
      const el = document.createElement("textarea")
      el.value = this.urlValue
      el.style.position = "fixed"
      el.style.opacity  = "0"
      document.body.appendChild(el)
      el.select()
      document.execCommand("copy")
      document.body.removeChild(el)
    }

    new Toast(this.toastTarget).show()
  }
}
