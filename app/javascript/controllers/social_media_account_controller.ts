import { Controller } from "@hotwired/stimulus"

const PLATFORM_ICONS: Record<string, string> = {
  facebook:  "bi-facebook",
  instagram: "bi-instagram",
  youtube:   "bi-youtube",
  twitter:   "bi-twitter-x",
  tiktok:    "bi-tiktok",
  snapchat:  "bi-snapchat",
  linkedin:  "bi-linkedin",
  discord:   "bi-discord",
  patreon:   "bi-patreon",
  onlyfans:  "bi-person-heart",
  twitch:    "bi-twitch",
}

export default class SocialMediaAccountController extends Controller {
  static targets = ["accountsContainer", "accountTemplate", "iconField"]

  declare accountsContainerTarget: HTMLElement
  declare accountTemplateTarget: HTMLTemplateElement
  declare iconFieldTargets: HTMLInputElement[]

  addAccount(event: Event) {
    event.preventDefault()
    const content = this.accountTemplateTarget.innerHTML.replace(/new_account/g, Date.now().toString())
    this.accountsContainerTarget.insertAdjacentHTML("beforeend", content)
  }

  fillIcon(event: Event) {
    const select = event.target as HTMLSelectElement
    const platform = select.value
    const row = select.closest(".d-flex")
    if (!row) return
    const iconField = row.querySelector<HTMLInputElement>("[data-social-media-account-target='iconField']")
    if (iconField && !iconField.value && platform) {
      iconField.value = PLATFORM_ICONS[platform] ?? ""
      iconField.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
