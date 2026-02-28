FactoryBot.define do
  factory :discount_code do
    key { Faker::Alphanumeric.unique.alphanumeric(number: 8).upcase }
    discount_type { :fixed }
    amount_cents { 1000 }
    start_at { nil }
    end_at { nil }

    trait :percentage do
      discount_type { :percentage }
      amount_cents { 1500 }
    end

    trait :active do
      start_at { 1.day.ago }
      end_at { 1.month.from_now }
    end

    trait :expired do
      start_at { 2.months.ago }
      end_at { 1.day.ago }
    end
  end
end
