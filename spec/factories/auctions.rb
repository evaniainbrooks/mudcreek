FactoryBot.define do
  factory :auction do
    sequence(:name) { |n| "Auction #{n}" }
    starts_at { Time.current }
    ends_at { 1.day.from_now }
  end

  factory :auction_listing do
    association :auction
    association :listing
  end
end
