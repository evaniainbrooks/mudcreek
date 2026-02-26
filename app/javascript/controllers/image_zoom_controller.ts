import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["level"]
  static values = {
    scale: { type: Number, default: 1 },
    step:  { type: Number, default: 0.25 },
    max:   { type: Number, default: 3 },
  }

  declare levelTarget: HTMLElement
  declare hasLevelTarget: boolean
  declare scaleValue: number
  declare stepValue: number
  declare maxValue: number

  private slideHandler!: () => void

  connect(): void {
    this.slideHandler = this.reset.bind(this)
    this.element.addEventListener("slide.bs.carousel", this.slideHandler)
  }

  disconnect(): void {
    this.element.removeEventListener("slide.bs.carousel", this.slideHandler)
  }

  track(event: MouseEvent): void {
    if (this.scaleValue === 1) return
    const img = this.activeImage
    if (!img) return
    const rect = img.getBoundingClientRect()
    const x = ((event.clientX - rect.left) / rect.width) * 100
    const y = ((event.clientY - rect.top) / rect.height) * 100
    img.style.transformOrigin = `${x}% ${y}%`
  }

  zoomIn(): void {
    this.scaleValue = Math.min(+(this.scaleValue + this.stepValue).toFixed(10), this.maxValue)
  }

  zoomOut(): void {
    this.scaleValue = Math.max(+(this.scaleValue - this.stepValue).toFixed(10), 1)
  }

  reset(): void {
    this.scaleValue = 1
  }

  scaleValueChanged(): void {
    const img = this.activeImage
    if (!img) return

    if (this.scaleValue <= 1) {
      img.style.transform = ""
      img.style.transformOrigin = ""
      img.style.cursor = ""
    } else {
      img.style.transform = `scale(${this.scaleValue})`
      img.style.cursor = "crosshair"
    }

    if (this.hasLevelTarget) {
      this.levelTarget.textContent = `${Math.round(this.scaleValue * 100)}%`
      this.levelTarget.style.visibility = this.scaleValue > 1 ? "visible" : "hidden"
    }
  }

  private get activeImage(): HTMLImageElement | null {
    return this.element.querySelector<HTMLImageElement>(".carousel-item.active img")
  }
}
