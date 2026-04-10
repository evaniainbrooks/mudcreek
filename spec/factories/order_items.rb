FactoryBot.define do
  factory :order_item do
    association :order
    association :listing
    name        { "Test Item" }
    price_cents { 1000 }
  end
end
