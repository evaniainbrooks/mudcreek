FactoryBot.define do
  factory :listing do
    sequence(:name) { |n| "Listing #{n}" }
    description { "A sample listing description" }
    price_cents { 1000 }
    association :owner, factory: :user
  end
end
