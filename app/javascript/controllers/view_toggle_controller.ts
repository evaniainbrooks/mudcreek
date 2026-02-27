import { Controller } from "@hotwired/stimulus"

type ViewMode = "small" | "large" | "list"

const GRID_CLASSES: Record<ViewMode, string> = {
  small: "row row-cols-1 row-cols-sm-2 row-cols-md-3 row-cols-lg-4 g-4",
  large: "row row-cols-1 row-cols-sm-2 g-4",
  list: "d-flex flex-column gap-3",
}

const STORAGE_KEY = "listings-view-mode"

export default class extends Controller {
  static targets = ["grid", "select"]

  declare gridTarget: HTMLElement
  declare selectTarget: HTMLSelectElement

  connect(): void {
    const saved = (localStorage.getItem(STORAGE_KEY) as ViewMode) || "small"
    this.applyMode(saved)
    this.selectTarget.value = saved
  }

  change(event: Event): void {
    const mode = (event.target as HTMLSelectElement).value as ViewMode
    this.applyMode(mode)
    localStorage.setItem(STORAGE_KEY, mode)
  }

  private applyMode(mode: ViewMode): void {
    const grid = this.gridTarget
    const allClasses = Object.values(GRID_CLASSES).flatMap(cls => cls.split(" "))
    allClasses.forEach(cls => grid.classList.remove(cls))
    const classes = GRID_CLASSES[mode] ?? GRID_CLASSES.small
    classes.split(" ").forEach(cls => grid.classList.add(cls))
    grid.dataset.viewMode = mode
  }
}
