import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

// Wrap the connection event handlers before the WebSocket is first opened so
// we can dispatch DOM events that cable_status.ts (and anything else) can
// listen to without coupling to the consumer directly.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const conn = (consumer as any).connection
const { open: origOpen, close: origClose } = conn.events

conn.events.open = function(this: unknown, event: Event) {
  origOpen.call(this, event)
  document.dispatchEvent(new CustomEvent("cable:connected"))
}

conn.events.close = function(this: unknown, event: CloseEvent) {
  origClose.call(this, event)
  document.dispatchEvent(new CustomEvent("cable:disconnected"))
}

// Eagerly open the WebSocket so disconnect events are monitored on every page,
// not just those with explicit channel subscriptions.
consumer.connect()

export default consumer
