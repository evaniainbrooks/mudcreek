FactoryBot.define do
  factory :cart_item do
    association :user
    association :listing

    trait :rental do
      rental_start_at    { 1.day.from_now }
      rental_end_at      { 2.days.from_now }
      rental_price_cents { 6500 }
    end
  end
end
