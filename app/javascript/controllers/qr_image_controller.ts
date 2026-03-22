import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

export default class extends Controller {
  static targets = ["preview", "downloadBtn", "sizeLabel", "formatLabel", "styleLabel", "toast"]
  static values  = {
    baseUrl: String,
    size:    { type: String, default: "md" },
    format:  { type: String, default: "png" },
    style:   { type: String, default: "standard" },
  }

  declare previewTarget:     HTMLImageElement
  declare downloadBtnTarget: HTMLAnchorElement
  declare sizeLabelTarget:   HTMLElement
  declare formatLabelTarget: HTMLElement
  declare styleLabelTarget:  HTMLElement
  declare toastTarget:       HTMLElement
  declare baseUrlValue:      string
  declare sizeValue:         string
  declare formatValue:       string
  declare styleValue:        string

  selectSize(event: Event) {
    const btn = event.currentTarget as HTMLElement
    this.sizeValue = btn.dataset.size!
    this.sizeLabelTarget.textContent = btn.textContent!.trim()
  }

  selectFormat(event: Event) {
    const btn = event.currentTarget as HTMLElement
    this.formatValue = btn.dataset.format!
    this.formatLabelTarget.textContent = btn.textContent!.trim()
  }

  selectStyle(event: Event) {
    const btn = event.currentTarget as HTMLElement
    this.styleValue = btn.dataset.qrStyle!
    this.styleLabelTarget.textContent = btn.textContent!.trim()
  }

  sizeValueChanged()   { this.update() }
  formatValueChanged() { this.update() }
  styleValueChanged()  { this.update() }

  async copyUrl() {
    const url = this.imageUrl(false)

    if (navigator.clipboard) {
      await navigator.clipboard.writeText(url)
    } else {
      const el = document.createElement("textarea")
      el.value = url
      el.style.cssText = "position:fixed;opacity:0"
      document.body.appendChild(el)
      el.select()
      document.execCommand("copy")
      document.body.removeChild(el)
    }

    new Toast(this.toastTarget).show()
  }

  private update() {
    this.previewTarget.src     = this.svgPreviewUrl()
    this.downloadBtnTarget.href = this.imageUrl(true)
  }

  private svgPreviewUrl() {
    const url = new URL(`${this.baseUrlValue}.svg`, window.location.origin)
    url.searchParams.set("size",  this.sizeValue)
    url.searchParams.set("style", this.styleValue)
    return url.toString()
  }

  private imageUrl(download: boolean) {
    const ext = this.formatValue
    const url  = new URL(`${this.baseUrlValue}.${ext}`, window.location.origin)
    url.searchParams.set("size",  this.sizeValue)
    url.searchParams.set("style", this.styleValue)
    if (download && ext === "svg") url.searchParams.set("download", "1")
    return url.toString()
  }
}
