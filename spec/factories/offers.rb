FactoryBot.define do
  factory :offer do
    association :listing
    association :user
    amount_cents { 500 }
    message { nil }
    state { "pending" }
  end
end
