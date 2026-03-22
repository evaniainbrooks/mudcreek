import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["progressContainer"]
  declare progressContainerTarget: HTMLElement

  private uploads = new Map<number, HTMLElement>()

  connect() {
    this.element.addEventListener("direct-upload:initialize", this.onInit)
    this.element.addEventListener("direct-upload:progress", this.onProgress)
    this.element.addEventListener("direct-upload:error", this.onError)
    this.element.addEventListener("direct-upload:end", this.onEnd)
  }

  disconnect() {
    this.element.removeEventListener("direct-upload:initialize", this.onInit)
    this.element.removeEventListener("direct-upload:progress", this.onProgress)
    this.element.removeEventListener("direct-upload:error", this.onError)
    this.element.removeEventListener("direct-upload:end", this.onEnd)
  }

  private onInit = (event: Event) => {
    const { id, file } = (event as CustomEvent).detail
    const item = document.createElement("div")
    item.className = "mb-2"
    item.innerHTML = `
      <div class="d-flex justify-content-between small mb-1">
        <span class="text-truncate me-2">${this.escape(file.name)}</span>
        <span class="text-muted">0%</span>
      </div>
      <div class="progress" style="height:5px">
        <div class="progress-bar progress-bar-striped progress-bar-animated"
             style="width:0%" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
      </div>`
    this.progressContainerTarget.appendChild(item)
    this.progressContainerTarget.hidden = false
    this.uploads.set(id, item)
  }

  private onProgress = (event: Event) => {
    const { id, progress } = (event as CustomEvent).detail
    const item = this.uploads.get(id)
    if (!item) return
    item.querySelector<HTMLElement>(".progress-bar")!.style.width = `${progress}%`
    item.querySelector<HTMLElement>(".text-muted")!.textContent = `${Math.round(progress)}%`
  }

  private onError = (event: Event) => {
    event.preventDefault()
    const { id } = (event as CustomEvent).detail
    const item = this.uploads.get(id)
    if (!item) return
    const bar = item.querySelector<HTMLElement>(".progress-bar")
    bar?.classList.replace("progress-bar-animated", "bg-danger")
    bar?.classList.remove("progress-bar-striped")
    item.querySelector<HTMLElement>(".text-muted")!.textContent = "Failed"
    const msg = document.createElement("p")
    msg.className = "text-danger small mb-0 mt-1"
    msg.textContent = "Upload failed. Please remove the file and try again."
    item.appendChild(msg)
  }

  private onEnd = (event: Event) => {
    const { id } = (event as CustomEvent).detail
    const item = this.uploads.get(id)
    if (!item) return
    const bar = item.querySelector<HTMLElement>(".progress-bar")!
    bar.style.width = "100%"
    bar.classList.remove("progress-bar-striped", "progress-bar-animated")
    bar.classList.add("bg-success")
    item.querySelector<HTMLElement>(".text-muted")!.textContent = "Done"
  }

  private escape(str: string) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
