import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["carousel", "zoomControls"]

  declare carouselTarget: HTMLElement
  declare zoomControlsTarget: HTMLElement

  connect() {
    this.updateControls()
    this.carouselTarget.addEventListener("slide.bs.carousel", this.onSlide)
    this.carouselTarget.addEventListener("slid.bs.carousel", this.onSlid)
  }

  disconnect() {
    this.carouselTarget.removeEventListener("slide.bs.carousel", this.onSlide)
    this.carouselTarget.removeEventListener("slid.bs.carousel", this.onSlid)
  }

  private onSlide = () => {
    this.pauseVideos()
  }

  private onSlid = () => {
    this.updateControls()
  }

  private updateControls() {
    const active = this.carouselTarget.querySelector<HTMLElement>(".carousel-item.active")
    const isVideo = !!active?.querySelector("video")

    this.carouselTarget.querySelectorAll<HTMLElement>(".carousel-control-prev, .carousel-control-next").forEach(control => {
      control.style.visibility = isVideo ? "hidden" : ""
    })

    this.zoomControlsTarget.style.visibility = isVideo ? "hidden" : ""
  }

  private pauseVideos() {
    this.carouselTarget.querySelectorAll<HTMLVideoElement>("video").forEach(v => v.pause())
  }
}
