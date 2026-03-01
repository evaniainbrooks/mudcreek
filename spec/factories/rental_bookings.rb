FactoryBot.define do
  factory :rental_booking do
    association :listing
    association :cart_item
    start_at   { 1.day.from_now }
    end_at     { 2.days.from_now }
    expires_at { 24.hours.from_now }
  end
end
