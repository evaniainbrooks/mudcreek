import { Toast } from "bootstrap"
import "./consumer" // ensure consumer is initialized with event hooks

let toastEl: HTMLElement | null = null

function ensureToast(): HTMLElement {
  if (toastEl && document.body.contains(toastEl)) return toastEl

  const container = document.createElement("div")
  container.className = "toast-container position-fixed bottom-0 end-0 p-3"
  container.setAttribute("aria-live", "polite")
  container.innerHTML = `
    <div class="toast align-items-center text-bg-danger border-0" role="alert" aria-atomic="true" data-bs-autohide="false">
      <div class="d-flex">
        <div class="toast-body">
          <i class="bi bi-wifi-off me-2"></i>
          Connection lost. Please refresh the page to continue receiving live updates.
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
      </div>
    </div>
  `
  document.body.appendChild(container)
  toastEl = container.querySelector<HTMLElement>(".toast")!
  return toastEl
}

function showToast(): void {
  Toast.getOrCreateInstance(ensureToast()).show()
}

function hideToast(): void {
  if (!toastEl) return
  Toast.getInstance(toastEl)?.hide()
}

// Wait 3 seconds before showing the toast. If the page is refreshing or
// navigating away, the JS context is destroyed before the timeout fires so
// the toast never appears. It also suppresses brief blips that self-recover.
let disconnectTimer: ReturnType<typeof setTimeout> | null = null

document.addEventListener("cable:disconnected", () => {
  disconnectTimer ??= setTimeout(showToast, 3000)
})

document.addEventListener("cable:connected", () => {
  if (disconnectTimer) { clearTimeout(disconnectTimer); disconnectTimer = null }
  hideToast()
})
