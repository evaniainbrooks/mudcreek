import "@hotwired/turbo-rails"
import "./controllers"
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
import "bootstrap"
import { Popover } from "bootstrap"
import "trix"
import "@rails/actiontext"

import { StreamActions, visit } from "@hotwired/turbo"
import { Offcanvas } from "bootstrap"

// Custom Turbo Stream action: <turbo-stream action="redirect" target="/path"></turbo-stream>
StreamActions["redirect"] = function(this: HTMLElement) {
  visit(this.getAttribute("target")!)
}

// Custom Turbo Stream action: <turbo-stream action="show_offcanvas" target="element-id"></turbo-stream>
StreamActions["show_offcanvas"] = function(this: HTMLElement) {
  const el = document.getElementById(this.getAttribute("target")!)
  if (el) Offcanvas.getOrCreateInstance(el).show()
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
  document.querySelectorAll<HTMLElement>("[data-bs-toggle='popover']").forEach(el => new Popover(el))
})
