FactoryBot.define do
  factory :auction do
    sequence(:name) { |n| "Auction #{n}" }
  end

  factory :auction_listing do
    association :auction
    association :listing
  end
end
