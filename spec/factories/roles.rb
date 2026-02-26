FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    description { "A sample role description" }
  end
end
