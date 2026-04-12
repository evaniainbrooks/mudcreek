FactoryBot.define do
  factory :tenant do
    sequence(:key) { |n| "tenant_#{n}" }
    sequence(:name) { |n| "Tenant #{n}" }
    email_address { "info@#{key.tr('_', '-')}.com" }
    default { false }
  end
end
