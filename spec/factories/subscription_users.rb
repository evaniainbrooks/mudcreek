FactoryBot.define do
  factory :subscription_user do
    association :subscription
    association :user
  end
end
