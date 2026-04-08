FactoryBot.define do
  factory :navbar_item do
    sequence(:title) { |n| "Nav Item #{n}" }
    sequence(:path)  { |n| "/nav-#{n}" }
    sequence(:position) { |n| n }
    icon { "bi-link" }
  end
end
