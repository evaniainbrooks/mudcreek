import "@hotwired/turbo-rails"
import "./controllers"
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
import "bootstrap"
import "trix"
import "@rails/actiontext"

import { StreamActions, visit } from "@hotwired/turbo"

// Custom Turbo Stream action: <turbo-stream action="redirect" target="/path"></turbo-stream>
StreamActions["redirect"] = function(this: HTMLElement) {
  visit(this.getAttribute("target")!)
}

// Directional page transitions: set html[data-transition] before navigation
document.addEventListener("click", (event) => {
  const link = (event.target as HTMLElement).closest<HTMLElement>("a[data-transition]")
  if (link?.dataset.transition) {
    document.documentElement.dataset.transition = link.dataset.transition
  }
})
document.addEventListener("turbo:load", () => {
  delete document.documentElement.dataset.transition
})
