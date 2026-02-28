FactoryBot.define do
  factory :delivery_method do
    sequence(:name) { |n| "Delivery Method #{n}" }
    price_cents { 0 }
    active { true }

    trait :paid do
      price_cents { 1500 }
    end

    trait :inactive do
      active { false }
    end
  end
end
