import { Controller } from "@hotwired/stimulus"
import { renderStreamMessage } from "@hotwired/turbo"
import { Subscription } from "@rails/actioncable"
import consumer from "../consumer"

export default class extends Controller {
  static targets = ["message"]
  static values = { streamSrc: String, url: String }

  declare messageTarget: HTMLElement
  declare streamSrcValue: string
  declare urlValue: string

  private subscription: Subscription | null = null

  connect(): void {
    this.messageTarget.textContent = "Initializing..."
    this.subscription = consumer.subscriptions.create(
      { channel: "Turbo::StreamsChannel", signed_stream_name: this.streamSrcValue },
      {
        connected: () => this.onConnected(),
        received: (data: string) => renderStreamMessage(data)
      }
    )
  }

  disconnect(): void {
    this.subscription?.unsubscribe()
    this.subscription = null
  }

  private async onConnected(): Promise<void> {
    this.messageTarget.textContent = "Sending request..."
    const response = await fetch(this.urlValue, {
      headers: { Accept: "text/vnd.async-content" }
    })
    if (response.ok) {
      const text = await response.text()
      if (text) renderStreamMessage(text)
    }
    this.messageTarget.textContent = "Loading..."
  }
}
