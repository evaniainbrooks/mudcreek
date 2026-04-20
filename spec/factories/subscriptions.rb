FactoryBot.define do
  factory :subscription_plan do
    sequence(:name) { |n| "Plan #{n}" }
    amount_cents { 5_000 }
    subscription_type { :month_to_month }
  end

  factory :subscription do
    transient do
      user { nil }
    end

    association :subscription_plan
    renews_at { Date.current + 1.month }
    status    { :active }
    amount_cents { 5_000 }

    after(:create) do |subscription, evaluator|
      if evaluator.user
        subscription.subscription_users.create!(user: evaluator.user, primary_contact: true)
      end
    end
  end
end
