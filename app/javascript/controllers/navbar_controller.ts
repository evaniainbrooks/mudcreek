import { Controller } from "@hotwired/stimulus"

export default class NavbarController extends Controller {
  private onScroll!: () => void

  connect() {
    this.onScroll = () => {
      this.element.classList.toggle("navbar-scrolled", window.scrollY > 8)
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    document.body.style.paddingTop = `${(this.element as HTMLElement).offsetHeight}px`
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    document.body.style.paddingTop = ""
  }
}
