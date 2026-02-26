FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n.to_s.tr('0-9', 'a-j')}" }
    description { "A sample role description" }
  end
end
