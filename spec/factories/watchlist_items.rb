FactoryBot.define do
  factory :watchlist_item do
    association :user
    association :listing
  end
end
