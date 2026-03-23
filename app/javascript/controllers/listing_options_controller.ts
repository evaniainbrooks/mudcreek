import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["optionsContainer", "optionTemplate", "optionRow",
                    "destroyField", "valuesContainer", "valueTemplate",
                    "valueRow", "valueDestroyField"]

  declare optionsContainerTarget: HTMLElement
  declare optionTemplateTarget: HTMLTemplateElement
  declare optionRowTargets: HTMLElement[]
  declare valuesContainerTargets: HTMLElement[]
  declare valueTemplateTargets: HTMLTemplateElement[]

  addOption(event: Event) {
    event.preventDefault()
    const timestamp = new Date().getTime()
    const template = this.optionTemplateTarget.innerHTML
      .replace(/new_option/g, `option_${timestamp}`)
    const wrapper = document.createElement("div")
    wrapper.innerHTML = template
    this.optionsContainerTarget.appendChild(wrapper.firstElementChild!)
  }

  removeOption(event: Event) {
    event.preventDefault()
    const btn = event.currentTarget as HTMLElement
    const row = btn.closest("[data-listing-options-target~='optionRow']") as HTMLElement
    const destroyField = row.querySelector<HTMLInputElement>("[data-listing-options-target~='destroyField']")
    if (destroyField) {
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }

  addValue(event: Event) {
    event.preventDefault()
    const btn = event.currentTarget as HTMLElement
    const optionRow = btn.closest("[data-listing-options-target~='optionRow']") as HTMLElement
    const valuesContainer = optionRow.querySelector("[data-listing-options-target~='valuesContainer']") as HTMLElement
    const template = optionRow.querySelector<HTMLTemplateElement>("[data-listing-options-target~='valueTemplate']")!
    const timestamp = new Date().getTime()
    const html = template.innerHTML.replace(/new_value/g, `value_${timestamp}`)
    const wrapper = document.createElement("div")
    wrapper.innerHTML = html
    valuesContainer.appendChild(wrapper.firstElementChild!)
  }

  removeValue(event: Event) {
    event.preventDefault()
    const btn = event.currentTarget as HTMLElement
    const row = btn.closest("[data-listing-options-target~='valueRow']") as HTMLElement
    const destroyField = row.querySelector<HTMLInputElement>("[data-listing-options-target~='valueDestroyField']")
    if (destroyField) {
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
