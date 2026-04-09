import { Controller } from "@hotwired/stimulus"

export default class ListingPropertyController extends Controller {
  static targets = ["propertiesContainer", "rowTemplate"]
  static values  = { propertySetFieldsBase: String }

  declare propertiesContainerTarget: HTMLElement
  declare rowTemplateTarget: HTMLTemplateElement
  declare propertySetFieldsBaseValue: string

  addRow(event: Event) {
    event.preventDefault()
    const content = this.rowTemplateTarget.innerHTML.replace(/new_property/g, Date.now().toString())
    this.propertiesContainerTarget.insertAdjacentHTML("beforeend", content)
  }

  async applyPropertySet(event: Event) {
    const select = event.target as HTMLSelectElement
    const id = select.value
    if (!id) return

    select.value = ""

    const response = await fetch(`${this.propertySetFieldsBaseValue}/${id}/listing_fields`, {
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector<HTMLMetaElement>("meta[name=csrf-token]")?.content ?? ""
      }
    })

    const properties: Array<{ name: string; value: string; icon: string | null }> = await response.json()
    const base = Date.now()

    properties.forEach((prop, idx) => {
      const key  = `${base}${idx}`
      const html = this.rowTemplateTarget.innerHTML.replace(/new_property/g, key)

      const temp = document.createElement("template")
      temp.innerHTML = html

      const nameInput  = temp.content.querySelector<HTMLInputElement>(`[name*="[${key}]"][name$="[name]"]`)
      const valueInput = temp.content.querySelector<HTMLInputElement>(`[name*="[${key}]"][name$="[value]"]`)
      const iconInput  = temp.content.querySelector<HTMLInputElement>(`[name*="[${key}]"][name$="[icon]"]`)
      if (nameInput)  nameInput.value  = prop.name
      if (valueInput) valueInput.value = prop.value
      if (iconInput)  iconInput.value  = prop.icon ?? ""

      this.propertiesContainerTarget.appendChild(temp.content.cloneNode(true))
    })
  }
}
