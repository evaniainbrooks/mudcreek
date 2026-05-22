FactoryBot.define do
  factory :work_order do
    sequence(:title) { |n| "Work Order #{n}" }
    client_name  { "Jane Smith" }
    client_email { "jane@example.com" }
    client_phone { "555-0100" }
    state        { "draft" }
    total_cents  { 0 }

    trait :with_user do
      association :user
      client_name  { nil }
      client_email { nil }
      client_phone { nil }
    end

    trait :with_items do
      after(:create) do |wo|
        create(:work_order_item, work_order: wo, quantity: 2, unit_price_cents: 50_000)
        create(:work_order_item, work_order: wo, quantity: 1, unit_price_cents: 25_000)
        wo.update_columns(total_cents: 125_000)
      end
    end

    trait :with_milestones do
      after(:create) do |wo|
        create(:work_order_milestone, work_order: wo, name: "Deposit",    percentage: 10, trigger_state: "contracted")
        create(:work_order_milestone, work_order: wo, name: "Midway",     percentage: 40, trigger_state: "in_progress")
        create(:work_order_milestone, work_order: wo, name: "Completion", percentage: 50, trigger_state: "completed")
      end
    end

    trait :contracted do
      state         { "contracted" }
      contracted_at { Time.current }
    end

    trait :estimate_sent do
      state            { "estimate_sent" }
      estimate_sent_at { Time.current }
    end
  end

  factory :work_order_item do
    association :work_order
    sequence(:name) { |n| "Item #{n}" }
    quantity         { 1 }
    unit_price_cents { 10_000 }
  end

  factory :work_order_milestone do
    association :work_order
    sequence(:name) { |n| "Milestone #{n}" }
    percentage    { 50 }
    trigger_state { "contracted" }
    amount_cents  { 0 }
  end
end
