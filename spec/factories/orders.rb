FactoryBot.define do
  factory :order do
    association :user
    subtotal_cents { 1000 }
    tax_cents      { 150 }
    total_cents    { 1150 }
    status         { "pending" }
  end
end
