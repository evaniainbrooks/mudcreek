FactoryBot.define do
  factory :qr_code do
    sequence(:name) { |n| "QR Code #{n}" }
    slug            { name.parameterize }
    destination_url { "https://example.com" }
    active          { true }

    trait :inactive do
      active { false }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :with_expiry do
      expires_at { 1.week.from_now }
    end
  end
end
