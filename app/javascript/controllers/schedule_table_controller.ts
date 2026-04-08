import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { todayCol: Number }
  static targets = ["col", "colHeader", "expandBtn"]

  declare todayColValue: number
  declare colTargets: HTMLElement[]
  declare colHeaderTargets: HTMLElement[]
  declare expandBtnTarget: HTMLElement
  declare hasExpandBtnTarget: boolean

  private expandedAll = false
  private mq = window.matchMedia("(max-width: 767px)")

  connect(): void {
    if (this.mq.matches) this.resetToDefault()
    this.mq.addEventListener("change", this.onBreakpoint)
  }

  disconnect(): void {
    this.mq.removeEventListener("change", this.onBreakpoint)
  }

  toggleCol(event: Event): void {
    if (!this.mq.matches) return
    const header = event.currentTarget as HTMLElement
    const col = parseInt(header.dataset.col ?? "-1", 10)
    if (!this.isCollapsed(col)) return
    // Collapse all, then expand only the tapped column
    this.collapseAll()
    this.expand(col)
    this.expandedAll = false
    this.syncBtn()
  }

  toggleAll(): void {
    if (this.expandedAll) {
      this.expandedAll = false
      this.resetToDefault()
    } else {
      this.expandedAll = true
      this.colHeaderTargets.forEach((_, i) => this.expand(i))
    }
    this.syncBtn()
  }

  private onBreakpoint = (e: MediaQueryListEvent): void => {
    if (e.matches) {
      this.expandedAll = false
      this.resetToDefault()
    } else {
      this.colHeaderTargets.forEach((_, i) => this.expand(i))
    }
  }

  private resetToDefault(): void {
    this.colHeaderTargets.forEach((_, i) => {
      if (i === this.todayColValue) {
        this.expand(i)
      } else {
        this.collapse(i)
      }
    })
    this.syncBtn()
  }

  private collapseAll(): void {
    this.colHeaderTargets.forEach((_, i) => this.collapse(i))
  }

  private isCollapsed(col: number): boolean {
    return this.colHeaderTargets[col]?.classList.contains("sched-col-collapsed") ?? false
  }

  private collapse(col: number): void {
    if (col < 0 || col >= this.colTargets.length) return
    this.colTargets[col].style.width = "2rem"
    this.colHeaderTargets[col]?.classList.add("sched-col-collapsed")
    this.element.querySelectorAll<HTMLElement>(`td[data-col="${col}"]`).forEach(el =>
      el.classList.add("sched-col-collapsed")
    )
  }

  private expand(col: number): void {
    if (col < 0 || col >= this.colTargets.length) return
    this.colTargets[col].style.removeProperty("width")
    this.colHeaderTargets[col]?.classList.remove("sched-col-collapsed")
    this.element.querySelectorAll<HTMLElement>(`td[data-col="${col}"]`).forEach(el =>
      el.classList.remove("sched-col-collapsed")
    )
  }

  private syncBtn(): void {
    if (this.hasExpandBtnTarget) {
      this.expandBtnTarget.textContent = this.expandedAll ? "Collapse" : "Expand all"
    }
  }
}
