FactoryBot.define do
  factory :tenant do
    sequence(:key) { |n| "tenant_#{n}" }
    default { false }
  end
end
