FactoryBot.define do
  factory :kid do
    association :user
    sequence(:name) { |n| "Kid #{n}" }
    birthdate { 8.years.ago.to_date }
  end
end
