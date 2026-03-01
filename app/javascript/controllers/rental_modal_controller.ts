import { Controller } from "@hotwired/stimulus"

interface RatePlan {
  label: string
  duration_minutes: number
  price_cents: number
}

export default class extends Controller {
  static targets = ["startAt", "endAt", "breakdown", "submit"]
  static values  = { ratePlans: Array }

  declare startAtTarget:   HTMLInputElement
  declare endAtTarget:     HTMLInputElement
  declare breakdownTarget: HTMLElement
  declare submitTarget:    HTMLButtonElement
  declare ratePlansValue:  RatePlan[]

  calculate(): void {
    const start = new Date(this.startAtTarget.value)
    const end   = new Date(this.endAtTarget.value)

    if (!this.startAtTarget.value || !this.endAtTarget.value || end <= start) {
      this.breakdownTarget.innerHTML = ""
      this.submitTarget.disabled = true
      return
    }

    const durationMinutes = Math.ceil((end.getTime() - start.getTime()) / 60000)
    const { totalCents, breakdown } = this.minimumCost(durationMinutes)

    this.renderBreakdown(breakdown, totalCents)
    this.submitTarget.disabled = false
  }

  private minimumCost(target: number): { totalCents: number; breakdown: { plan: RatePlan; quantity: number }[] } {
    const plans = this.ratePlansValue
    const dp     = new Array(target + 1).fill(Infinity)
    const chosen = new Array(target + 1).fill(null)
    dp[0] = 0

    for (let i = 1; i <= target; i++) {
      for (const plan of plans) {
        const prev = Math.max(i - plan.duration_minutes, 0)
        const cost = dp[prev] + plan.price_cents
        if (cost < dp[i]) { dp[i] = cost; chosen[i] = { plan, prev } }
      }
    }

    const counts = new Map<RatePlan, number>()
    let i = target
    while (i > 0) {
      const step = chosen[i]
      counts.set(step.plan, (counts.get(step.plan) ?? 0) + 1)
      i = step.prev
    }

    const breakdown = Array.from(counts.entries()).map(([plan, quantity]) => ({ plan, quantity }))
    return { totalCents: dp[target], breakdown }
  }

  private renderBreakdown(breakdown: { plan: RatePlan; quantity: number }[], totalCents: number): void {
    const fmt = (cents: number) => (cents / 100).toLocaleString("en-CA", { style: "currency", currency: "CAD" })
    const rows = breakdown.map(({ plan, quantity }) =>
      `<tr><td>${quantity} × ${plan.label}</td><td class="text-end">${fmt(plan.price_cents * quantity)}</td></tr>`
    ).join("")
    this.breakdownTarget.innerHTML = `
      <table class="table table-sm mb-0">
        <tbody>${rows}</tbody>
        <tfoot><tr class="fw-bold border-top"><td>Total</td><td class="text-end">${fmt(totalCents)}</td></tr></tfoot>
      </table>`
  }
}
