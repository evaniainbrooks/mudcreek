FactoryBot.define do
  factory :ledger_entry, class: "Ledger::Entry" do
    association :ledger
    sequence(:description) { |n| "Entry #{n}" }
    entry_type { "credit" }
    amount { 10.00 }
    recorded_at { Time.current }

    trait :debit do
      entry_type { "debit" }
    end

    trait :without_amount do
      amount { nil }
    end
  end
end
