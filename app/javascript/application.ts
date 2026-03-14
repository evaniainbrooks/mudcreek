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
