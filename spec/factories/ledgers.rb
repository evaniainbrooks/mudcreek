FactoryBot.define do
  factory :ledger do
    sequence(:name) { |n| "Ledger #{n}" }
    description { nil }
  end
end
