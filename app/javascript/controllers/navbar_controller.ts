import { Controller } from "@hotwired/stimulus"

export default class NavbarController extends Controller {
  private onScroll!: () => void

  connect() {
    this.onScroll = () => {
      this.element.classList.toggle("navbar-scrolled", window.scrollY > 8)
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.updateOffset()
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    document.documentElement.style.removeProperty("--navbar-height")
  }

  private updateOffset() {
    const height = (this.element as HTMLElement).offsetHeight
    document.documentElement.style.setProperty("--navbar-height", `${height}px`)
  }
}
