import { Controller } from "@hotwired/stimulus"

const SHRINK_ON_THRESHOLD  = 40   // px — scroll past here to apply compact style
const SHRINK_OFF_THRESHOLD = 8    // px — scroll back to here to remove compact style
const HIDE_THRESHOLD       = 60   // px — minimum scroll distance before hiding kicks in
const DIRECTION_DELTA      = 6    // px — ignore jitter smaller than this

export default class NavbarController extends Controller {
  private onScroll!: () => void
  private lastScrollY = 0

  connect() {
    this.lastScrollY = window.scrollY

    this.onScroll = () => {
      const current = window.scrollY
      const delta   = current - this.lastScrollY

      // Compact style on the navbar itself — hysteresis prevents feedback-loop jitter
      const isScrolled = this.element.classList.contains("navbar-scrolled")
      if (!isScrolled && current > SHRINK_ON_THRESHOLD) {
        this.element.classList.add("navbar-scrolled")
      } else if (isScrolled && current < SHRINK_OFF_THRESHOLD) {
        this.element.classList.remove("navbar-scrolled")
      }

      // Hide/show the entire sticky header (notice + navbar together)
      if (current < HIDE_THRESHOLD) {
        this.header.classList.remove("header-hidden")
        this.lastScrollY = current
      } else if (delta > DIRECTION_DELTA) {
        this.header.classList.add("header-hidden")
        this.lastScrollY = current
      } else if (delta < -DIRECTION_DELTA) {
        this.header.classList.remove("header-hidden")
        this.lastScrollY = current
      }
    }

    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  private get header(): HTMLElement {
    return (this.element.closest<HTMLElement>(".sticky-header") ?? this.element) as HTMLElement
  }
}
