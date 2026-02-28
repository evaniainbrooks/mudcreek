FactoryBot.define do
  factory :tenant do
    sequence(:key) { |n| "tenant_#{n}" }
    sequence(:name) { |n| "Tenant #{n}" }
    default { false }
  end
end
