FactoryBot.define do
  factory :check_in do
    association :location
    association :user

    trait :guest do
      user { nil }
      guest_name { "Jane Guest" }
    end
  end
end
