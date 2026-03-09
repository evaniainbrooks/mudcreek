FactoryBot.define do
  factory :bid_increment_tier do
    bid_increment_schedule
    min_amount_cents { 0 }
    increment_cents  { 500 }
  end
end
