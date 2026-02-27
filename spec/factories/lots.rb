FactoryBot.define do
  factory :lot do
    sequence(:name) { |n| "Lot #{n}" }
    association :owner, factory: :user
  end
end
