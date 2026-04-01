import { Controller } from "@hotwired/stimulus"

const SHRINK_THRESHOLD = 8    // px — when to apply the compact style
const HIDE_THRESHOLD   = 60   // px — minimum scroll distance before hiding kicks in
const DIRECTION_DELTA  = 6    // px — ignore jitter smaller than this

export default class NavbarController extends Controller {
  private onScroll!: () => void
  private lastScrollY = 0

  connect() {
    this.lastScrollY = window.scrollY

    this.onScroll = () => {
      const current = window.scrollY
      const delta   = current - this.lastScrollY

      // Compact style
      this.element.classList.toggle("navbar-scrolled", current > SHRINK_THRESHOLD)

      // Hide/show based on scroll direction — only past the threshold.
      // lastScrollY is only updated when action is taken, so delta accumulates
      // across events and small per-frame jitter never crosses the threshold.
      if (current < HIDE_THRESHOLD) {
        // Always visible near the top
        this.element.classList.remove("navbar-hidden")
        this.lastScrollY = current
      } else if (delta > DIRECTION_DELTA) {
        // Scrolling down — hide
        this.element.classList.add("navbar-hidden")
        this.lastScrollY = current
      } else if (delta < -DIRECTION_DELTA) {
        // Scrolling up — show
        this.element.classList.remove("navbar-hidden")
        this.lastScrollY = current
      }
      // If delta is within the dead zone, don't update lastScrollY so it accumulates
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
