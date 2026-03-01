class RentalPricingService
  Result = Data.define(:total_cents, :breakdown)
  # breakdown: [{rate_plan:, quantity:}, ...]

  def initialize(rate_plans)
    @rate_plans = rate_plans.sort_by(&:duration_minutes)
  end

  def minimum_cost_for(duration_minutes)
    return Result.new(total_cents: 0, breakdown: []) if duration_minutes <= 0

    n      = duration_minutes
    dp     = Array.new(n + 1, Float::INFINITY)
    chosen = Array.new(n + 1)
    dp[0]  = 0

    (1..n).each do |i|
      @rate_plans.each do |plan|
        prev = [i - plan.duration_minutes, 0].max
        cost = dp[prev] + plan.price_cents
        if cost < dp[i]
          dp[i]     = cost
          chosen[i] = { plan: plan, prev: prev }
        end
      end
    end

    plans_used = Hash.new(0)
    i = n
    while i > 0
      step = chosen[i]
      plans_used[step[:plan]] += 1
      i = step[:prev]
    end

    breakdown = plans_used.map { |plan, qty| { rate_plan: plan, quantity: qty } }
    Result.new(total_cents: dp[n], breakdown: breakdown)
  end
end
