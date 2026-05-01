FactoryBot.define do
  factory :rank do
    association :discipline
    sequence(:name) { |n| "Rank #{n}" }
    sequence(:position) { |n| n }
  end
end
