FactoryBot.define do
  factory :gallery do
    sequence(:name) { |n| "Gallery #{n}" }
  end
end
