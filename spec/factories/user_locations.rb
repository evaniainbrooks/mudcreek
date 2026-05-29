FactoryBot.define do
  factory :user_location do
    association :user
    association :location
  end
end
