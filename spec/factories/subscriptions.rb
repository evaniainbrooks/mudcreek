FactoryBot.define do
  factory :subscription_plan do
    sequence(:name) { |n| "Plan #{n}" }
    amount_cents { 5_000 }
    kind { :month_to_month }
  end

  factory :subscription do
    association :user
    association :subscription_plan
    renews_at { Date.current + 1.month }
    status    { :active }
  end
end
