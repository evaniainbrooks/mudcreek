import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parentSelect", "topLevelOnly"]

  declare parentSelectTarget: HTMLSelectElement
  declare topLevelOnlyTargets: HTMLElement[]

  connect(): void {
    this.toggle()
  }

  toggle(): void {
    const isChild = this.parentSelectTarget.value !== ""
    this.topLevelOnlyTargets.forEach(el => { el.hidden = isChild })
  }
}
